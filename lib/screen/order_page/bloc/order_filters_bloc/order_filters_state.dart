part of 'order_filters_bloc.dart';

abstract class OrderFiltersState extends Equatable {
  const OrderFiltersState();
  
  @override
  List<Object?> get props => [];
}

class OrderFiltersInitial extends OrderFiltersState {}

class OrderFiltersLoading extends OrderFiltersState {}

class OrderFiltersLoaded extends OrderFiltersState {
  final OrderEnum filters;
  final String? selectedStatus;
  final String? selectedRange;
  final String? selectedPaymentType;

  const OrderFiltersLoaded({
    required this.filters,
    this.selectedStatus,
    this.selectedRange,
    this.selectedPaymentType,
  });

  OrderFiltersLoaded copyWith({
    OrderEnum? filters,
    String? selectedStatus,
    String? selectedRange,
    String? selectedPaymentType,
  }) {
    return OrderFiltersLoaded(
      filters: filters ?? this.filters,
      selectedStatus: selectedStatus,
      selectedRange: selectedRange,
      selectedPaymentType: selectedPaymentType,
    );
  }

  @override
  List<Object?> get props => [
        filters,
        selectedStatus,
        selectedRange,
        selectedPaymentType,
      ];
}

class OrderFiltersError extends OrderFiltersState {
  final String message;

  const OrderFiltersError(this.message);

  @override
  List<Object> get props => [message];
}
