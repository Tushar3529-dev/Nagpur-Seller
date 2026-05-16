part of 'product_faq_bloc.dart';

class ProductFaqState extends PaginatedState<ProductFaq> {
  final int? productId;
  final String? search;

  const ProductFaqState({
    super.items,
    super.hasMore,
    super.isInitialLoading,
    super.isPaginating,
    super.isRefreshing,
    super.error,
    super.currentPage,
    super.total,
    super.operationSuccess,
    super.operationMessage,
    super.lastOperationType,
    this.productId,
    this.search,
  });

  @override
  ProductFaqState copyWith({
    List<ProductFaq>? items,
    bool? hasMore,
    bool? isInitialLoading,
    bool? isPaginating,
    bool? isRefreshing,
    String? error,
    int? currentPage,
    int? total,
    bool? operationSuccess,
    String? operationMessage,
    String? lastOperationType,
    bool clearOperation = false,
    int? productId,
    String? search,
    bool overrideFilters = false,
  }) {
    return ProductFaqState(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isPaginating: isPaginating ?? this.isPaginating,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: error ?? this.error,
      currentPage: currentPage ?? this.currentPage,
      total: total ?? this.total,
      operationSuccess: clearOperation ? null : (operationSuccess ?? this.operationSuccess),
      operationMessage: clearOperation ? null : (operationMessage ?? this.operationMessage),
      lastOperationType: clearOperation ? null : (lastOperationType ?? this.lastOperationType),
      productId: overrideFilters ? productId : (productId ?? this.productId),
      search: overrideFilters ? search : (search ?? this.search),
    );
  }

  @override
  List<Object?> get props => [
        ...super.props,
        productId,
        search,
      ];
}
