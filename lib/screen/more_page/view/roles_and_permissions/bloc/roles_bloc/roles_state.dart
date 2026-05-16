part of 'roles_bloc.dart';

class RolesState extends PaginatedState<Role> {
  const RolesState({
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
  });

  @override
  RolesState copyWith({
    List<Role>? items,
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
  }) {
    return RolesState(
      items: items ?? this.items,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isPaginating: isPaginating ?? this.isPaginating,
      hasMore: hasMore ?? this.hasMore,
      error: clearOperation ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
      total: total ?? this.total,
      operationSuccess:
          clearOperation ? null : (operationSuccess ?? this.operationSuccess),
      operationMessage:
          clearOperation ? null : (operationMessage ?? this.operationMessage),
      lastOperationType:
          clearOperation ? null : (lastOperationType ?? this.lastOperationType),
    );
  }

  @override
  List<Object?> get props => [...super.props];
}
