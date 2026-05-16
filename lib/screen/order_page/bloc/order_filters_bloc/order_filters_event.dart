part of 'order_filters_bloc.dart';

abstract class OrderFiltersEvent extends Equatable {
  const OrderFiltersEvent();

  @override
  List<Object?> get props => [];
}

class FetchOrderFilters extends OrderFiltersEvent {}

class SelectStatusFilter extends OrderFiltersEvent {
  final String? status;

  const SelectStatusFilter(this.status);

  @override
  List<Object?> get props => [status];
}

class SelectRangeFilter extends OrderFiltersEvent {
  final String? range;

  const SelectRangeFilter(this.range);

  @override
  List<Object?> get props => [range];
}

class SelectPaymentTypeFilter extends OrderFiltersEvent {
  final String? paymentType;

  const SelectPaymentTypeFilter(this.paymentType);

  @override
  List<Object?> get props => [paymentType];
}

class ClearOrderFilters extends OrderFiltersEvent {}

class ResetOrderFilters extends OrderFiltersEvent {}
