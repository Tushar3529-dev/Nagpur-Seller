part of 'orders_bloc.dart';

class OrdersState extends PaginatedState<SellerOrderItem> {
  final String? paymentType;
  final String? range;
  final String? sortBy;
  final String? sortDir;
  final String? status;
  final int? storeId;

  const OrdersState({
    super.items,
    super.hasMore,
    super.isInitialLoading,
    super.isPaginating, // Replaced isLoadingMore with isPaginating
    super.isRefreshing,
    super.error,
    super.currentPage,
    super.total,
    this.paymentType,
    this.range,
    this.sortBy,
    this.sortDir,
    this.status,
    this.storeId,
  });

  @override
  OrdersState copyWith({
    List<SellerOrderItem>? items,
    bool? hasMore,
    bool? isInitialLoading,
    bool? isPaginating, // Replaced isLoadingMore
    bool? isRefreshing,
    String? error,
    int? currentPage,
    int? total,
    bool? operationSuccess,
    String? operationMessage,
    String? lastOperationType,
    bool clearOperation = false,
    String? paymentType,
    String? range,
    String? sortBy,
    String? sortDir,
    String? status,
    bool overrideFilters = false,
    int? storeId,
  }) {
    return OrdersState(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isPaginating: isPaginating ?? this.isPaginating,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: clearOperation ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
      total: total ?? this.total,
      paymentType: overrideFilters ? paymentType : (paymentType ?? this.paymentType),
      range: overrideFilters ? range : (range ?? this.range),
      sortBy: overrideFilters ? sortBy : (sortBy ?? this.sortBy),
      sortDir: overrideFilters ? sortDir : (sortDir ?? this.sortDir),
      status: overrideFilters ? status : (status ?? this.status),
      storeId: overrideFilters ? storeId : (storeId ?? this.storeId),
    );
  }

  @override
  List<Object?> get props => [
        ...super.props,
        paymentType,
        range,
        sortBy,
        sortDir,
        status,
        storeId,
      ];
}
