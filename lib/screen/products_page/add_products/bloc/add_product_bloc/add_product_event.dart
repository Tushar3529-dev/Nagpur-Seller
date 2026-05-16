part of 'add_product_bloc.dart';

@immutable
sealed class AddProductEvent {}

class UpdateProductData extends AddProductEvent {
  final ProductData productData;
  UpdateProductData(this.productData);
}

class SubmitProduct extends AddProductEvent {}

class AddProductReset extends AddProductEvent {}

/// Load product data from API by ID for editing
class LoadProductForEdit extends AddProductEvent {
  final int productId;
  LoadProductForEdit(this.productId);
}

/// Internal event - sets product data after API fetch
class SetProductForEdit extends AddProductEvent {
  final Product product;
  SetProductForEdit(this.product);
}
