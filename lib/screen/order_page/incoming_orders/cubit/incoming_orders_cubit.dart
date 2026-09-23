import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/screen/order_page/incoming_orders/model/pending_order_model.dart';
import 'package:hyper_local_seller/screen/order_page/incoming_orders/repo/pending_orders_repo.dart';

part 'incoming_orders_state.dart';

/// Holds the queue of orders (regular and wholesale) waiting for the seller
/// to accept.
///
/// The server is the source of truth: pushes, app resume and a periodic poll
/// all just call [fetch]. While the queue is non-empty the app shows the
/// blocking incoming-order overlay and rings.
class IncomingOrdersCubit extends Cubit<IncomingOrdersState> {
  final PendingOrdersRepo _repo;

  IncomingOrdersCubit(this._repo) : super(const IncomingOrdersState());

  bool _isFetching = false;
  bool _refetchQueued = false;

  /// Last list received per mode. If one endpoint fails, the other mode's
  /// orders (and the failed mode's last known orders) stay on screen.
  final Map<OrderMode, List<PendingOrder>> _latest = {
    OrderMode.regular: const [],
    OrderMode.wholesale: const [],
  };

  /// Accept/preparing steps that already succeeded, keyed by order_item_id,
  /// so a retry after a partial failure only resends what's missing.
  final Map<int, Set<_Step>> _doneSteps = {};

  // Once wholesale acceptance starts succeeding, popup=1 may omit accepted
  // items or the whole order. Keep the original items until preparing finishes
  // so a retry cannot silently skip unfinished work. Regular flow is unchanged.
  final Map<int, PendingOrder> _wholesalePreparing = {};

  /// seller_order_ids accepted on this device. Never shown again this
  /// session, even if the pending endpoint still lists them for a while.
  final Set<int> _handled = {};

  static bool get _isLoggedIn {
    final token = HiveStorage.userToken;
    return token != null && token.trim().isNotEmpty;
  }

  Future<void> fetch() async {
    if (!_isLoggedIn) return;
    // No fetching while an accept is running; accept() fetches when done.
    if (_isFetching || state.acceptingOrderId != null) {
      _refetchQueued = true;
      return;
    }
    _isFetching = true;
    try {
      await Future.wait([
        _fetchMode(OrderMode.regular),
        _fetchMode(OrderMode.wholesale),
      ]);
      if (isClosed || !_isLoggedIn) return;
      _publish();
    } finally {
      _isFetching = false;
      if (_refetchQueued && state.acceptingOrderId == null) {
        _refetchQueued = false;
        fetch();
      }
    }
  }

  Future<void> _fetchMode(OrderMode mode) async {
    try {
      _latest[mode] = await _repo.getPendingOrders(mode);
    } catch (e) {
      // Keep the last list — being offline must not drop the popup.
      debugPrint('[IncomingOrders] ${mode.name} fetch failed: $e');
    }
  }

  /// Accepts every item of [order] and moves them to preparing.
  /// Returns true when the whole order went through.
  Future<bool> accept(PendingOrder order) async {
    if (state.acceptingOrderId != null) return false;
    if (_handled.contains(order.sellerOrderId)) return true;
    emit(
      state.copyWith(acceptingOrderId: order.sellerOrderId, clearError: true),
    );

    try {
      for (final item in order.items) {
        final done = _doneSteps.putIfAbsent(item.orderItemId, () => {});
        if (!done.contains(_Step.accept)) {
          await _repo.acceptItem(item.orderItemId);
          done.add(_Step.accept);
          if (order.isWholesale) {
            _wholesalePreparing.putIfAbsent(order.sellerOrderId, () => order);
          }
        }
        if (!done.contains(_Step.preparing)) {
          await _repo.markItemPreparing(item.orderItemId);
          done.add(_Step.preparing);
        }
      }
    } catch (e) {
      debugPrint(
        '[IncomingOrders] accept failed for ${order.sellerOrderId}: $e',
      );
      if (!isClosed) {
        emit(
          state.copyWith(
            clearAccepting: true,
            failedOrderId: order.sellerOrderId,
            errorMessage: e.toString(),
          ),
        );
      }
      _resumeFetching();
      return false;
    }

    for (final item in order.items) {
      _doneSteps.remove(item.orderItemId);
    }
    _handled.add(order.sellerOrderId);
    _wholesalePreparing.remove(order.sellerOrderId);
    if (!isClosed) {
      emit(state.copyWith(clearAccepting: true));
      _publish();
    }
    _resumeFetching();
    return true;
  }

  void _resumeFetching() {
    _refetchQueued = false;
    fetch();
  }

  /// Called on logout.
  void clear() {
    debugPrint('[IncomingOrders] cleared (logout)');
    _doneSteps.clear();
    _wholesalePreparing.clear();
    _handled.clear();
    _latest.updateAll((_, _) => const []);
    emit(const IncomingOrdersState());
  }

  /// Merges both modes into one queue: deduplicated by seller_order_id,
  /// accepted orders removed, oldest first (first come, first served).
  void _publish() {
    final now = DateTime.now();
    final byId = <int, PendingOrder>{};
    for (final order in [
      ..._latest[OrderMode.regular]!,
      ..._latest[OrderMode.wholesale]!,
    ]) {
      if (_handled.contains(order.sellerOrderId)) continue;
      byId.putIfAbsent(order.sellerOrderId, () => order);
    }
    byId.addAll(_wholesalePreparing);

    // When each order first appeared in the popup. Wholesale orders were
    // placed long before their popup window, so their timer starts here.
    final shownAt = <int, DateTime>{
      for (final id in byId.keys) id: state.shownAt[id] ?? now,
    };

    DateTime appeared(PendingOrder o) => o.isWholesale
        ? shownAt[o.sellerOrderId]!
        : (o.createdAt?.toLocal() ?? shownAt[o.sellerOrderId]!);

    final queue = byId.values.toList()
      ..sort((a, b) => appeared(a).compareTo(appeared(b)));

    // The card on screen stays on top until it's handled (or the backend
    // drops it), so a new order never replaces it mid-read.
    final pinnedId =
        state.acceptingOrderId ??
        (state.orders.isEmpty ? null : state.orders.first.sellerOrderId);
    if (pinnedId != null) {
      final index = queue.indexWhere((o) => o.sellerOrderId == pinnedId);
      if (index > 0) queue.insert(0, queue.removeAt(index));
    }

    if (kDebugMode) {
      final ids = queue.map((o) => o.sellerOrderId).toList();
      final before = state.orders.map((o) => o.sellerOrderId).toList();
      if (!listEquals(ids, before)) {
        debugPrint('[IncomingOrders] queue $before -> $ids');
      }
    }
    emit(state.copyWith(orders: queue, shownAt: shownAt));
  }
}

enum _Step { accept, preparing }
