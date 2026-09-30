part of 'products_bloc.dart';

/// Client side sorting options for the products list.
class ProductSort {
  static const String stockLowToHigh = 'stock_low_to_high';
  static const String stockHighToLow = 'stock_high_to_low';
  static const String priceLowToHigh = 'price_low_to_high';
  static const String priceHighToLow = 'price_high_to_low';

  /// Lowest stock first, so products running out show up at the top.
  static const String defaultSort = stockLowToHigh;

  static const List<String> values = [
    stockLowToHigh,
    stockHighToLow,
    priceLowToHigh,
    priceHighToLow,
  ];
}

class ProductsState extends PaginatedState<Product> {
  final ProductFilter? filterOptions;
  final String? selectedType;
  final String? selectedStatus;
  final String? selectedVerificationStatus;
  final String? selectedProductFilter;
  final String sortBy;

  const ProductsState({
    super.items,
    super.isInitialLoading,
    super.isRefreshing,
    super.isPaginating,
    super.hasMore,
    super.error,
    super.currentPage,
    super.total,
    super.operationSuccess,
    super.operationMessage,
    super.lastOperationType,
    this.filterOptions,
    this.selectedType,
    this.selectedStatus,
    this.selectedVerificationStatus,
    this.selectedProductFilter,
    this.sortBy = ProductSort.defaultSort,
  });

  /// Effective price shown on the product card (special price when set).
  static int _effectivePrice(Product product) {
    final variant = (product.variants?.isNotEmpty ?? false)
        ? product.variants!.first
        : null;
    if (variant == null) return 0;
    final special = variant.specialPrice;
    if (special != null && special > 0) return special;
    return variant.price ?? 0;
  }

  /// Quantity in stock, summed over every variant of the product.
  static int totalStock(Product product) {
    final variants = product.variants;
    if (variants == null || variants.isEmpty) return 0;
    return variants.fold<int>(0, (sum, variant) => sum + (variant.stock ?? 0));
  }

  /// Orders the whole product list for the given sort option. The API cannot
  /// sort by price or stock, so it is done here over the full result set.
  static List<Product> sortProducts(List<Product> products, String sort) {
    final sorted = List<Product>.from(products);
    sorted.sort((a, b) {
      switch (sort) {
        case ProductSort.stockHighToLow:
          return totalStock(b).compareTo(totalStock(a));
        case ProductSort.priceLowToHigh:
          return _effectivePrice(a).compareTo(_effectivePrice(b));
        case ProductSort.priceHighToLow:
          return _effectivePrice(b).compareTo(_effectivePrice(a));
        case ProductSort.stockLowToHigh:
        default:
          return totalStock(a).compareTo(totalStock(b));
      }
    });
    return sorted;
  }

  @override
  ProductsState copyWith({
    List<Product>? items,
    bool? isInitialLoading,
    bool? isRefreshing,
    bool? isPaginating,
    bool? hasMore,
    String? error,
    int? currentPage,
    int? total,
    bool? operationSuccess,
    String? operationMessage,
    String? lastOperationType,
    bool clearOperation = false,
    ProductFilter? filterOptions,
    String? selectedType,
    String? selectedStatus,
    String? selectedVerificationStatus,
    String? selectedProductFilter,
    String? sortBy,
    bool overrideFilters = false,
  }) {
    return ProductsState(
      items: items ?? this.items,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isPaginating: isPaginating ?? this.isPaginating,
      hasMore: hasMore ?? this.hasMore,
      error: clearOperation ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
      total: total ?? this.total,
      operationSuccess: clearOperation
          ? null
          : (operationSuccess ?? this.operationSuccess),
      operationMessage: clearOperation
          ? null
          : (operationMessage ?? this.operationMessage),
      lastOperationType: clearOperation
          ? null
          : (lastOperationType ?? this.lastOperationType),
      filterOptions: filterOptions ?? this.filterOptions,
      selectedType: overrideFilters
          ? selectedType
          : (selectedType ?? this.selectedType),
      selectedStatus: overrideFilters
          ? selectedStatus
          : (selectedStatus ?? this.selectedStatus),
      selectedVerificationStatus: overrideFilters
          ? selectedVerificationStatus
          : (selectedVerificationStatus ?? this.selectedVerificationStatus),
      selectedProductFilter: overrideFilters
          ? selectedProductFilter
          : (selectedProductFilter ?? this.selectedProductFilter),
      sortBy: sortBy ?? this.sortBy,
    );
  }

  @override
  List<Object?> get props => [
    ...super.props,
    filterOptions,
    selectedType,
    selectedStatus,
    selectedVerificationStatus,
    selectedProductFilter,
    sortBy,
  ];
}
