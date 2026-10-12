import 'package:hyper_local_seller/screen/more_page/view/categories/model/categories_model.dart';
import 'package:hyper_local_seller/screen/products_page/products/model/product_model.dart';

/// Every marketplace category, keyed by id, in the order the API returned them.
class CategoryCatalog {
  final Map<int, Category> _byId;
  final Map<int, int> _order;

  CategoryCatalog(List<Category> categories)
    : _byId = {for (final c in categories) c.id: c},
      _order = {
        for (var i = 0; i < categories.length; i++) categories[i].id: i,
      };

  const CategoryCatalog.empty() : _byId = const {}, _order = const {};

  bool get isEmpty => _byId.isEmpty;

  Category? operator [](int id) => _byId[id];

  /// Position in API order; unknown ids sort last.
  int orderOf(int id) => _order[id] ?? _order.length;
}

/// A level two category (e.g. Fresh > Vegetables) and the seller's products in it.
class ProductSubcategoryGroup {
  final int id;
  final String title;
  final List<Product> products;

  const ProductSubcategoryGroup({
    required this.id,
    required this.title,
    required this.products,
  });
}

/// A top level category (e.g. Fresh) with every product under it, including
/// the ones that sit in its subcategories.
class ProductCategoryGroup {
  final int id;
  final String title;
  final String icon;
  final List<Product> products;
  final List<ProductSubcategoryGroup> subcategories;

  const ProductCategoryGroup({
    required this.id,
    required this.title,
    required this.icon,
    required this.products,
    required this.subcategories,
  });
}

class ProductCategoryTree {
  /// Bucket for products whose category is not in the catalog.
  static const int otherCategoryId = -1;

  /// Groups [products] by top level category and, inside it, by level two
  /// subcategory. Products deeper than level two roll up to their level two
  /// ancestor; products placed directly on a top level category only show up
  /// in that category's full list. The order of [products] is kept.
  static List<ProductCategoryGroup> build(
    List<Product> products,
    CategoryCatalog catalog, {
    required String otherTitle,
  }) {
    final rootProducts = <int, List<Product>>{};
    final subProducts = <int, Map<int, List<Product>>>{};

    for (final product in products) {
      final lineage = _lineage(product, catalog);
      final rootId = lineage.isEmpty ? otherCategoryId : lineage.first;
      rootProducts.putIfAbsent(rootId, () => []).add(product);
      if (lineage.length > 1) {
        subProducts
            .putIfAbsent(rootId, () => {})
            .putIfAbsent(lineage[1], () => [])
            .add(product);
      }
    }

    final rootIds = rootProducts.keys.toList()
      ..sort((a, b) => _compare(a, b, catalog));

    return [
      for (final rootId in rootIds)
        ProductCategoryGroup(
          id: rootId,
          title: rootId == otherCategoryId
              ? otherTitle
              : _title(rootId, catalog, rootProducts[rootId]!),
          icon: catalog[rootId]?.icon ?? '',
          products: rootProducts[rootId]!,
          subcategories: [
            for (final subId
                in (subProducts[rootId]?.keys.toList() ?? <int>[])
                  ..sort((a, b) => _compare(a, b, catalog)))
              ProductSubcategoryGroup(
                id: subId,
                title: _title(subId, catalog, subProducts[rootId]![subId]!),
                products: subProducts[rootId]![subId]!,
              ),
          ],
        ),
    ];
  }

  /// Number of [products] in each category, counting a product in its own
  /// category and in every category above it.
  static Map<int, int> productCountByCategory(
    List<Product> products,
    CategoryCatalog catalog,
  ) {
    final counts = <int, int>{};
    for (final product in products) {
      for (final id in _lineage(product, catalog)) {
        counts[id] = (counts[id] ?? 0) + 1;
      }
    }
    return counts;
  }

  /// Category ids from the top level down to the product's own category.
  static List<int> _lineage(Product product, CategoryCatalog catalog) {
    final categoryId = product.categoryId;
    if (categoryId != null && catalog[categoryId] != null) {
      final path = <int>[];
      final seen = <int>{};
      int? current = categoryId;
      while (current != null && catalog[current] != null && seen.add(current)) {
        path.insert(0, current);
        current = catalog[current]!.parentId;
      }
      return path;
    }

    // Fall back to the hierarchy the API sends with the product.
    final path = <int>[];
    var node = product.categoryHierarchyKey;
    while (node != null) {
      path.add(node.id);
      node = node.child;
    }
    return path.isNotEmpty && catalog[path.first] != null ? path : const [];
  }

  static int _compare(int a, int b, CategoryCatalog catalog) {
    if (a == otherCategoryId) return b == otherCategoryId ? 0 : 1;
    if (b == otherCategoryId) return -1;
    return catalog.orderOf(a).compareTo(catalog.orderOf(b));
  }

  static String _title(
    int id,
    CategoryCatalog catalog,
    List<Product> products,
  ) {
    final known = catalog[id]?.title;
    if (known != null && known.isNotEmpty) return known;
    for (final p in products) {
      if (p.categoryId == id && (p.categoryName?.isNotEmpty ?? false)) {
        return p.categoryName!;
      }
    }
    return '#$id';
  }
}
