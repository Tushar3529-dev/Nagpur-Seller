import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/screen/more_page/view/categories/model/categories_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/categories/repo/categories_repo.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/bloc/category_product_counts/category_product_counts_cubit.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/bloc/selected_categories/category_expansion_cubit.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/bloc/selected_categories/selected_categories_cubit.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/widgets/steps/category_node_widget.dart';
import 'package:hyper_local_seller/screen/products_page/products/model/product_category_tree.dart';
import 'package:hyper_local_seller/screen/products_page/products/model/product_model.dart';
import 'package:hyper_local_seller/screen/products_page/products/repo/products_repo.dart';

Map<String, dynamic> _categoryJson(
  int id,
  String title, {
  int parentId = 0,
  int subcategoryCount = 0,
}) => {
  'id': id,
  'title': title,
  'slug': title.toLowerCase(),
  'parent_id': parentId,
  'subcategory_count': subcategoryCount,
};

Map<String, dynamic> _productJson(int id, int categoryId) => {
  'id': id,
  'title': 'Product $id',
  'slug': 'product-$id',
  'category_id': categoryId,
};

class _CategoriesRepo extends CategoriesRepo {
  @override
  Future<dynamic> getCategories({
    int? page,
    int? perPage,
    String? slug,
    String? search,
  }) async {
    final items = switch (slug) {
      null => [
        _categoryJson(1, 'Fresh', subcategoryCount: 2),
        _categoryJson(2, 'Kirana'),
      ],
      'fresh' => [
        _categoryJson(9, 'Vegetables', parentId: 1),
        _categoryJson(8, 'Fruits', parentId: 1),
      ],
      _ => <Map<String, dynamic>>[],
    };
    return {
      'success': true,
      'data': {'current_page': 1, 'last_page': 1, 'data': items},
    };
  }
}

class _ProductsRepo extends ProductsRepo {
  final pages = <int>[];
  bool fail = false;

  @override
  Future<dynamic> getProducts({
    int? page,
    int? perPage,
    String? search,
    String? type,
    String? status,
    String? verificationStatus,
    String? productFilter,
  }) async {
    pages.add(page!);
    if (fail) throw Exception('offline');
    final items = page == 1
        ? [_productJson(1, 9), _productJson(2, 9)]
        : [_productJson(3, 8), _productJson(4, 1)];
    return {
      'success': true,
      'data': {'current_page': page, 'last_page': 2, 'data': items},
    };
  }
}

void main() {
  test('counts a product in its category and every category above it', () {
    final catalog = CategoryCatalog([
      Category.fromJson(_categoryJson(1, 'Fresh', subcategoryCount: 1)),
      Category.fromJson(_categoryJson(9, 'Vegetables', parentId: 1)),
      Category.fromJson(_categoryJson(30, 'Leafy', parentId: 9)),
    ]);
    Product product(int id, int categoryId) => Product(
      id: id,
      title: 'Product $id',
      slug: 'product-$id',
      mainImage: '',
      categoryId: categoryId,
    );

    final counts = ProductCategoryTree.productCountByCategory([
      product(1, 9),
      product(2, 30),
      product(3, 1),
    ], catalog);

    expect(counts, {1: 3, 9: 2, 30: 1});
  });

  group('CategoryProductCountsCubit', () {
    test('counts every page of the seller products', () async {
      final products = _ProductsRepo();
      final cubit = CategoryProductCountsCubit(_CategoriesRepo(), products);

      await cubit.load();

      expect(products.pages, [1, 2]);
      expect(cubit.state, {1: 4, 9: 2, 8: 1});
      await cubit.close();
    });

    test('shows no counts when loading fails', () async {
      final cubit = CategoryProductCountsCubit(
        _CategoriesRepo(),
        _ProductsRepo()..fail = true,
      );

      await cubit.load();

      expect(cubit.state, isNull);
      await cubit.close();
    });
  });

  group('CategoryNodeWidget', () {
    Future<void> pump(
      WidgetTester tester,
      Category category,
      Map<int, int>? counts,
    ) async {
      final countsCubit = _FixedCounts(counts);
      addTearDown(countsCubit.close);
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => SelectedCategoriesCubit()),
            BlocProvider(create: (_) => CategoryExpansionCubit()),
            BlocProvider<CategoryProductCountsCubit>.value(value: countsCubit),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: CategoryNodeWidget(category: category, level: 0),
            ),
          ),
        ),
      );
    }

    testWidgets('category shows subcategory and product counts', (
      tester,
    ) async {
      await pump(
        tester,
        Category.fromJson(_categoryJson(1, 'Fresh', subcategoryCount: 8)),
        {1: 46},
      );

      expect(find.text('Fresh'), findsOneWidget);
      expect(find.text('8 subcategories'), findsOneWidget);
      expect(find.text('46 products'), findsOneWidget);
    });

    testWidgets('subcategory without products shows 0 and no sub line', (
      tester,
    ) async {
      await pump(
        tester,
        Category.fromJson(_categoryJson(14, 'Breakfast', parentId: 1)),
        {1: 46},
      );

      expect(find.text('0 products'), findsOneWidget);
      expect(find.textContaining('subcategor'), findsNothing);
    });

    testWidgets('no pill while counts are loading', (tester) async {
      await pump(
        tester,
        Category.fromJson(_categoryJson(9, 'Vegetables', parentId: 1)),
        null,
      );

      expect(find.textContaining('product'), findsNothing);
    });
  });
}

class _FixedCounts extends CategoryProductCountsCubit {
  _FixedCounts(Map<int, int>? counts)
    : super(_CategoriesRepo(), _ProductsRepo()) {
    if (counts != null) emit(counts);
  }
}
