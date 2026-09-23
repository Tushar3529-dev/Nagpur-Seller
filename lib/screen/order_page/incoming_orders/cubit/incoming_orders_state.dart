part of 'incoming_orders_cubit.dart';

class IncomingOrdersState extends Equatable {
  final List<PendingOrder> orders;

  /// When each queued order (by seller_order_id) first appeared in the popup.
  final Map<int, DateTime> shownAt;
  final int? acceptingOrderId;
  final int? failedOrderId;
  final String? errorMessage;

  const IncomingOrdersState({
    this.orders = const [],
    this.shownAt = const {},
    this.acceptingOrderId,
    this.failedOrderId,
    this.errorMessage,
  });

  bool get hasPending => orders.isNotEmpty;

  /// Start of the waiting timer: order time for regular orders, popup time
  /// for wholesale orders (placed long before their popup window opens).
  DateTime? waitingSince(PendingOrder order) => order.isWholesale
      ? shownAt[order.sellerOrderId]
      : (order.createdAt ?? shownAt[order.sellerOrderId]);

  IncomingOrdersState copyWith({
    List<PendingOrder>? orders,
    Map<int, DateTime>? shownAt,
    int? acceptingOrderId,
    int? failedOrderId,
    String? errorMessage,
    bool clearAccepting = false,
    bool clearError = false,
  }) {
    return IncomingOrdersState(
      orders: orders ?? this.orders,
      shownAt: shownAt ?? this.shownAt,
      acceptingOrderId: clearAccepting
          ? null
          : (acceptingOrderId ?? this.acceptingOrderId),
      failedOrderId: clearError ? null : (failedOrderId ?? this.failedOrderId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    orders,
    shownAt,
    acceptingOrderId,
    failedOrderId,
    errorMessage,
  ];
}
