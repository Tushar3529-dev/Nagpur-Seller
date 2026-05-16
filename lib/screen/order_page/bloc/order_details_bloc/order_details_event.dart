part of 'order_details_bloc.dart';

abstract class OrderDetailsEvent extends Equatable {
  const OrderDetailsEvent();

  @override
  List<Object> get props => [];
}

class FetchOrderDetails extends OrderDetailsEvent {
  final int orderId; // seller_order_id
  const FetchOrderDetails(this.orderId);

  @override
  List<Object> get props => [orderId];
}

class UpdateOrderStatusEvent extends OrderDetailsEvent {
  final int orderId;
  final String status;
  const UpdateOrderStatusEvent({required this.orderId, required this.status});

  @override
  List<Object> get props => [orderId, status];
}
