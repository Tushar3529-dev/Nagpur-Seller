part of 'orders_bloc.dart';

abstract class OrdersEvent {}

class LoadOrdersInitial extends OrdersEvent {
  final String? search;
  final int? storeId;
  LoadOrdersInitial({this.search, this.storeId});
}

class LoadMoreOrders extends OrdersEvent {}

class RefreshOrders extends OrdersEvent {
  final int? storeId;
  RefreshOrders({this.storeId});
}

class SearchOrders extends OrdersEvent {
  final String query;
  SearchOrders(this.query);
}

class ApplyFilter extends OrdersEvent {
  final String? paymentType;
  final String? range;
  final String? sortBy;
  final String? sortDir;
  final String? status;

  ApplyFilter({
    this.paymentType,
    this.range,
    this.sortBy,
    this.sortDir,
    this.status,
  });
}

class ClearFilters extends OrdersEvent {}

class OrdersReset extends OrdersEvent {}

class UpdateOrderListItemStatus extends OrdersEvent {
  final int orderId;
  final String status;
  UpdateOrderListItemStatus({required this.orderId, required this.status});
}
