part of 'order_details_bloc.dart';

abstract class OrderDetailsState extends Equatable {
  const OrderDetailsState();
  
  @override
  List<Object?> get props => [];
}

class OrderDetailsInitial extends OrderDetailsState {}

class OrderDetailsLoading extends OrderDetailsState {}

class OrderDetailsLoaded extends OrderDetailsState {
  final OrderDetailsData orderData;
  final bool isUpdating; // To show loader during status update

  const OrderDetailsLoaded({
    required this.orderData,
    this.isUpdating = false,
  });

  OrderDetailsLoaded copyWith({
    OrderDetailsData? orderData,
    bool? isUpdating,
  }) {
    return OrderDetailsLoaded(
      orderData: orderData ?? this.orderData,
      isUpdating: isUpdating ?? this.isUpdating,
    );
  }

  @override
  List<Object?> get props => [orderData, isUpdating];
}

class OrderDetailsError extends OrderDetailsState {
  final String message;

  const OrderDetailsError(this.message);

  @override
  List<Object> get props => [message];
}

class OrderStatusUpdateSuccess extends OrderDetailsState {
  final String message;
  const OrderStatusUpdateSuccess(this.message);
  @override
  List<Object> get props => [message];
}
