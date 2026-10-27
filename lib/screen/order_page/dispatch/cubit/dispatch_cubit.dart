import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/screen/order_page/dispatch/model/dispatch_model.dart';
import 'package:hyper_local_seller/screen/order_page/dispatch/repo/dispatch_repo.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';
import 'dispatch_state.dart';

export 'dispatch_state.dart';

class DispatchCubit extends Cubit<DispatchState> {
  final DispatchRepo _repo;
  final Duration pollInterval;
  Timer? _timer;
  Future<void>? _inFlight;
  int _session = 0;
  int _revision = 0;
  final _pollingOwners = <Object>{};

  DispatchCubit(this._repo, {this.pollInterval = const Duration(seconds: 15)})
    : super(const DispatchState());

  Future<void> load() => _fetch(silent: false);
  Future<void> refresh({bool silent = true}) => _fetch(silent: silent);

  Future<void> _fetch({required bool silent}) {
    if (isClosed) return Future.value();
    if (_inFlight != null) return _inFlight!;
    final session = _session;
    final revision = _revision;
    final task = _read(session, revision, silent);
    _inFlight = task;
    return task.whenComplete(() {
      if (identical(_inFlight, task)) _inFlight = null;
    });
  }

  Future<void> _read(int session, int revision, bool silent) async {
    emit(
      state.copyWith(
        isLoading: state.dashboard == null,
        isRefreshing: state.dashboard != null,
        clearError: true,
      ),
    );
    try {
      var dashboard = await _repo.getDashboard();
      if (isClosed || session != _session || revision != _revision) return;
      // A poll cannot put a still-pending optimistic order back into dispatch.
      for (final id in state.pendingSelfDeliver) {
        dashboard = _replace(
          dashboard,
          id,
          (order) => order.copyWith(
            status: DispatchStatus.sellerSelfDelivery,
            deliveryBoyId: () => null,
            deliveryBoyName: () => null,
          ),
        );
      }
      emit(
        state.copyWith(
          dashboard: dashboard,
          isLoading: false,
          isRefreshing: false,
          clearError: true,
          lastUpdated: DateTime.now(),
        ),
      );
    } catch (error) {
      if (isClosed || session != _session || revision != _revision) return;
      debugPrint('Dispatch dashboard refresh failed');
      emit(
        state.copyWith(
          isLoading: false,
          isRefreshing: false,
          error: state.dashboard == null || !silent
              ? (error is ApiException ? error.message : '')
              : null,
          clearError: state.dashboard != null && silent,
        ),
      );
    }
  }

  void startPolling() {
    if (isClosed || _timer != null) return;
    unawaited(refresh());
    _timer = Timer.periodic(pollInterval, (_) => refresh());
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  // Visible Orders/Dispatch pages share a timer; releasing one never stops the other.
  void setPollingOwner(Object owner, {required bool visible}) {
    if (visible) {
      _pollingOwners.add(owner);
      startPolling();
    } else {
      _pollingOwners.remove(owner);
      if (_pollingOwners.isEmpty) stopPolling();
    }
  }

  void setFilter(DispatchFilter filter) => emit(state.copyWith(filter: filter));

  DispatchDashboard _replace(
    DispatchDashboard dashboard,
    int id,
    DispatchOrder Function(DispatchOrder) change,
  ) {
    var noRider = dashboard.summary.noNearbyRiders;
    var assigned = dashboard.summary.assignedOrders;
    bool isAssigned(DispatchStatus status) =>
        status == DispatchStatus.riderAssigned ||
        status == DispatchStatus.sellerSelfDelivery;
    final orders = dashboard.orders.map((order) {
      if (order.orderId != id) return order;
      final replacement = change(order);
      noRider +=
          (replacement.status.needsAction ? 1 : 0) -
          (order.status.needsAction ? 1 : 0);
      assigned +=
          (isAssigned(replacement.status) ? 1 : 0) -
          (isAssigned(order.status) ? 1 : 0);
      return replacement;
    }).toList();
    return DispatchDashboard(
      summary: DispatchSummary(
        readyOrders: dashboard.summary.readyOrders,
        noNearbyRiders: noRider.clamp(0, 1 << 30),
        assignedOrders: assigned.clamp(0, 1 << 30),
      ),
      orders: orders,
    );
  }

  Future<SelfDeliverResult> selfDeliver(int orderId) async {
    if (isClosed || state.pendingSelfDeliver.contains(orderId)) {
      return const SelfDeliverResult.ignored();
    }
    final dashboard = state.dashboard;
    DispatchOrder? previous;
    for (final order in dashboard?.orders ?? <DispatchOrder>[]) {
      if (order.orderId == orderId) previous = order;
    }
    if (dashboard == null ||
        previous == null ||
        !previous.status.canSelfDeliver) {
      return const SelfDeliverResult.ignored();
    }
    final original = previous;
    final session = _session;
    _revision++;
    final optimistic = _replace(
      dashboard,
      orderId,
      (order) => order.copyWith(
        status: DispatchStatus.sellerSelfDelivery,
        deliveryBoyId: () => null,
        deliveryBoyName: () => null,
      ),
    );
    emit(
      state.copyWith(
        dashboard: optimistic,
        pendingSelfDeliver: {...state.pendingSelfDeliver, orderId},
        isLoading: false,
        isRefreshing: false,
      ),
    );
    try {
      await _repo.markSelfDelivery(orderId);
      if (isClosed || session != _session) {
        return const SelfDeliverResult.ignored();
      }
      final message = _repo.lastMessage;
      _revision++;
      emit(
        state.copyWith(
          pendingSelfDeliver: {...state.pendingSelfDeliver}..remove(orderId),
          isRefreshing: false,
        ),
      );
      unawaited(_refreshAfterWrite(session));
      return SelfDeliverResult.success(message);
    } catch (error) {
      if (isClosed || session != _session) {
        return const SelfDeliverResult.ignored();
      }
      _revision++;
      emit(
        state.copyWith(
          // Restore the exact snapshot unless another order or poll has changed it.
          dashboard: identical(state.dashboard, optimistic)
              ? dashboard
              : _replace(state.dashboard!, orderId, (_) => original),
          pendingSelfDeliver: {...state.pendingSelfDeliver}..remove(orderId),
          isRefreshing: false,
        ),
      );
      final apiError = error is ApiException ? error : null;
      if (apiError?.statusCode == 409 || apiError?.statusCode == 404) {
        unawaited(_refreshAfterWrite(session));
      }
      return SelfDeliverResult.failure(
        apiError?.message ?? '',
        statusCode: apiError?.statusCode,
      );
    }
  }

  Future<void> _refreshAfterWrite(int session) async {
    final pendingRead = _inFlight;
    if (pendingRead != null) {
      await pendingRead;
      // Let the in-flight read release its lock before reconciliation.
      await Future<void>.value();
    }
    if (!isClosed && session == _session) await refresh();
  }

  void reset() {
    stopPolling();
    _pollingOwners.clear();
    _session++;
    _revision++;
    _inFlight = null;
    emit(const DispatchState());
  }

  @override
  Future<void> close() {
    stopPolling();
    _session++;
    _pollingOwners.clear();
    return super.close();
  }
}
