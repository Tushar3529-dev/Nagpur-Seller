import 'package:equatable/equatable.dart';
import 'package:hyper_local_seller/screen/order_page/dispatch/model/dispatch_model.dart';

enum DispatchFilter { all, needsAction, awaiting, assigned }

class DispatchState extends Equatable {
  final DispatchDashboard? dashboard;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;
  final DispatchFilter filter;
  final Set<int> pendingSelfDeliver;
  final DateTime? lastUpdated;
  const DispatchState({
    this.dashboard,
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.filter = DispatchFilter.all,
    this.pendingSelfDeliver = const {},
    this.lastUpdated,
  });

  DispatchState copyWith({
    DispatchDashboard? dashboard,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    bool clearError = false,
    DispatchFilter? filter,
    Set<int>? pendingSelfDeliver,
    DateTime? lastUpdated,
  }) => DispatchState(
    dashboard: dashboard ?? this.dashboard,
    isLoading: isLoading ?? this.isLoading,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    error: clearError ? null : error ?? this.error,
    filter: filter ?? this.filter,
    pendingSelfDeliver: pendingSelfDeliver ?? this.pendingSelfDeliver,
    lastUpdated: lastUpdated ?? this.lastUpdated,
  );

  List<DispatchOrder> get visibleOrders {
    final orders = (dashboard?.orders ?? <DispatchOrder>[])
        .where(
          (order) => switch (filter) {
            DispatchFilter.all => true,
            DispatchFilter.needsAction => order.status.needsAction,
            DispatchFilter.awaiting =>
              order.status == DispatchStatus.waitingForDispatch ||
                  order.status == DispatchStatus.awaitingRiderAcceptance,
            DispatchFilter.assigned =>
              order.status == DispatchStatus.riderAssigned ||
                  order.status == DispatchStatus.sellerSelfDelivery,
          },
        )
        .toList();
    const priority = [
      DispatchStatus.noNearbyRiders,
      DispatchStatus.awaitingRiderAcceptance,
      DispatchStatus.waitingForDispatch,
      DispatchStatus.riderAssigned,
      DispatchStatus.sellerSelfDelivery,
      DispatchStatus.unknown,
    ];
    orders.sort((a, b) {
      final group = priority
          .indexOf(a.status)
          .compareTo(priority.indexOf(b.status));
      if (group != 0) return group;
      if (a.createdAt == null) {
        return b.createdAt == null ? a.orderId.compareTo(b.orderId) : 1;
      }
      if (b.createdAt == null) return -1;
      final age = a.createdAt!.compareTo(b.createdAt!);
      return age == 0 ? a.orderId.compareTo(b.orderId) : age;
    });
    return orders;
  }

  @override
  List<Object?> get props => [
    dashboard,
    isLoading,
    isRefreshing,
    error,
    filter,
    pendingSelfDeliver,
    lastUpdated,
  ];
}

class SelfDeliverResult {
  final bool isSuccess;
  final bool isIgnored;
  final String message;
  final int? statusCode;
  const SelfDeliverResult.success(this.message)
    : isSuccess = true,
      isIgnored = false,
      statusCode = null;
  const SelfDeliverResult.failure(this.message, {this.statusCode})
    : isSuccess = false,
      isIgnored = false;
  const SelfDeliverResult.ignored()
    : isSuccess = false,
      isIgnored = true,
      message = '',
      statusCode = null;
}
