import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/utils/unit_price_calculator.dart';
import 'package:hyper_local_seller/widgets/custom/custom_textfield.dart';

/// Unit price ("₹20 per 100 g") for one store/variant pricing row.
///
/// The basis (amount + unit) is stored on the pricing row. The unit price
/// itself is never sent to the API: editing it rewrites the effective pack
/// price instead — the special price when one is set, otherwise the price.
///
/// Holds its own controllers so typing (e.g. "2.") isn't overwritten by the
/// recomputed value while the field has focus.
class UnitPriceEditor extends StatefulWidget {
  const UnitPriceEditor({
    super.key,
    required this.price,
    required this.specialPrice,
    required this.basisQuantity,
    required this.basisUnit,
    required this.packageSize,
    required this.unitCount,
    required this.onBasisChanged,
    required this.onPackPriceChanged,
  });

  final String? price;
  final String? specialPrice;
  final String? basisQuantity;
  final String? basisUnit;

  /// Contents of one inner unit; null when the package isn't set up.
  final PackageSize? packageSize;
  final int? unitCount;

  final void Function(String quantity, String unit) onBasisChanged;
  final void Function({String? price, String? specialPrice}) onPackPriceChanged;

  @override
  State<UnitPriceEditor> createState() => _UnitPriceEditorState();
}

class _UnitPriceEditorState extends State<UnitPriceEditor> {
  final _unitPriceController = TextEditingController();
  final _basisQuantityController = TextEditingController();
  final _basisUnitController = TextEditingController();
  final _unitPriceFocus = FocusNode();
  final _basisQuantityFocus = FocusNode();
  final _basisUnitFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _syncBasisFromWidget();
    _syncUnitPriceFromWidget();
    for (final node in [
      _unitPriceFocus,
      _basisQuantityFocus,
      _basisUnitFocus,
    ]) {
      node.addListener(_onFocusChanged);
    }
    _persistDefaultBasisIfMissing();
  }

  @override
  void didUpdateWidget(covariant UnitPriceEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_basisQuantityFocus.hasFocus && !_basisUnitFocus.hasFocus) {
      _syncBasisFromWidget();
    }
    if (!_unitPriceFocus.hasFocus) _syncUnitPriceFromWidget();
    if (oldWidget.packageSize != widget.packageSize) {
      _persistDefaultBasisIfMissing();
    }
  }

  @override
  void dispose() {
    _unitPriceController.dispose();
    _basisQuantityController.dispose();
    _basisUnitController.dispose();
    _unitPriceFocus.dispose();
    _basisQuantityFocus.dispose();
    _basisUnitFocus.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    // Once the seller leaves a field, show the normalised values again.
    if (!_unitPriceFocus.hasFocus) _syncUnitPriceFromWidget();
    setState(() {});
  }

  bool get _hasSavedBasis =>
      (widget.basisQuantity?.trim().isNotEmpty ?? false) &&
      (widget.basisUnit?.trim().isNotEmpty ?? false);

  PackageSize? get _defaultBasis => widget.packageSize == null
      ? null
      : UnitPriceCalculator.defaultBasisFor(widget.packageSize!.unit);

  /// The basis shown to the seller: the saved one, else the default for
  /// the package unit.
  (String, String) get _displayBasis {
    if (_hasSavedBasis) {
      return (widget.basisQuantity!.trim(), widget.basisUnit!.trim());
    }
    final fallback = _defaultBasis;
    if (fallback == null) return ('', '');
    return (UnitPriceCalculator.formatNumber(fallback.quantity), fallback.unit);
  }

  void _syncBasisFromWidget() {
    final (quantity, unit) = _displayBasis;
    if (_basisQuantityController.text != quantity) {
      _basisQuantityController.text = quantity;
    }
    if (_basisUnitController.text != unit) _basisUnitController.text = unit;
  }

  void _syncUnitPriceFromWidget() {
    final value = _computedUnitPrice();
    final text = value == null ? '' : UnitPriceCalculator.formatNumber(value);
    if (_unitPriceController.text != text) _unitPriceController.text = text;
  }

  /// The basis is sent with every pricing row so it restores on edit, so
  /// store the default as soon as there is a package to base it on.
  void _persistDefaultBasisIfMissing() {
    if (_hasSavedBasis || _defaultBasis == null) return;
    final (quantity, unit) = _displayBasis;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _hasSavedBasis) return;
      widget.onBasisChanged(quantity, unit);
    });
  }

  double? get _basisQuantity =>
      double.tryParse(_basisQuantityController.text.trim());

  String get _basisUnit => _basisUnitController.text.trim();

  bool get _hasSpecialPrice {
    final special = double.tryParse(widget.specialPrice?.trim() ?? '');
    return special != null && special > 0;
  }

  double? _computedUnitPrice() {
    return UnitPriceCalculator.unitPrice(
      price: double.tryParse(widget.price?.trim() ?? ''),
      specialPrice: double.tryParse(widget.specialPrice?.trim() ?? ''),
      netQuantity: widget.packageSize?.quantity,
      netQuantityUnit: widget.packageSize?.unit,
      unitCount: widget.unitCount,
      basisQuantity: _basisQuantity,
      basisUnit: _basisUnit,
    );
  }

  bool get _isComparable =>
      widget.packageSize != null &&
      UnitPriceCalculator.areComparable(widget.packageSize!.unit, _basisUnit);

  void _onBasisEdited(String _) {
    widget.onBasisChanged(
      _basisQuantityController.text.trim(),
      _basisUnitController.text.trim(),
    );
    if (!_unitPriceFocus.hasFocus) _syncUnitPriceFromWidget();
    setState(() {});
  }

  void _onUnitPriceEdited(String text) {
    final unitPrice = double.tryParse(text.trim());
    if (unitPrice == null) return;
    final packPrice = UnitPriceCalculator.packPriceFromUnitPrice(
      unitPrice: unitPrice,
      netQuantity: widget.packageSize?.quantity,
      netQuantityUnit: widget.packageSize?.unit,
      unitCount: widget.unitCount,
      basisQuantity: _basisQuantity,
      basisUnit: _basisUnit,
    );
    if (packPrice == null) return;
    final formatted = UnitPriceCalculator.formatNumber(packPrice);
    if (_hasSpecialPrice) {
      widget.onPackPriceChanged(specialPrice: formatted);
    } else {
      widget.onPackPriceChanged(price: formatted);
    }
  }

  void _applyDefaultBasis() {
    final fallback = _defaultBasis;
    if (fallback == null) return;
    _basisQuantityController.text = UnitPriceCalculator.formatNumber(
      fallback.quantity,
    );
    _basisUnitController.text = fallback.unit;
    _onBasisEdited('');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tertiary = Theme.of(context).colorScheme.tertiary;
    final canEditUnitPrice = _isComparable && (_basisQuantity ?? 0) > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.unitPrice,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: tertiary,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              flex: 5,
              child: CustomTextField(
                controller: _unitPriceController,
                focusNode: _unitPriceFocus,
                enabled: canEditUnitPrice,
                hint: "0",
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Text(
                    HiveStorage.currencySymbol,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                onChanged: _onUnitPriceEdited,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                l10n.unitPricePer,
                style: TextStyle(fontSize: 13, color: tertiary),
              ),
            ),
            Expanded(
              flex: 3,
              child: CustomTextField(
                controller: _basisQuantityController,
                focusNode: _basisQuantityFocus,
                hint: "100",
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: _onBasisEdited,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 3,
              child: CustomTextField(
                controller: _basisUnitController,
                focusNode: _basisUnitFocus,
                hint: "g",
                inputFormatters: [
                  LengthLimitingTextInputFormatter(
                    UnitPriceCalculator.maxUnitLength,
                  ),
                ],
                onChanged: _onBasisEdited,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _buildHelper(l10n),
      ],
    );
  }

  Widget _buildHelper(AppLocalizations l10n) {
    const helperStyle = TextStyle(fontSize: 12, color: Colors.grey);
    final package = widget.packageSize;

    if (package == null) {
      return Text(l10n.unitPriceNeedsPackage, style: helperStyle);
    }

    if (_basisUnit.isNotEmpty && !_isComparable) {
      final fallback = _defaultBasis!;
      return Row(
        children: [
          Expanded(
            child: Text(
              l10n.unitPriceNotComparable(package.unit, _basisUnit),
              style: const TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ),
          TextButton(
            onPressed: _applyDefaultBasis,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryColor,
              visualDensity: VisualDensity.compact,
            ),
            child: Text(l10n.useDefaultBasis(fallback.toString())),
          ),
        ],
      );
    }

    return Text(
      _hasSpecialPrice
          ? l10n.unitPriceEditsSpecial
          : l10n.unitPriceEditsRegular,
      style: helperStyle,
    );
  }
}
