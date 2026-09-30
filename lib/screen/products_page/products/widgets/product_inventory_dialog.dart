import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/widgets/stock_quantity_field.dart';
import 'package:hyper_local_seller/screen/products_page/products/model/product_model.dart';
import 'package:hyper_local_seller/screen/products_page/products/repo/products_repo.dart';

class ProductInventoryDialog extends StatefulWidget {
  final int productId;
  final Variant variant;
  final List<Variant>? variants;
  final ProductsRepo? repo;
  const ProductInventoryDialog({
    super.key,
    required this.productId,
    required this.variant,
    this.variants,
    this.repo,
  });

  @override
  State<ProductInventoryDialog> createState() => _ProductInventoryDialogState();
}

class _ProductInventoryDialogState extends State<ProductInventoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _repo = widget.repo ?? ProductsRepo();
  late final _variants = widget.variants ?? [widget.variant];
  late Variant _variant = widget.variant;
  List<VariantStore> get _stores => _variant.stores ?? <VariantStore>[];
  VariantStore? _store;
  String _quantity = '';
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectStore();
  }

  void _selectStore() {
    _store =
        _stores
            .where((store) => store.storeId == HiveStorage.selectedStoreId)
            .firstOrNull ??
        _stores.firstOrNull;
    _quantity = _store?.stock?.toString() ?? '';
  }

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    final id = _store?.storeProductVariantId;
    if (id == null || id < 1) {
      setState(
        () => _error =
            'Inventory details are missing. Refresh the product and try again.',
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (kDebugMode) {
        final requested = int.parse(_quantity.trim());
        final previous = _store?.stock;
        debugPrint(
          '[Inventory] quantity change | product_id: ${widget.productId} | store_id: ${_store?.storeId} | store_product_variant_id: $id | previous_stock: $previous | requested_stock: $requested | delta: ${previous == null ? "unknown" : requested - previous}',
        );
      }
      final stock = await _repo.updateInventory(
        productId: widget.productId,
        storeProductVariantId: id,
        stock: int.parse(_quantity.trim()),
      );
      if (!mounted) return;
      _store!.stock = stock;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[Inventory] quantity update failed | product_id: ${widget.productId} | error: $e',
        );
      }
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      title: const Text('Edit stock quantity'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_variants.length > 1)
                DropdownButtonFormField<Variant>(
                  initialValue: _variant,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Variation'),
                  items: [
                    for (final variant in _variants)
                      DropdownMenuItem(
                        value: variant,
                        child: Text(variant.title ?? 'Variation'),
                      ),
                  ],
                  onChanged: _saving
                      ? null
                      : (variant) {
                          if (variant == null) return;
                          setState(() {
                            _variant = variant;
                            _selectStore();
                            _error = null;
                          });
                        },
                )
              else
                Text(_variant.title ?? 'Product'),
              const SizedBox(height: 12),
              if (_stores.length > 1) ...[
                DropdownButtonFormField<VariantStore>(
                  key: ObjectKey(_variant),
                  initialValue: _store,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Store'),
                  items: [
                    for (final store in _stores)
                      DropdownMenuItem(
                        value: store,
                        child: Text(store.storeName ?? 'Store'),
                      ),
                  ],
                  onChanged: _saving
                      ? null
                      : (store) => setState(() {
                          _store = store;
                          _quantity = store?.stock?.toString() ?? '';
                          _error = null;
                        }),
                ),
                const SizedBox(height: 12),
              ] else if (_store?.storeName != null) ...[
                Text(_store!.storeName!),
                const SizedBox(height: 12),
              ],
              AbsorbPointer(
                absorbing: _saving,
                child: StockQuantityField(
                  value: _quantity,
                  onChanged: (value) => setState(() {
                    _quantity = value;
                    _error = null;
                  }),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
          ),
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save stock'),
        ),
      ],
    ),
  );
}
