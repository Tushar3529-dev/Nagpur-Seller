part of 'incoming_orders_cubit.dart';

class IncomingOrdersState extends Equatable {
  final List<PendingOrder> orders;
  final int? acceptingOrderId;
  final int? failedOrderId;
  final String? errorMessage;

  const IncomingOrdersState({
    this.orders = const [],
    this.acceptingOrderId,
    this.failedOrderId,
    this.errorMessage,
  });

  bool get hasPending => orders.isNotEmpty;

  IncomingOrdersState copyWith({
    List<PendingOrder>? orders,
    int? acceptingOrderId,
    int? failedOrderId,
    String? errorMessage,
    bool clearAccepting = false,
    bool clearError = false,
  }) {
    return IncomingOrdersState(
      orders: orders ?? this.orders,
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
    acceptingOrderId,
    failedOrderId,
    errorMessage,
  ];
}
