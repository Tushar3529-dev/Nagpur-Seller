import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/screen/order_page/incoming_orders/cubit/incoming_orders_cubit.dart';
import 'package:hyper_local_seller/screen/order_page/incoming_orders/model/pending_order_model.dart';
import 'package:hyper_local_seller/widgets/custom/barcode_scan_widgets.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

enum _Mode { checklist, camera, manual, review, quantity }

/// Shown in the incoming-order popup once an order is accepted. The seller
/// scans (or types) each item's barcode and confirms its quantity; when
/// every item is verified, "Mark as preparing" appears.
class OrderScanPanel extends StatefulWidget {
  final PendingOrder order;
  final IncomingOrdersState state;

  /// Called after the order was moved to preparing.
  final VoidCallback onPrepared;

  @visibleForTesting
  final Widget Function(void Function(String code, Uint8List? image) onCode)?
  cameraBuilder;

  const OrderScanPanel({
    super.key,
    required this.order,
    required this.state,
    required this.onPrepared,
    this.cameraBuilder,
  });

  @override
  State<OrderScanPanel> createState() => _OrderScanPanelState();
}

class _OrderScanPanelState extends State<OrderScanPanel> {
  _Mode _mode = _Mode.checklist;
  MobileScannerController? _scanner;
  final _codeController = TextEditingController();
  final _quantityController = TextEditingController();

  /// Code read by the camera, waiting for the seller to confirm it.
  String? _scannedCode;
  Uint8List? _scannedImage;
  PendingOrderItem? _item;
  String? _error;

  IncomingOrdersCubit get _cubit => context.read<IncomingOrdersCubit>();

  @override
  void dispose() {
    _scanner?.dispose();
    _codeController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _go(_Mode mode) {
    if (mode == _Mode.camera && widget.cameraBuilder == null) {
      _scanner ??= MobileScannerController(returnImage: true);
    } else {
      _scanner?.dispose();
      _scanner = null;
    }
    if (mode == _Mode.manual) _codeController.clear();
    setState(() {
      _mode = mode;
      _error = null;
    });
  }

  void _onDetect(BarcodeCapture capture) {
    if (_mode != _Mode.camera) return;
    final code = firstBarcodeValue(capture);
    if (code == null) return;
    _onCode(code, capture.image);
  }

  void _onCode(String code, Uint8List? image) {
    if (!mounted || _mode != _Mode.camera || code.trim().isEmpty) return;
    HapticFeedback.mediumImpact();
    _scannedCode = code.trim();
    _scannedImage = image;
    _go(_Mode.review);
  }

  /// Compares [code] with the order's barcodes and moves on to the quantity
  /// step when it belongs to an item still to be verified.
  void _checkCode(String code) {
    if (code.trim().isEmpty) {
      setState(() => _error = 'Enter a barcode');
      return;
    }
    final (match, item) = _cubit.matchCode(widget.order, code);
    switch (match) {
      case ScanMatch.matched:
        _item = item;
        _quantityController.text = '1';
        _go(_Mode.quantity);
      case ScanMatch.alreadyVerified:
        setState(
          () => _error =
              '${item!.product} is already verified. Scan the next item.',
        );
      case ScanMatch.notInOrder:
        setState(
          () => _error =
              "This barcode isn't in this order. Check the product and try again.",
        );
    }
  }

  void _changeQuantity(int delta) {
    final current = int.tryParse(_quantityController.text) ?? 0;
    final next = (current + delta).clamp(1, 99999);
    setState(() {
      _quantityController.text = '$next';
      _error = null;
    });
  }

  void _confirmQuantity() {
    final item = _item!;
    final quantity = int.tryParse(_quantityController.text);
    if (quantity == null || quantity < 1) {
      setState(() => _error = 'Enter the quantity');
      return;
    }
    if (!_cubit.confirmQuantity(item, quantity)) {
      setState(
        () => _error =
            "Quantity doesn't match the order (${item.quantity}). Count again.",
      );
      return;
    }
    HapticFeedback.lightImpact();
    _item = null;
    _go(_Mode.checklist);
  }

  Future<void> _markPreparing() async {
    final prepared = await _cubit.markPreparing(widget.order);
    if (prepared && mounted) widget.onPrepared();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: ColoredBox(
        color: isDark ? AppColors.darkSubCategoryCardColor : Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ScanHeader(
              order: widget.order,
              title: switch (_mode) {
                _Mode.checklist => 'Scan items',
                _Mode.camera => 'Scan barcode',
                _Mode.manual => 'Enter barcode',
                _Mode.review => 'Check the code',
                _Mode.quantity => 'Confirm quantity',
              },
              verified: widget.state.verifiedCount(widget.order),
              total: widget.order.items.length,
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: switch (_mode) {
                  _Mode.checklist => _buildChecklist(),
                  _Mode.camera => _buildCamera(),
                  _Mode.manual => _buildManual(),
                  _Mode.review => _buildReview(),
                  _Mode.quantity => _buildQuantity(),
                },
              ),
            ),
            ScanBottomBar(
              child: switch (_mode) {
                _Mode.checklist => _buildChecklistActions(),
                _Mode.camera => _buildCameraActions(),
                _Mode.manual => _buildManualActions(),
                _Mode.review => _buildReviewActions(),
                _Mode.quantity => _buildQuantityActions(),
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Checklist ──────────────────────────────────────────────────────────

  Widget _buildChecklist() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in widget.order.items)
          _ChecklistRow(
            item: item,
            verified: widget.state.isVerified(item),
            errors: widget.state.itemErrors[item.orderItemId] ?? const {},
          ),
      ],
    );
  }

  Widget _buildChecklistActions() {
    final state = widget.state;
    final orderId = widget.order.sellerOrderId;
    if (state.isFullyVerified(widget.order)) {
      final isPreparing = state.preparingOrderId == orderId;
      final error = state.failedOrderId == orderId ? state.errorMessage : null;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (error != null) ...[
            ScanErrorText("Couldn't mark as preparing. $error"),
            const SizedBox(height: 8),
          ],
          ScanPrimaryButton(
            label: error != null ? 'Retry preparing' : 'Mark as preparing',
            icon: Icons.soup_kitchen_outlined,
            color: Colors.green.shade600,
            isLoading: isPreparing,
            onPressed: _markPreparing,
          ),
        ],
      );
    }
    final error = state.failedOrderId == orderId ? state.errorMessage : null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (error != null) ...[
          ScanErrorText("Couldn't mark as preparing. $error"),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            ScanManualEntryButton(onPressed: () => _go(_Mode.manual)),
            const SizedBox(width: 10),
            Expanded(
              child: ScanPrimaryButton(
                label: state.verifiedCount(widget.order) == 0
                    ? 'Scan item'
                    : 'Scan next item',
                icon: Icons.qr_code_scanner,
                onPressed: () => _go(_Mode.camera),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Camera ─────────────────────────────────────────────────────────────

  Widget _buildCamera() {
    if (widget.cameraBuilder != null) return widget.cameraBuilder!(_onCode);
    return ScanCameraView(
      controller: _scanner!,
      onDetect: _onDetect,
      onManualEntry: () => _go(_Mode.manual),
    );
  }

  Widget _buildCameraActions() {
    return Row(
      children: [
        ScanManualEntryButton(onPressed: () => _go(_Mode.manual)),
        const SizedBox(width: 10),
        Expanded(
          child: ScanSecondaryButton(
            label: 'Back to items',
            onPressed: () => _go(_Mode.checklist),
          ),
        ),
      ],
    );
  }

  // ── Review a camera scan ───────────────────────────────────────────────

  Widget _buildReview() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 200,
            color: Colors.black,
            child: _scannedImage != null
                ? Image.memory(_scannedImage!, fit: BoxFit.contain)
                : const Icon(Icons.qr_code_2, color: Colors.white70, size: 64),
          ),
        ),
        const SizedBox(height: 12),
        ScanCodeBox(label: 'Detected code', code: _scannedCode ?? ''),
        if (_error != null) ...[
          const SizedBox(height: 10),
          ScanErrorText(_error!),
        ],
        const SizedBox(height: 4),
        Text(
          'Tap the tick to check it against the order.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
        ),
      ],
    );
  }

  Widget _buildReviewActions() {
    return Row(
      children: [
        Expanded(
          child: ScanSecondaryButton(
            label: 'Retake',
            onPressed: () => _go(_Mode.camera),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ScanPrimaryButton(
            label: 'Confirm',
            icon: Icons.check,
            color: Colors.green.shade600,
            onPressed: () => _checkCode(_scannedCode ?? ''),
          ),
        ),
      ],
    );
  }

  // ── Manual entry ───────────────────────────────────────────────────────

  Widget _buildManual() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Type the code printed under the product's barcode.",
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _codeController,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          onSubmitted: _checkCode,
          cursorColor: scanFieldColor(context),
          decoration: scanCodeFieldDecoration(context, errorText: _error),
        ),
      ],
    );
  }

  Widget _buildManualActions() {
    return Row(
      children: [
        Expanded(
          child: ScanSecondaryButton(
            label: 'Scan instead',
            onPressed: () => _go(_Mode.camera),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ScanPrimaryButton(
            label: 'Confirm',
            icon: Icons.check,
            color: Colors.green.shade600,
            onPressed: () => _checkCode(_codeController.text),
          ),
        ),
      ],
    );
  }

  // ── Quantity ───────────────────────────────────────────────────────────

  Widget _buildQuantity() {
    final theme = Theme.of(context);
    final item = _item!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _Thumb(image: item.image),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (item.variant != null)
                    Text(
                      item.variant!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Barcode matched',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Ordered quantity: ${item.quantity}',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.outlined(
              tooltip: 'Decrease',
              onPressed: () => _changeQuantity(-1),
              icon: const Icon(Icons.remove),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 96,
              child: TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(5),
                ],
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                onSubmitted: (_) => _confirmQuantity(),
                decoration: InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton.outlined(
              tooltip: 'Increase',
              onPressed: () => _changeQuantity(1),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Tap the number to type it.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          ScanErrorText(_error!),
        ],
      ],
    );
  }

  Widget _buildQuantityActions() {
    return Row(
      children: [
        Expanded(
          child: ScanSecondaryButton(
            label: 'Cancel',
            onPressed: () {
              _item = null;
              _go(_Mode.checklist);
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: ScanPrimaryButton(
            label: 'Confirm quantity',
            icon: Icons.check,
            color: Colors.green.shade600,
            onPressed: _confirmQuantity,
          ),
        ),
      ],
    );
  }
}

class _ScanHeader extends StatelessWidget {
  final PendingOrder order;
  final String title;
  final int verified;
  final int total;

  const _ScanHeader({
    required this.order,
    required this.title,
    required this.verified,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryColor,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ORDER #${order.orderNumber} · ACCEPTED',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$verified of $total',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : verified / total,
              minHeight: 6,
              color: Colors.greenAccent,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  final PendingOrderItem item;
  final bool verified;
  final Map<String, String> errors;

  const _ChecklistRow({
    required this.item,
    required this.verified,
    required this.errors,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final green = Colors.green.shade600;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: verified
            ? green.withValues(alpha: 0.08)
            : (isDark
                  ? AppColors.darkProductCardColor
                  : AppColors.mainLightContainerBgColor),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: verified
              ? green.withValues(alpha: 0.5)
              : (isDark ? AppColors.darkOutline : AppColors.lightOutline),
        ),
      ),
      child: Row(
        children: [
          Icon(
            verified
                ? Icons.check_circle
                : errors.isNotEmpty || !item.hasBarcode
                ? Icons.error_outline
                : Icons.radio_button_unchecked,
            color: verified
                ? green
                : errors.isNotEmpty || !item.hasBarcode
                ? Colors.red.shade600
                : theme.hintColor,
          ),
          const SizedBox(width: 10),
          _Thumb(image: item.image),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (item.variant != null) item.variant!,
                    'Qty ${item.quantity}',
                    if (item.sku != null) 'SKU ${item.sku}',
                    if (item.variantWeight != null)
                      'Weight ${item.variantWeight}',
                    if (item.variantDimensions != null) item.variantDimensions!,
                  ].join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
                if (!item.hasBarcode)
                  Text(
                    'Barcode missing for ${item.product}. Contact support.',
                    style: TextStyle(color: Colors.red.shade600),
                  ),
                for (final error in errors.entries)
                  Text(
                    '${error.key}: ${error.value}',
                    style: TextStyle(color: Colors.red.shade600),
                  ),
              ],
            ),
          ),
          if (verified)
            Text(
              '${item.quantity}/${item.quantity}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: green,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final String? image;

  const _Thumb({required this.image});

  @override
  Widget build(BuildContext context) {
    const placeholder = ColoredBox(
      color: AppColors.stepCurrentBgColor,
      child: Icon(
        Icons.inventory_2_outlined,
        color: AppColors.primaryColor,
        size: 20,
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 44,
        height: 44,
        child: image != null
            ? CachedNetworkImage(
                imageUrl: image!,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => placeholder,
                placeholder: (_, _) => placeholder,
              )
            : placeholder,
      ),
    );
  }
}
