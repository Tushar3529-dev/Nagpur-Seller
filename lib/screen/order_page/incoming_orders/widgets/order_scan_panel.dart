import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/screen/order_page/incoming_orders/cubit/incoming_orders_cubit.dart';
import 'package:hyper_local_seller/screen/order_page/incoming_orders/model/pending_order_model.dart';
import 'package:hyper_local_seller/widgets/custom/barcode_scan_widgets.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// [items]: scanning products, [bag]: every product verified, scanning a
/// bag, [ready]: bag assigned, waiting for "Dispatch order".
enum _Phase { items, bag, ready }

/// Shown full screen once an order is accepted. The camera stays open while
/// a page per product slides past: scanning the product on screen (with the
/// quantity set on its page) verifies it and moves on to the next one, no
/// confirm taps. Then a bag is scanned, and "Dispatch order" appears.
class OrderScanPanel extends StatefulWidget {
  final PendingOrder order;
  final IncomingOrdersState state;

  /// Called after the order was moved to preparing.
  final VoidCallback onPrepared;

  /// Opens Bag inventory so a seller without available bags can add some.
  /// Completes when they come back.
  final Future<void> Function()? onAddBags;

  @visibleForTesting
  final Widget Function(void Function(String code, Uint8List? image) onCode)?
  cameraBuilder;

  const OrderScanPanel({
    super.key,
    required this.order,
    required this.state,
    required this.onPrepared,
    this.onAddBags,
    this.cameraBuilder,
  });

  @override
  State<OrderScanPanel> createState() => _OrderScanPanelState();
}

class _OrderScanPanelState extends State<OrderScanPanel> {
  /// The camera reports a barcode many times a second while it's in view.
  /// The same code is ignored until it has been out of view this long.
  static const _repeatDelay = Duration(milliseconds: 1500);

  MobileScannerController? _scanner;
  late PageController _pages;
  int _page = 0;
  final _codeController = TextEditingController();

  /// Quantity set on each product's page (by order_item_id). Starts at the
  /// ordered quantity, so a full line needs no taps.
  final Map<int, int> _quantities = {};

  /// Typing codes instead of using the camera.
  bool _manual = false;

  /// The seller packed the items and opened the bag scanner. Until then the
  /// bag step asks them to put everything in a bag first.
  bool _bagScanStarted = false;
  String? _error;

  /// Product just verified, shown over the camera for a moment.
  String? _matched;
  Timer? _matchedTimer;

  String? _lastCode;
  DateTime? _lastCodeAt;

  /// Available bags in the seller's inventory, checked once the bag step is
  /// reached. Null until checked, or when the check failed.
  int? _availableBags;
  bool _bagsChecked = false;
  bool _checkingBags = false;

  IncomingOrdersCubit get _cubit => context.read<IncomingOrdersCubit>();

  _Phase _phaseOf(IncomingOrdersState state) =>
      !state.isFullyVerified(widget.order)
      ? _Phase.items
      : state.bagFor(widget.order) == null
      ? _Phase.bag
      : _Phase.ready;

  _Phase get _phase => _phaseOf(widget.state);

  bool get _packing => _phase == _Phase.bag && !_bagScanStarted;

  bool get _isAssigningBag =>
      widget.state.assigningBagOrderId == widget.order.sellerOrderId;

  @override
  void initState() {
    super.initState();
    _pages = PageController(initialPage: _firstUnverified());
    _page = _pages.initialPage;
    _syncCamera();
    _checkBagsIfNeeded();
  }

  @override
  void didUpdateWidget(covariant OrderScanPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final phase = _phase;
    if (phase != _phaseOf(oldWidget.state)) {
      _error = null;
      _lastCode = null;
      // Back to items (the server rejected some): open the first one left.
      if (phase == _Phase.items) {
        _pages.dispose();
        _pages = PageController(initialPage: _firstUnverified());
        _page = _pages.initialPage;
      }
      _bagScanStarted = false;
      if (phase != _Phase.items) _manual = false;
    }
    _syncCamera();
    _checkBagsIfNeeded();
  }

  @override
  void dispose() {
    _matchedTimer?.cancel();
    _scanner?.dispose();
    _pages.dispose();
    _codeController.dispose();
    super.dispose();
  }

  /// Keeps the camera running while there is something to scan with it.
  void _syncCamera() {
    final wanted =
        widget.cameraBuilder == null &&
        !_manual &&
        !_packing &&
        _phase != _Phase.ready;
    if (wanted) {
      _scanner ??= MobileScannerController();
    } else {
      _scanner?.dispose();
      _scanner = null;
    }
  }

  void _checkBagsIfNeeded() {
    if (_phase == _Phase.bag && !_bagsChecked && !_checkingBags) _checkBags();
  }

  /// Called from initState/didUpdateWidget, so a build always follows.
  Future<void> _checkBags() async {
    _checkingBags = true;
    final count = await _cubit.availableBagCount();
    if (!mounted) return;
    setState(() {
      _checkingBags = false;
      _bagsChecked = true;
      _availableBags = count;
    });
  }

  Future<void> _addBags() async {
    await widget.onAddBags?.call();
    if (!mounted) return;
    setState(() => _checkingBags = true);
    final count = await _cubit.availableBagCount();
    if (!mounted) return;
    setState(() {
      _checkingBags = false;
      _availableBags = count;
    });
  }

  int _firstUnverified() {
    final index = widget.order.items.indexWhere(
      (item) => !widget.state.isVerified(item),
    );
    return index < 0 ? 0 : index;
  }

  int _quantityOf(PendingOrderItem item) =>
      _quantities[item.orderItemId] ?? item.quantity;

  void _changeQuantity(PendingOrderItem item, int delta) {
    setState(() {
      _quantities[item.orderItemId] = (_quantityOf(item) + delta).clamp(
        1,
        9999,
      );
      _error = null;
      // Let the product still under the camera be read again.
      _lastCode = null;
    });
  }

  void _setManual(bool manual) {
    _manual = manual;
    _codeController.clear();
    _lastCode = null;
    _syncCamera();
    setState(() => _error = null);
  }

  void _startBagScan({bool manual = false}) {
    _bagScanStarted = true;
    _setManual(manual);
  }

  void _onDetect(BarcodeCapture capture) {
    final code = firstBarcodeValue(capture);
    if (code != null) _onCameraCode(code, null);
  }

  void _onCameraCode(String code, Uint8List? _) {
    code = code.trim();
    if (!mounted || _manual || code.isEmpty) return;
    final now = DateTime.now();
    final repeated =
        code == _lastCode && now.difference(_lastCodeAt!) < _repeatDelay;
    _lastCodeAt = now;
    if (repeated) return;
    _lastCode = code;
    _handleCode(code);
  }

  void _handleCode(String code) {
    code = code.trim();
    if (code.isEmpty) {
      setState(
        () => _error = _phase == _Phase.bag
            ? 'Enter the bag barcode'
            : 'Enter a barcode',
      );
      return;
    }
    switch (_phase) {
      case _Phase.items:
        _checkItem(code);
      case _Phase.bag:
        _assignBag(code);
      case _Phase.ready:
        break;
    }
  }

  /// Verifies the product [code] belongs to with the quantity on its page,
  /// then slides on to the next product still to scan.
  void _checkItem(String code) {
    final (match, item) = _cubit.matchCode(widget.order, code);
    switch (match) {
      case ScanMatch.matched:
        final quantity = _quantityOf(item!);
        if (!_cubit.confirmQuantity(item, quantity)) {
          _showPage(item);
          HapticFeedback.heavyImpact();
          setState(
            () => _error = quantity != item.quantity
                ? 'Quantity is $quantity but ${item.quantity} were ordered. '
                      'Fix it and scan again.'
                : "Couldn't verify ${item.product}. Scan it again.",
          );
          return;
        }
        HapticFeedback.mediumImpact();
        _codeController.clear();
        _matchedTimer?.cancel();
        _matchedTimer = Timer(const Duration(milliseconds: 1200), () {
          if (mounted) setState(() => _matched = null);
        });
        setState(() {
          _error = null;
          _matched = item.product;
        });
        _showNextAfter(item);
      case ScanMatch.alreadyVerified:
        HapticFeedback.heavyImpact();
        setState(
          () => _error =
              '${item!.product} is already verified. Scan the next item.',
        );
      case ScanMatch.notInOrder:
        HapticFeedback.heavyImpact();
        setState(
          () => _error =
              "This barcode isn't in this order. Check the product and try again.",
        );
    }
  }

  void _showPage(PendingOrderItem item) {
    final index = widget.order.items.indexOf(item);
    if (index >= 0 && index != _page && _pages.hasClients) {
      _pages.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// Next product after [item] that isn't verified yet, wrapping round.
  void _showNextAfter(PendingOrderItem item) {
    final items = widget.order.items;
    final start = items.indexOf(item);
    for (var step = 1; step < items.length; step++) {
      final next = items[(start + step) % items.length];
      if (!_cubit.state.isVerified(next)) {
        _showPage(next);
        return;
      }
    }
  }

  Future<void> _assignBag(String code) async {
    if (_isAssigningBag) return;
    setState(() => _error = null);
    final error = await _cubit.assignBag(widget.order, code);
    if (!mounted) return;
    if (error != null) {
      HapticFeedback.heavyImpact();
      setState(() => _error = error);
      return;
    }
    HapticFeedback.mediumImpact();
  }

  Future<void> _markPreparing() async {
    final prepared = await _cubit.markPreparing(widget.order);
    if (prepared && mounted) widget.onPrepared();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final phase = _phase;
    final total = widget.order.items.length;
    return ColoredBox(
      color: isDark ? AppColors.darkSubCategoryCardColor : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ScanHeader(
            order: widget.order,
            title: switch (phase) {
              _Phase.items => 'Scan items',
              _Phase.bag => 'Assign a bag',
              _Phase.ready => 'Ready to dispatch',
            },
            position: phase == _Phase.items ? '${_page + 1} / $total' : null,
          ),
          Expanded(
            child: phase == _Phase.ready
                ? _buildSummary()
                : _packing
                ? _buildPacking()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 4,
                        child: _manual ? _buildManual() : _buildCamera(),
                      ),
                      Expanded(
                        flex: 5,
                        child: phase == _Phase.items
                            ? _buildPages()
                            : _buildBag(),
                      ),
                    ],
                  ),
          ),
          ScanBottomBar(child: _buildActions(phase)),
        ],
      ),
    );
  }

  // ── Scanning ───────────────────────────────────────────────────────────

  Widget _buildCamera() {
    final message = _matched != null
        ? _ScanMessage(text: '$_matched verified', success: true)
        : _error != null
        ? _ScanMessage(text: _error!, success: false)
        : null;
    return ScanCameraView(
      controller: _scanner,
      preview: widget.cameraBuilder?.call(_onCameraCode),
      onDetect: _onDetect,
      onManualEntry: () => _setManual(true),
      hint: _phase == _Phase.bag
          ? "Point the camera at the bag's barcode."
          : "Point the camera at the product's barcode.",
      footer: message,
    );
  }

  Widget _buildManual() {
    final theme = Theme.of(context);
    final bag = _phase == _Phase.bag;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            bag
                ? "Type the code printed under the bag's barcode."
                : "Type the code printed under the product's barcode.",
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
            enabled: !_isAssigningBag,
            onSubmitted: _handleCode,
            cursorColor: scanFieldColor(context),
            decoration: scanCodeFieldDecoration(context, errorText: _error),
          ),
          if (_matched != null) ...[
            const SizedBox(height: 10),
            _ScanMessage(text: '$_matched verified', success: true),
          ],
        ],
      ),
    );
  }

  Widget _buildPages() {
    final items = widget.order.items;
    final state = widget.state;
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pages,
            itemCount: items.length,
            onPageChanged: (page) => setState(() {
              _page = page;
              _error = null;
            }),
            itemBuilder: (context, index) {
              final item = items[index];
              return _ItemPage(
                item: item,
                quantity: _quantityOf(item),
                verified: state.isVerified(item),
                errors: state.itemErrors[item.orderItemId] ?? const {},
                onQuantity: (delta) => _changeQuantity(item, delta),
              );
            },
          ),
        ),
        if (items.length > 1 && items.length <= 15)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _PageDots(
              count: items.length,
              current: _page,
              verified: [for (final item in items) state.isVerified(item)],
            ),
          ),
      ],
    );
  }

  Widget _buildBag() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BagRow(bag: null, noBagsAvailable: _availableBags == 0),
          const SizedBox(height: 10),
          Text(
            'All ${widget.order.items.length} items verified. Scan a free bag '
            'from your inventory; it stays with this order.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
          ),
          if (_isAssigningBag) ...[
            const SizedBox(height: 12),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }

  /// Between the last item and the bag scanner: pack everything first.
  Widget _buildPacking() {
    final theme = Theme.of(context);
    final items = widget.order.items;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.primaryColor.withValues(alpha: 0.1),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 36,
                color: AppColors.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Put all items in a bag',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'All ${items.length} items are verified. Pack them in one bag, '
            "then scan the bag's barcode.",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 16),
          if (_availableBags == 0) ...[
            const _BagRow(bag: null, noBagsAvailable: true),
            const SizedBox(height: 12),
          ],
          for (final item in items)
            _ChecklistRow(
              item: item,
              verified: widget.state.isVerified(item),
              errors: const {},
            ),
        ],
      ),
    );
  }

  // ── Summary ────────────────────────────────────────────────────────────

  Widget _buildSummary() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final item in widget.order.items)
            _ChecklistRow(
              item: item,
              verified: widget.state.isVerified(item),
              errors: widget.state.itemErrors[item.orderItemId] ?? const {},
            ),
          const SizedBox(height: 4),
          _BagRow(
            bag: widget.state.bagFor(widget.order),
            noBagsAvailable: false,
          ),
        ],
      ),
    );
  }

  // ── Bottom bar ─────────────────────────────────────────────────────────

  Widget _buildActions(_Phase phase) {
    final state = widget.state;
    final orderId = widget.order.sellerOrderId;
    final error = state.failedOrderId == orderId ? state.errorMessage : null;
    final Widget actions;
    if (phase == _Phase.ready) {
      actions = ScanPrimaryButton(
        label: error != null ? 'Retry dispatch' : 'Dispatch order',
        icon: Icons.local_shipping_outlined,
        color: Colors.green.shade600,
        isLoading: state.preparingOrderId == orderId,
        onPressed: _markPreparing,
      );
    } else if (phase == _Phase.bag && _availableBags == 0) {
      actions = ScanPrimaryButton(
        label: 'Add bags',
        icon: Icons.add,
        isLoading: _checkingBags,
        onPressed: _addBags,
      );
    } else if (_packing) {
      actions = Row(
        children: [
          ScanManualEntryButton(onPressed: () => _startBagScan(manual: true)),
          const SizedBox(width: 10),
          Expanded(
            child: ScanPrimaryButton(
              label: 'Scan bag',
              icon: Icons.qr_code_scanner,
              isLoading: _checkingBags,
              onPressed: _startBagScan,
            ),
          ),
        ],
      );
    } else if (_manual) {
      actions = Row(
        children: [
          Expanded(
            child: ScanSecondaryButton(
              label: 'Scan instead',
              onPressed: _isAssigningBag ? null : () => _setManual(false),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ScanPrimaryButton(
              label: phase == _Phase.bag ? 'Assign bag' : 'Check code',
              icon: Icons.check,
              color: Colors.green.shade600,
              isLoading: _isAssigningBag,
              onPressed: () => _handleCode(_codeController.text),
            ),
          ),
        ],
      );
    } else {
      actions = Row(
        children: [
          ScanManualEntryButton(onPressed: () => _setManual(true)),
          const SizedBox(width: 12),
          Expanded(
            child: _Progress(
              verified: state.verifiedCount(widget.order),
              total: widget.order.items.length,
            ),
          ),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (error != null) ...[
          ScanErrorText("Couldn't dispatch the order. $error"),
          const SizedBox(height: 8),
        ],
        actions,
      ],
    );
  }
}

class _ScanHeader extends StatelessWidget {
  final PendingOrder order;
  final String title;

  /// Product on screen, e.g. "2 / 5", while scanning items.
  final String? position;

  const _ScanHeader({required this.order, required this.title, this.position});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryColor,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          Expanded(
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
                const SizedBox(height: 4),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (position != null)
            Text(
              position!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

/// "2 of 5 verified" with a bar, beside the manual-entry button.
class _Progress extends StatelessWidget {
  final int verified;
  final int total;

  const _Progress({required this.verified, required this.total});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$verified of $total verified',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : verified / total,
            minHeight: 6,
            color: Colors.green.shade600,
            backgroundColor: theme.hintColor.withValues(alpha: 0.2),
          ),
        ),
      ],
    );
  }
}

/// Result of the last scan, pinned over the bottom of the camera.
class _ScanMessage extends StatelessWidget {
  final String text;
  final bool success;

  const _ScanMessage({required this.text, required this.success});

  @override
  Widget build(BuildContext context) {
    final color = success ? Colors.green.shade700 : Colors.red.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            success ? Icons.check_circle : Icons.error_outline,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One product of the order: what to pick and how many.
class _ItemPage extends StatelessWidget {
  final PendingOrderItem item;
  final int quantity;
  final bool verified;
  final Map<String, String> errors;
  final void Function(int delta) onQuantity;

  const _ItemPage({
    required this.item,
    required this.quantity,
    required this.verified,
    required this.errors,
    required this.onQuantity,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final green = Colors.green.shade600;
    final mismatch = quantity != item.quantity;
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Thumb(image: item.image, size: 88),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (item.variant != null)
                    Text(
                      item.variant!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    '${HiveStorage.currencySymbol}${item.subtotal}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!item.hasBarcode) ...[
          const SizedBox(height: 8),
          Text(
            'Barcode missing for ${item.product}. Contact support.',
            style: TextStyle(color: Colors.red.shade600),
          ),
        ],
        for (final error in errors.entries)
          Text(
            '${error.key}: ${error.value}',
            style: TextStyle(color: Colors.red.shade600),
          ),
      ],
    );
    final status = verified
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: green.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: green.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Verified',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: green,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${item.quantity}/${item.quantity}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: green,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          )
        : Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quantity',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Ordered ${item.quantity}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.outlined(
                tooltip: 'Decrease',
                onPressed: quantity > 1 ? () => onQuantity(-1) : null,
                icon: const Icon(Icons.remove),
              ),
              SizedBox(
                width: 56,
                child: Text(
                  '$quantity',
                  key: ValueKey('qty-${item.orderItemId}'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: mismatch ? Colors.orange.shade800 : null,
                  ),
                ),
              ),
              IconButton.outlined(
                tooltip: 'Increase',
                onPressed: () => onQuantity(1),
                icon: const Icon(Icons.add),
              ),
            ],
          );
    // The quantity stays in view; only the product details scroll. Too
    // short for that (keyboard open): everything scrolls.
    return LayoutBuilder(
      builder: (context, constraints) {
        const padding = EdgeInsets.fromLTRB(16, 12, 16, 8);
        if (constraints.maxHeight < 150) {
          return SingleChildScrollView(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [details, const SizedBox(height: 10), status],
            ),
          );
        }
        return Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: SingleChildScrollView(child: details)),
              const SizedBox(height: 10),
              status,
            ],
          ),
        );
      },
    );
  }
}

class _PageDots extends StatelessWidget {
  final int count;
  final int current;
  final List<bool> verified;

  const _PageDots({
    required this.count,
    required this.current,
    required this.verified,
  });

  @override
  Widget build(BuildContext context) {
    final idle = Theme.of(context).hintColor.withValues(alpha: 0.3);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == current ? 18 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: i == current
                  ? AppColors.primaryColor
                  : verified[i]
                  ? Colors.green.shade600
                  : idle,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}

/// The order's bag: assigned (green, final) or still to be scanned.
class _BagRow extends StatelessWidget {
  final AssignedBag? bag;
  final bool noBagsAvailable;

  const _BagRow({required this.bag, required this.noBagsAvailable});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bag = this.bag;
    final assigned = bag != null;
    final color = assigned
        ? Colors.green.shade700
        : noBagsAvailable
        ? Colors.orange.shade800
        : AppColors.primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: assigned
            ? Colors.green.shade50
            : noBagsAvailable
            ? Colors.orange.shade50
            : AppColors.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(
            assigned ? Icons.inventory_2 : Icons.shopping_bag_outlined,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: assigned
                ? Text(
                    bag.barcode,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  )
                : Text(
                    noBagsAvailable
                        ? "You don't have any available bags. Add bags to your "
                              'inventory to continue.'
                        : 'No bag assigned yet. Scan a bag for this order.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: color),
                  ),
          ),
          if (assigned)
            Text(
              'Assigned',
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
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
            verified ? Icons.check_circle : Icons.error_outline,
            color: verified ? green : Colors.red.shade600,
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
                  ].join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
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
  final double size;

  const _Thumb({required this.image, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: AppColors.stepCurrentBgColor,
      child: Icon(
        Icons.inventory_2_outlined,
        color: AppColors.primaryColor,
        size: size * 0.45,
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(size > 60 ? 14 : 10),
      child: SizedBox(
        width: size,
        height: size,
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
