part of 'products_bloc.dart';

abstract class ProductsEvent {}

class LoadProductsInitial extends ProductsEvent {
  final String? search;
  LoadProductsInitial({this.search});
}

class LoadMoreProducts extends ProductsEvent {}

class RefreshProducts extends ProductsEvent {}

class SearchProducts extends ProductsEvent {
  final String query;
  SearchProducts(this.query);
}

class DeleteProduct extends ProductsEvent {
  final int productId;
  DeleteProduct(this.productId);
}

class UpdateProductStatus extends ProductsEvent {
  final int productId;
  final String status;
  UpdateProductStatus({required this.productId, required this.status});
}

class LoadProductFilters extends ProductsEvent {}

class ApplyProductFilter extends ProductsEvent {
  final String? type;
  final String? status;
  final String? verificationStatus;
  final String? productFilter;

  ApplyProductFilter({
    this.type,
    this.status,
    this.verificationStatus,
    this.productFilter,
  });
}

class ProductFilterApplied extends ProductsEvent {
  final String? type;
  final String? status;
  final String? verificationStatus;
  final String? productFilter;

  ProductFilterApplied({
    this.type,
    this.status,
    this.verificationStatus,
    this.productFilter,
  });
}

class ClearProducts extends ProductsEvent {}

