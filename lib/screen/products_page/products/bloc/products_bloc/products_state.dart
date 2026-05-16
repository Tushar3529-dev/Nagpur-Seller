part of 'products_bloc.dart';

class ProductsState extends PaginatedState<Product> {
  final ProductFilter? filterOptions;
  final String? selectedType;
  final String? selectedStatus;
  final String? selectedVerificationStatus;
  final String? selectedProductFilter;

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
  });

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
  ];
}
