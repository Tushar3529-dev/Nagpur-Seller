import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/categories/model/categories_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/categories/repo/categories_repo.dart';
import 'package:hyper_local_seller/screen/products_page/products/model/product_category_tree.dart';

enum ProductCategoryStatus { initial, loading, loaded, failed }

class ProductCategoryState {
  final ProductCategoryStatus status;
  final CategoryCatalog catalog;

  const ProductCategoryState({
    this.status = ProductCategoryStatus.initial,
    this.catalog = const CategoryCatalog.empty(),
  });
}

/// Loads the category tree used to group the products list into
/// category tabs and subcategory chips.
class ProductCategoryCubit extends Cubit<ProductCategoryState> {
  final CategoriesRepo _repo;

  ProductCategoryCubit(this._repo) : super(const ProductCategoryState());

  Future<void> load() async {
    if (state.status == ProductCategoryStatus.loading ||
        state.status == ProductCategoryStatus.loaded) {
      return;
    }
    emit(
      ProductCategoryState(
        status: ProductCategoryStatus.loading,
        catalog: state.catalog,
      ),
    );

    try {
      final catalog = await fetchCategoryCatalog(_repo);
      if (isClosed) return;
      emit(
        ProductCategoryState(
          status: ProductCategoryStatus.loaded,
          catalog: catalog,
        ),
      );
    } catch (e) {
      debugPrint('Load product categories error: $e');
      if (isClosed) return;
      emit(
        ProductCategoryState(
          status: ProductCategoryStatus.failed,
          catalog: state.catalog,
        ),
      );
    }
  }
}

const int _categoryPageSize = 100;

/// Levels below the top level to load; the tabs only use the first one,
/// deeper levels let products in sub-subcategories roll up correctly.
const int _maxCategoryDepth = 3;

/// Loads every category, level by level, into one catalog.
Future<CategoryCatalog> fetchCategoryCatalog(CategoriesRepo repo) async {
  final all = <Category>[];
  var level = await _fetchAllCategories(repo, null);
  for (var depth = 0; level.isNotEmpty; depth++) {
    all.addAll(level);
    if (depth == _maxCategoryDepth) break;
    final parents = level.where((c) => c.subcategoryCount > 0);
    final children = await Future.wait(
      parents.map((c) => _fetchAllCategories(repo, c.slug)),
    );
    level = children.expand((c) => c).toList();
  }
  return CategoryCatalog(all);
}

/// Every page of the children of [parentSlug], or the top level when null.
Future<List<Category>> _fetchAllCategories(
  CategoriesRepo repo,
  String? parentSlug,
) async {
  final result = <Category>[];
  var page = 1;
  while (true) {
    final response = await repo.getCategories(
      page: page,
      perPage: _categoryPageSize,
      slug: parentSlug,
    );
    final data = CategoryResponse.fromJson(response).data;
    final items = data?.category ?? [];
    result.addAll(items);
    if (items.isEmpty || page >= (data?.lastPage ?? page)) return result;
    page++;
  }
}
