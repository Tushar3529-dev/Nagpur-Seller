import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/screen/order_page/incoming_orders/model/pending_order_model.dart';
import 'package:hyper_local_seller/screen/order_page/incoming_orders/repo/pending_orders_repo.dart';

part 'incoming_orders_state.dart';

/// Holds the stack of regular orders waiting for the seller to accept.
///
/// The server is the source of truth: pushes, app resume and a periodic poll
/// all just call [fetch]. While the list is non-empty the app shows the
/// blocking incoming-order overlay and rings.
class IncomingOrdersCubit extends Cubit<IncomingOrdersState> {
  final PendingOrdersRepo _repo;

  IncomingOrdersCubit(this._repo) : super(const IncomingOrdersState());

  bool _isFetching = false;
  bool _refetchQueued = false;

  /// Accept/preparing steps that already succeeded, keyed by order_item_id,
  /// so a retry after a partial failure only resends what's missing.
  final Map<int, Set<_Step>> _doneSteps = {};

  /// Orders accepted on this device recently. The pending endpoint can lag
  /// behind the accept call, so these are hidden for a short while.
  final Map<int, DateTime> _recentlyAccepted = {};
  static const _acceptedGrace = Duration(seconds: 60);

  static bool get _isLoggedIn {
    final token = HiveStorage.userToken;
    return token != null && token.trim().isNotEmpty;
  }

  Future<void> fetch() async {
    if (!_isLoggedIn) return;
    if (_isFetching) {
      _refetchQueued = true;
      return;
    }
    _isFetching = true;
    try {
      final orders = await _repo.getPendingRegularOrders();
      if (isClosed || !_isLoggedIn) return;
      emit(state.copyWith(orders: _arrange(orders)));
    } catch (e) {
      // Keep whatever is on screen — being offline must not drop the popup.
      debugPrint('[IncomingOrders] fetch failed: $e');
    } finally {
      _isFetching = false;
      if (_refetchQueued) {
        _refetchQueued = false;
        fetch();
      }
    }
  }

  /// Accepts every item of [order] and moves them to preparing.
  /// Returns true when the whole order went through.
  Future<bool> accept(PendingOrder order) async {
    if (state.acceptingOrderId != null) return false;
    emit(
      state.copyWith(acceptingOrderId: order.sellerOrderId, clearError: true),
    );

    try {
      for (final item in order.items) {
        final done = _doneSteps.putIfAbsent(item.orderItemId, () => {});
        if (!done.contains(_Step.accept)) {
          await _repo.acceptItem(item.orderItemId);
          done.add(_Step.accept);
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
      return false;
    }

    for (final item in order.items) {
      _doneSteps.remove(item.orderItemId);
    }
    _recentlyAccepted[order.sellerOrderId] = DateTime.now();
    if (!isClosed) {
      emit(
        state.copyWith(
          orders: state.orders
              .where((o) => o.sellerOrderId != order.sellerOrderId)
              .toList(),
          clearAccepting: true,
        ),
      );
    }
    fetch();
    return true;
  }

  /// Called on logout.
  void clear() {
    _doneSteps.clear();
    _recentlyAccepted.clear();
    emit(const IncomingOrdersState());
  }

  /// Newest order on top of the stack, except that an order being accepted
  /// stays on top so the card doesn't change under the seller's finger.
  List<PendingOrder> _arrange(List<PendingOrder> orders) {
    final now = DateTime.now();
    _recentlyAccepted.removeWhere(
      (_, acceptedAt) => now.difference(acceptedAt) > _acceptedGrace,
    );

    final visible =
        orders
            .where((o) => !_recentlyAccepted.containsKey(o.sellerOrderId))
            .toList()
          ..sort((a, b) {
            final aTime = a.createdAt ?? now;
            final bTime = b.createdAt ?? now;
            return bTime.compareTo(aTime);
          });

    final acceptingId = state.acceptingOrderId;
    if (acceptingId != null) {
      final index = visible.indexWhere((o) => o.sellerOrderId == acceptingId);
      if (index > 0) visible.insert(0, visible.removeAt(index));
    }
    return visible;
  }
}

enum _Step { accept, preparing }
