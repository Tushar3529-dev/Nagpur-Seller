import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/categories/repo/categories_repo.dart';
import 'package:hyper_local_seller/screen/products_page/products/bloc/product_category_cubit/product_category_cubit.dart';
import 'package:hyper_local_seller/screen/products_page/products/model/product_category_tree.dart';
import 'package:hyper_local_seller/screen/products_page/products/model/product_model.dart';
import 'package:hyper_local_seller/screen/products_page/products/repo/products_repo.dart';

/// How many of the seller's products sit in each category, shown next to the
/// categories in the add product category picker. Null until loaded, and
/// stays null if loading fails so the picker simply shows no counts.
class CategoryProductCountsCubit extends Cubit<Map<int, int>?> {
  final CategoriesRepo _categoriesRepo;
  final ProductsRepo _productsRepo;

  static const int _pageSize = 100;

  /// Same safety net as the products list.
  static const int _maxProducts = 2000;

  bool _loading = false;

  CategoryProductCountsCubit(this._categoriesRepo, this._productsRepo)
    : super(null);

  Future<void> load() async {
    if (_loading || state != null) return;
    _loading = true;
    try {
      final (catalog, products) = await (
        fetchCategoryCatalog(_categoriesRepo),
        _fetchAllProducts(),
      ).wait;
      if (isClosed) return;
      emit(ProductCategoryTree.productCountByCategory(products, catalog));
    } catch (e) {
      debugPrint('Load category product counts error: $e');
    } finally {
      _loading = false;
    }
  }

  Future<List<Product>> _fetchAllProducts() async {
    final products = <Product>[];
    var page = 1;
    while (true) {
      final response = await _productsRepo.getProducts(
        page: page,
        perPage: _pageSize,
      );
      final data = ProductsResponse.fromJson(response).data;
      final items = data?.products ?? [];
      products.addAll(items);
      if (items.isEmpty ||
          page >= (data?.lastPage ?? page) ||
          products.length >= _maxProducts) {
        return products;
      }
      page++;
    }
  }
}
