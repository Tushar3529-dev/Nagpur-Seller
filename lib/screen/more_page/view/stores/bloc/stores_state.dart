part of 'stores_bloc.dart';


class StoresState extends PaginatedState<Store> {
  final StoreFilter? filterOptions;
  final String? selectedStatus;
  final String? selectedVisibilityStatus;
  final String? selectedVerificationStatus;

  const StoresState({
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
    this.selectedStatus,
    this.selectedVisibilityStatus,
    this.selectedVerificationStatus,
  });

  @override
  StoresState copyWith({
    List<Store>? items,
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
    StoreFilter? filterOptions,
    String? selectedStatus,
    String? selectedVisibilityStatus,
    String? selectedVerificationStatus,
    bool overrideFilters = false,
  }) {
    return StoresState(
      items: items ?? this.items,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isPaginating: isPaginating ?? this.isPaginating,
      hasMore: hasMore ?? this.hasMore,
      error: clearOperation ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
      total: total ?? this.total,
      operationSuccess: clearOperation ? null : (operationSuccess ?? this.operationSuccess),
      operationMessage: clearOperation ? null : (operationMessage ?? this.operationMessage),
      lastOperationType: clearOperation ? null : (lastOperationType ?? this.lastOperationType),
      filterOptions: filterOptions ?? this.filterOptions,
      selectedStatus: overrideFilters ? selectedStatus : (selectedStatus ?? this.selectedStatus),
      selectedVisibilityStatus: overrideFilters ? selectedVisibilityStatus : (selectedVisibilityStatus ?? this.selectedVisibilityStatus),
      selectedVerificationStatus: overrideFilters ? selectedVerificationStatus : (selectedVerificationStatus ?? this.selectedVerificationStatus),
    );
  }

  @override
  List<Object?> get props => [
        ...super.props,
        filterOptions,
        selectedStatus,
        selectedVisibilityStatus,
        selectedVerificationStatus,
      ];
}
