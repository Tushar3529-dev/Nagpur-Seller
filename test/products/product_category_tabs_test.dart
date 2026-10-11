import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/screen/more_page/view/categories/model/categories_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/categories/repo/categories_repo.dart';
import 'package:hyper_local_seller/screen/products_page/products/bloc/product_category_cubit/product_category_cubit.dart';
import 'package:hyper_local_seller/screen/products_page/products/model/product_category_tree.dart';
import 'package:hyper_local_seller/screen/products_page/products/model/product_model.dart';
import 'package:hyper_local_seller/screen/products_page/products/widgets/product_category_tabs.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';

Map<String, dynamic> _categoryJson(
  int id,
  String title, {
  int parentId = 0,
  int subcategoryCount = 0,
}) => {
  'id': id,
  'title': title,
  'slug': title.toLowerCase().replaceAll(' ', '-'),
  'parent_id': parentId,
  'subcategory_count': subcategoryCount,
};

Category _category(
  int id,
  String title, {
  int parentId = 0,
  int subcategoryCount = 0,
}) => Category.fromJson(
  _categoryJson(
    id,
    title,
    parentId: parentId,
    subcategoryCount: subcategoryCount,
  ),
);

Product _product(int id, int? categoryId, {CategoryHierarchyNode? hierarchy}) =>
    Product(
      id: id,
      title: 'Product $id',
      slug: 'product-$id',
      mainImage: '',
      categoryId: categoryId,
      categoryHierarchyKey: hierarchy,
    );

// Beauty(4) > Skincare(20); Fresh(1) > Vegetables(9), Fruits(8);
// Vegetables > Leafy(30) is a third level.
final _catalog = CategoryCatalog([
  _category(4, 'Beauty', subcategoryCount: 1),
  _category(1, 'Fresh', subcategoryCount: 2),
  _category(20, 'Skincare', parentId: 4),
  _category(9, 'Vegetables', parentId: 1, subcategoryCount: 1),
  _category(8, 'Fruits', parentId: 1),
  _category(30, 'Leafy', parentId: 9),
]);

class _Repo extends CategoriesRepo {
  final requested = <String?>[];
  bool fail = false;

  @override
  Future<dynamic> getCategories({
    int? page,
    int? perPage,
    String? slug,
    String? search,
  }) async {
    requested.add(slug);
    if (fail) throw Exception('offline');
    final children = switch (slug) {
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
      'data': {'current_page': 1, 'last_page': 1, 'data': children},
    };
  }
}

void main() {
  group('ProductCategoryTree.build', () {
    test('groups by category and subcategory with counts', () {
      final groups = ProductCategoryTree.build(
        [
          _product(1, 9),
          _product(2, 8),
          _product(3, 9),
          _product(4, 20),
          _product(5, 30),
        ],
        _catalog,
        otherTitle: 'Other',
      );

      expect(groups.map((g) => g.title), ['Beauty', 'Fresh']);
      final fresh = groups[1];
      expect(fresh.products.map((p) => p.id), [1, 2, 3, 5]);
      expect(fresh.subcategories.map((s) => s.title), ['Vegetables', 'Fruits']);
      // The Leafy product rolls up into Vegetables.
      expect(fresh.subcategories[0].products.map((p) => p.id), [1, 3, 5]);
      expect(fresh.subcategories[1].products.map((p) => p.id), [2]);
    });

    test('product on a top level category only counts in its category', () {
      final groups = ProductCategoryTree.build(
        [_product(1, 1), _product(2, 9)],
        _catalog,
        otherTitle: 'Other',
      );

      expect(groups.single.products.length, 2);
      expect(groups.single.subcategories.single.products.single.id, 2);
    });

    test('uses the hierarchy key when the category id is unknown', () {
      final groups = ProductCategoryTree.build(
        [
          _product(
            1,
            999,
            hierarchy: CategoryHierarchyNode(
              id: 1,
              child: CategoryHierarchyNode(id: 8),
            ),
          ),
        ],
        _catalog,
        otherTitle: 'Other',
      );

      expect(groups.single.title, 'Fresh');
      expect(groups.single.subcategories.single.title, 'Fruits');
    });

    test('puts uncategorised products last under Other', () {
      final groups = ProductCategoryTree.build(
        [_product(1, null), _product(2, 20)],
        _catalog,
        otherTitle: 'Other',
      );

      expect(groups.map((g) => g.title), ['Beauty', 'Other']);
      expect(groups.last.id, ProductCategoryTree.otherCategoryId);
      expect(groups.last.subcategories, isEmpty);
    });
  });

  group('ProductCategoryCubit', () {
    test('loads top level categories and their children', () async {
      final repo = _Repo();
      final cubit = ProductCategoryCubit(repo);

      await cubit.load();

      expect(cubit.state.status, ProductCategoryStatus.loaded);
      expect(repo.requested, [null, 'fresh']);
      expect(cubit.state.catalog[8]?.title, 'Fruits');
      expect(cubit.state.catalog[2]?.title, 'Kirana');

      await cubit.load();
      expect(repo.requested.length, 2, reason: 'loaded once per page');
      await cubit.close();
    });

    test('a failed load can be retried', () async {
      final repo = _Repo()..fail = true;
      final cubit = ProductCategoryCubit(repo);

      await cubit.load();
      expect(cubit.state.status, ProductCategoryStatus.failed);

      repo.fail = false;
      await cubit.load();
      expect(cubit.state.status, ProductCategoryStatus.loaded);
      await cubit.close();
    });
  });

  group('ProductCategoryTabs', () {
    final groups = ProductCategoryTree.build(
      [_product(1, 9), _product(2, 8), _product(3, 9), _product(4, 20)],
      _catalog,
      otherTitle: 'Other',
    );

    Future<({List<int> categories, List<int?> subcategories})> pump(
      WidgetTester tester, {
      int selectedCategoryId = 1,
      int? selectedSubcategoryId,
    }) async {
      final categories = <int>[];
      final subcategories = <int?>[];
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ProductCategoryTabs(
              categories: groups,
              screenType: ScreenType.mobile,
              selectedCategoryId: selectedCategoryId,
              selectedSubcategoryId: selectedSubcategoryId,
              onCategorySelected: categories.add,
              onSubcategorySelected: subcategories.add,
            ),
          ),
        ),
      );
      return (categories: categories, subcategories: subcategories);
    }

    testWidgets(
      'shows subcategory counts on tabs and product counts on chips',
      (tester) async {
        await pump(tester);

        expect(find.text('Beauty'), findsOneWidget);
        expect(find.text('Fresh'), findsOneWidget);
        expect(find.text('1 subcategory'), findsOneWidget);
        expect(find.text('2 subcategories'), findsOneWidget);
        expect(find.text('All'), findsOneWidget);
        expect(find.text('Vegetables'), findsOneWidget);
        expect(find.text('Fruits'), findsOneWidget);
        // Chip badges: All 3, Vegetables 2, Fruits 1.
        expect(find.text('3'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        expect(find.text('1'), findsOneWidget);
        // Beauty's subcategory is not shown while Fresh is selected.
        expect(find.text('Skincare'), findsNothing);
      },
    );

    testWidgets('reports taps on tabs and chips', (tester) async {
      final taps = await pump(tester);

      await tester.tap(find.text('Beauty'));
      await tester.tap(find.text('Fruits'));
      await tester.tap(find.text('All'));

      expect(taps.categories, [4]);
      expect(taps.subcategories, [8, null]);
    });
  });
}
