import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';
import 'package:hyper_local_seller/screen/order_page/incoming_orders/model/pending_order_model.dart';
import 'package:hyper_local_seller/screen/order_page/incoming_orders/repo/pending_orders_repo.dart';
import 'package:hyper_local_seller/screen/order_page/incoming_orders/repo/scan_session_store.dart';

part 'incoming_orders_state.dart';

/// Holds the queue of orders (regular and wholesale) in the incoming-order
/// popup, from arrival until they're marked as preparing:
///
/// 1. [accept] — the order stays in the popup, now with a barcode per item.
/// 2. [matchCode] + [confirmQuantity] — per item, until all are verified.
/// 3. [markPreparing] — the order leaves the popup.
///
/// The server is the source of truth for new orders: pushes, app resume and
/// a periodic poll all just call [fetch]. Accepted orders are kept here (and
/// on the device) to preserve local verification progress across restarts.
class IncomingOrdersCubit extends Cubit<IncomingOrdersState> {
  final PendingOrdersRepo _repo;
  final ScanSessionStore _store;

  IncomingOrdersCubit(this._repo, {ScanSessionStore? store})
    : _store = store ?? ScanSessionStore(),
      super(const IncomingOrdersState());

  bool _isFetching = false;
  bool _refetchQueued = false;
  bool _restored = false;
  int _sessionGeneration = 0;
  final Map<int, String> _matchedCodes = {};

  /// Last list received per mode. If one endpoint fails, the other mode's
  /// orders (and the failed mode's last known orders) stay on screen.
  final Map<OrderMode, List<PendingOrder>> _latest = {
    OrderMode.regular: const [],
    OrderMode.wholesale: const [],
  };

  /// Accept/preparing steps that already succeeded, keyed by order_item_id,
  /// so a retry after a partial failure only resends what's missing.
  final Map<int, Set<_Step>> _doneSteps = {};

  /// Orders kept in the queue whatever the pending endpoint says: accepted
  /// ones (carrying barcodes) being scanned, and ones part way through
  /// accept, so a retry cannot silently skip unfinished work.
  final Map<int, PendingOrder> _held = {};

  /// seller_order_ids marked as preparing on this device. Never shown again
  /// this session, even if the pending endpoint still lists them for a while.
  final Set<int> _handled = {};

  static bool get _isLoggedIn {
    final token = HiveStorage.userToken;
    return token != null && token.trim().isNotEmpty;
  }

  Future<void> fetch() async {
    if (!_isLoggedIn) return;
    // No fetching while an accept or preparing call is running; they fetch
    // when done.
    if (_isFetching || state.isBusy) {
      _refetchQueued = true;
      return;
    }
    _isFetching = true;
    final generation = _sessionGeneration;
    try {
      if (!_restored) {
        _restored = true;
        await _restore(generation);
      }
      await Future.wait([
        _fetchMode(OrderMode.regular, generation),
        _fetchMode(OrderMode.wholesale, generation),
      ]);
      if (isClosed || !_isLoggedIn || generation != _sessionGeneration) return;
      _publish();
    } finally {
      _isFetching = false;
      if (_refetchQueued && !state.isBusy) {
        _refetchQueued = false;
        fetch();
      }
    }
  }

  Future<void> _fetchMode(OrderMode mode, int generation) async {
    try {
      final orders = await _repo.getPendingOrders(mode);
      if (generation == _sessionGeneration && !isClosed) {
        _latest[mode] = orders;
      }
    } catch (e) {
      // Keep the last list — being offline must not drop the popup.
      debugPrint('[IncomingOrders] ${mode.name} fetch failed: $e');
    }
  }

  /// Brings back orders that were being scanned when the app last closed,
  /// unless the server says they were prepared, rejected or cancelled since.
  Future<void> _restore(int generation) async {
    final sessions = await _store.load();
    if (sessions.isEmpty || isClosed || generation != _sessionGeneration) {
      return;
    }

    final accepted = <int>{};
    final verified = <int>{};
    final verifiedBarcodes = <int, String>{};
    for (final session in sessions) {
      var order = session.order;
      Map<int, String>? statuses;
      try {
        statuses = await _repo.itemStatuses(order.sellerOrderId);
      } catch (e) {
        // Offline: keep the order rather than lose the scan progress.
        debugPrint('[IncomingOrders] status check failed: $e');
      }
      if (isClosed || generation != _sessionGeneration) return;
      if (statuses != null &&
          statuses.isNotEmpty &&
          !order.items.any((i) => statuses![i.orderItemId] == 'accepted')) {
        debugPrint('[IncomingOrders] dropped stale ${order.sellerOrderId}');
        continue;
      }
      // Old per-item flows can have a mix of accepted and preparing lines.
      if (statuses != null && statuses.isNotEmpty) {
        order = order.copyWith(
          items: [
            for (final item in order.items)
              if (statuses[item.orderItemId] == 'accepted')
                item.copyWith(status: 'accepted'),
          ],
        );
      }
      _held[order.sellerOrderId] = order;
      accepted.add(order.sellerOrderId);
      for (final item in order.items) {
        final code = session.verifiedBarcodes[item.orderItemId];
        // Legacy sessions lack scanned values and must be scanned again.
        if (code != null &&
            session.verifiedItemIds.contains(item.orderItemId) &&
            item.matchesCode(code)) {
          verified.add(item.orderItemId);
          verifiedBarcodes[item.orderItemId] = code;
        }
      }
      for (final item in order.items) {
        final done = _doneSteps.putIfAbsent(item.orderItemId, () => {})
          ..add(_Step.accept);
        if (statuses?[item.orderItemId] == 'preparing') {
          done.add(_Step.preparing);
        }
      }
    }
    if (isClosed) return;
    emit(
      state.copyWith(
        acceptedOrderIds: {...state.acceptedOrderIds, ...accepted},
        verifiedItemIds: {...state.verifiedItemIds, ...verified},
        verifiedBarcodes: {...state.verifiedBarcodes, ...verifiedBarcodes},
      ),
    );
    _save();
  }

  /// Accepts every item of [order]. On success the order stays in the popup
  /// for scanning. Returns true when the whole order went through.
  Future<bool> accept(PendingOrder order) async {
    if (state.isBusy) return false;
    if (state.isAccepted(order)) return true;
    final generation = _sessionGeneration;
    emit(
      state.copyWith(acceptingOrderId: order.sellerOrderId, clearError: true),
    );

    final PendingOrder accepted;
    try {
      accepted = await _repo.acceptOrder(
        order,
        skipItemIds: _itemsDone(order, _Step.accept),
        onItemAccepted: (id) {
          if (isClosed || generation != _sessionGeneration) return;
          _doneSteps.putIfAbsent(id, () => {}).add(_Step.accept);
          _held.putIfAbsent(order.sellerOrderId, () => order);
        },
      );
    } catch (e) {
      if (!isClosed && generation == _sessionGeneration) {
        _fail(order, e, 'accept');
      }
      return false;
    }

    if (isClosed || generation != _sessionGeneration) return false;
    _held[order.sellerOrderId] = accepted;
    if (!isClosed) {
      emit(
        state.copyWith(
          clearAccepting: true,
          acceptedOrderIds: {...state.acceptedOrderIds, order.sellerOrderId},
        ),
      );
      _publish();
    }
    _resumeFetching();
    return true;
  }

  /// Finds the item of [order] that a scanned or typed [code] belongs to.
  /// Unverified items win when several share a barcode.
  (ScanMatch, PendingOrderItem?) matchCode(PendingOrder order, String code) {
    PendingOrderItem? alreadyVerified;
    final current =
        state.orders
            .where((o) => o.sellerOrderId == order.sellerOrderId)
            .firstOrNull ??
        order;
    for (final item in current.items) {
      if (!item.matchesCode(code)) continue;
      if (!state.isVerified(item)) {
        _matchedCodes[item.orderItemId] = code.trim();
        return (ScanMatch.matched, item);
      }
      alreadyVerified = item;
    }
    return alreadyVerified != null
        ? (ScanMatch.alreadyVerified, alreadyVerified)
        : (ScanMatch.notInOrder, null);
  }

  /// Marks [item] verified if [quantity] is exactly what was ordered.
  bool confirmQuantity(PendingOrderItem item, int quantity) {
    final currentOrder = state.orders
        .where(
          (order) =>
              order.items.any((line) => line.orderItemId == item.orderItemId),
        )
        .firstOrNull;
    final current = currentOrder?.items
        .where((line) => line.orderItemId == item.orderItemId)
        .firstOrNull;
    final code = _matchedCodes[item.orderItemId];
    if (currentOrder == null ||
        !state.isAccepted(currentOrder) ||
        current == null ||
        quantity != current.quantity ||
        code == null ||
        !current.matchesCode(code)) {
      return false;
    }
    emit(
      state.copyWith(
        verifiedItemIds: {...state.verifiedItemIds, item.orderItemId},
        verifiedBarcodes: {...state.verifiedBarcodes, item.orderItemId: code},
        itemErrors: {...state.itemErrors}..remove(item.orderItemId),
      ),
    );
    _save();
    return true;
  }

  /// Moves a fully verified [order] to preparing and out of the popup.
  Future<bool> markPreparing(PendingOrder order) async {
    if (state.isBusy) return false;
    order =
        state.orders
            .where((o) => o.sellerOrderId == order.sellerOrderId)
            .firstOrNull ??
        order;
    if (!state.isFullyVerified(order)) return false;
    final generation = _sessionGeneration;
    emit(
      state.copyWith(preparingOrderId: order.sellerOrderId, clearError: true),
    );

    try {
      await _repo.markOrderPreparing(
        order,
        verifiedBarcodes: state.verifiedBarcodes,
        onItemDone: (id) {
          if (!isClosed && generation == _sessionGeneration) {
            _doneSteps.putIfAbsent(id, () => {}).add(_Step.preparing);
          }
        },
      );
    } catch (e) {
      if (!isClosed && generation == _sessionGeneration) {
        _fail(order, e, 'preparing');
      }
      return false;
    }

    if (isClosed || generation != _sessionGeneration) return false;
    final itemIds = order.items.map((item) => item.orderItemId);
    itemIds.forEach(_doneSteps.remove);
    itemIds.forEach(_matchedCodes.remove);
    _handled.add(order.sellerOrderId);
    _held.remove(order.sellerOrderId);
    if (!isClosed) {
      emit(
        state.copyWith(
          clearPreparing: true,
          acceptedOrderIds: {...state.acceptedOrderIds}
            ..remove(order.sellerOrderId),
          verifiedItemIds: {...state.verifiedItemIds}..removeAll(itemIds),
          verifiedBarcodes: {...state.verifiedBarcodes}
            ..removeWhere((id, _) => itemIds.contains(id)),
        ),
      );
      _publish();
    }
    _save();
    _resumeFetching();
    return true;
  }

  Set<int> _itemsDone(PendingOrder order, _Step step) => {
    for (final item in order.items)
      if (_doneSteps[item.orderItemId]?.contains(step) ?? false)
        item.orderItemId,
  };

  void _fail(PendingOrder order, Object error, String action) {
    debugPrint(
      '[IncomingOrders] $action failed for ${order.sellerOrderId}: $error',
    );
    if (!isClosed) {
      final itemErrors = <int, Map<String, String>>{};
      if (error is ApiException) {
        final data = error.responseData?['data'];
        final errors = data is Map ? data['errors'] : null;
        if (errors is List) {
          for (final detail in errors.whereType<Map>()) {
            final id = int.tryParse('${detail['order_item_id']}');
            if (id == null ||
                !order.items.any((item) => item.orderItemId == id)) {
              continue;
            }
            itemErrors.putIfAbsent(
                  id,
                  () => {},
                )['${detail['field'] ?? 'item'}'] =
                '${detail['message'] ?? error.message}';
            _matchedCodes.remove(id);
          }
        }
      }
      emit(
        state.copyWith(
          clearAccepting: true,
          clearPreparing: true,
          itemErrors: itemErrors,
          verifiedItemIds: {...state.verifiedItemIds}
            ..removeAll(itemErrors.keys),
          verifiedBarcodes: {...state.verifiedBarcodes}
            ..removeWhere((id, _) => itemErrors.containsKey(id)),
          failedOrderId: order.sellerOrderId,
          errorMessage: error.toString(),
        ),
      );
    }
    _save();
    _resumeFetching();
  }

  void _resumeFetching() {
    _refetchQueued = false;
    fetch();
  }

  void _save() {
    _store.save([
      for (final id in state.acceptedOrderIds)
        if (_held[id] case final order?)
          ScanSession(
            order,
            {
              for (final item in order.items)
                if (state.isVerified(item)) item.orderItemId,
            },
            verifiedBarcodes: {
              for (final item in order.items)
                if (state.verifiedBarcodes[item.orderItemId] case final code?)
                  item.orderItemId: code,
            },
          ),
    ]);
  }

  /// Called on logout.
  void clear() {
    debugPrint('[IncomingOrders] cleared (logout)');
    _sessionGeneration++;
    _refetchQueued = false;
    _doneSteps.clear();
    _matchedCodes.clear();
    _held.clear();
    _handled.clear();
    _latest.updateAll((_, _) => const []);
    _restored = false;
    _store.clear();
    emit(const IncomingOrdersState());
  }

  /// Merges both modes into one queue: deduplicated by seller_order_id,
  /// prepared orders removed, accepted orders first, then oldest first
  /// (first come, first served).
  void _publish() {
    final now = DateTime.now();
    final byId = <int, PendingOrder>{};
    final accepted = {...state.acceptedOrderIds};
    final verified = {...state.verifiedItemIds};
    final codes = {...state.verifiedBarcodes};
    for (final order in [
      ..._latest[OrderMode.regular]!,
      ..._latest[OrderMode.wholesale]!,
    ]) {
      if (_handled.contains(order.sellerOrderId)) continue;
      if (order.isAcceptedOnServer) {
        final old = _held[order.sellerOrderId];
        for (final item in order.items) {
          final previous = old?.items
              .where((line) => line.orderItemId == item.orderItemId)
              .firstOrNull;
          if (previous?.quantity != item.quantity ||
              !item.matchesCode(codes[item.orderItemId] ?? '')) {
            verified.remove(item.orderItemId);
            codes.remove(item.orderItemId);
          }
          final matched = _matchedCodes[item.orderItemId];
          if (previous?.quantity != item.quantity ||
              (matched != null && !item.matchesCode(matched))) {
            _matchedCodes.remove(item.orderItemId);
          }
        }
        accepted.add(order.sellerOrderId);
        _held[order.sellerOrderId] = order;
      }
      byId.putIfAbsent(order.sellerOrderId, () => order);
    }
    byId.addAll(_held);

    // When each order first appeared in the popup. Wholesale orders were
    // placed long before their popup window, so their timer starts here.
    final shownAt = <int, DateTime>{
      for (final id in byId.keys) id: state.shownAt[id] ?? now,
    };

    DateTime appeared(PendingOrder o) => o.isWholesale
        ? shownAt[o.sellerOrderId]!
        : (o.createdAt?.toLocal() ?? shownAt[o.sellerOrderId]!);
    int acceptedFirst(PendingOrder o) =>
        accepted.contains(o.sellerOrderId) ? 0 : 1;

    final queue = byId.values.toList()
      ..sort((a, b) {
        final byAccepted = acceptedFirst(a).compareTo(acceptedFirst(b));
        return byAccepted != 0
            ? byAccepted
            : appeared(a).compareTo(appeared(b));
      });

    // The card on screen stays on top until it's handled (or the backend
    // drops it), so a new order never replaces it mid-read.
    final pinnedId =
        state.acceptingOrderId ??
        state.preparingOrderId ??
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
    final activeItems = queue
        .expand((order) => order.items)
        .map((item) => item.orderItemId)
        .toSet();
    verified.retainAll(activeItems);
    codes.removeWhere((id, _) => !verified.contains(id));
    final sessionsChanged =
        !setEquals(accepted, state.acceptedOrderIds) ||
        !setEquals(verified, state.verifiedItemIds) ||
        !listEquals(
          queue
              .where((order) => accepted.contains(order.sellerOrderId))
              .toList(),
          state.orders.where(state.isAccepted).toList(),
        );
    emit(
      state.copyWith(
        orders: queue,
        shownAt: shownAt,
        acceptedOrderIds: accepted..retainAll(byId.keys),
        verifiedItemIds: verified,
        verifiedBarcodes: codes,
      ),
    );
    if (sessionsChanged) _save();
  }
}

enum _Step { accept, preparing }
