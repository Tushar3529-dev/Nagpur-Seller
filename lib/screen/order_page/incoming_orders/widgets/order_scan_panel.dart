import 'package:app_settings/app_settings.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/screen/order_page/incoming_orders/cubit/incoming_orders_cubit.dart';
import 'package:hyper_local_seller/screen/order_page/incoming_orders/model/pending_order_model.dart';
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
    final code = capture.barcodes
        .map((barcode) => barcode.rawValue?.trim() ?? '')
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');
    if (code.isEmpty) return;
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
            _BottomBar(
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
          _ChecklistRow(item: item, verified: widget.state.isVerified(item)),
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
            _ErrorText("Couldn't mark as preparing. $error"),
            const SizedBox(height: 8),
          ],
          _PrimaryButton(
            label: error != null ? 'Retry preparing' : 'Mark as preparing',
            icon: Icons.soup_kitchen_outlined,
            color: Colors.green.shade600,
            isLoading: isPreparing,
            onPressed: _markPreparing,
          ),
        ],
      );
    }
    return Row(
      children: [
        _ManualEntryButton(onPressed: () => _go(_Mode.manual)),
        const SizedBox(width: 10),
        Expanded(
          child: _PrimaryButton(
            label: state.verifiedCount(widget.order) == 0
                ? 'Scan item'
                : 'Scan next item',
            icon: Icons.qr_code_scanner,
            onPressed: () => _go(_Mode.camera),
          ),
        ),
      ],
    );
  }

  // ── Camera ─────────────────────────────────────────────────────────────

  Widget _buildCamera() {
    if (widget.cameraBuilder != null) return widget.cameraBuilder!(_onCode);
    final scanner = _scanner!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 280,
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  controller: scanner,
                  onDetect: _onDetect,
                  errorBuilder: (context, error) => _CameraError(
                    permissionDenied:
                        error.errorCode ==
                        MobileScannerErrorCode.permissionDenied,
                    onManualEntry: () => _go(_Mode.manual),
                  ),
                ),
                IgnorePointer(
                  child: Center(
                    child: Container(
                      width: 240,
                      height: 130,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton.filledTonal(
                    tooltip: 'Flashlight',
                    onPressed: scanner.toggleTorch,
                    icon: const Icon(Icons.flashlight_on_outlined),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "Point the camera at the product's barcode.",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildCameraActions() {
    return Row(
      children: [
        _ManualEntryButton(onPressed: () => _go(_Mode.manual)),
        const SizedBox(width: 10),
        Expanded(
          child: _SecondaryButton(
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
        _CodeBox(label: 'Detected code', code: _scannedCode ?? ''),
        if (_error != null) ...[
          const SizedBox(height: 10),
          _ErrorText(_error!),
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
          child: _SecondaryButton(
            label: 'Retake',
            onPressed: () => _go(_Mode.camera),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PrimaryButton(
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
          decoration: InputDecoration(
            labelText: 'Barcode',
            prefixIcon: const Icon(Icons.keyboard_outlined),
            errorText: _error,
            errorMaxLines: 3,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildManualActions() {
    return Row(
      children: [
        Expanded(
          child: _SecondaryButton(
            label: 'Scan instead',
            onPressed: () => _go(_Mode.camera),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PrimaryButton(
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
          _ErrorText(_error!),
        ],
      ],
    );
  }

  Widget _buildQuantityActions() {
    return Row(
      children: [
        Expanded(
          child: _SecondaryButton(
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
          child: _PrimaryButton(
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

  const _ChecklistRow({required this.item, required this.verified});

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
            verified ? Icons.check_circle : Icons.radio_button_unchecked,
            color: verified ? green : theme.hintColor,
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
                    // Dummy barcodes can't be guessed; show them while testing.
                    if (kDebugMode && item.barcode != null)
                      'Code ${item.barcode}',
                  ].join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
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

class _CodeBox extends StatelessWidget {
  final String label;
  final String code;

  const _CodeBox({required this.label, required this.code});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkProductCardColor
            : AppColors.mainLightContainerBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
        ),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SelectableText(
              code,
              textAlign: TextAlign.end,
              style: theme.textTheme.titleMedium?.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraError extends StatelessWidget {
  final bool permissionDenied;
  final VoidCallback onManualEntry;

  const _CameraError({
    required this.permissionDenied,
    required this.onManualEntry,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.no_photography_outlined, color: Colors.white70),
            const SizedBox(height: 10),
            Text(
              permissionDenied
                  ? 'Camera access is off. Allow it in Settings, or enter the code manually.'
                  : "The camera isn't available. Enter the code manually.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              alignment: WrapAlignment.center,
              children: [
                if (permissionDenied)
                  TextButton(
                    onPressed: () => AppSettings.openAppSettings(),
                    child: const Text('Open settings'),
                  ),
                TextButton(
                  onPressed: onManualEntry,
                  child: const Text('Enter manually'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  final String message;

  const _ErrorText(this.message);

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      textAlign: TextAlign.center,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: Colors.red.shade600),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final Widget child;

  const _BottomBar({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkProductCardColor
            : AppColors.mainLightContainerBgColor,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
          ),
        ),
      ),
      child: child,
    );
  }
}

class _ManualEntryButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ManualEntryButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Tooltip(
          message: 'Enter code manually',
          child: Icon(Icons.keyboard_outlined),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color = AppColors.primaryColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading ? const SizedBox.shrink() : Icon(icon),
        label: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: color.withValues(alpha: 0.7),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _SecondaryButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
