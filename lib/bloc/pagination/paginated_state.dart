import 'package:equatable/equatable.dart';

class PaginatedState<T> extends Equatable {
  final List<T> items;
  final bool isInitialLoading;
  final bool isRefreshing;
  final bool isPaginating;
  final bool hasMore;
  final String? error;
  final int currentPage;
  final int? total;

  // ── New optional fields for UX feedback ────────────────
  final bool? operationSuccess;           // true = success, false = failed
  final String? operationMessage;         // "Product deleted successfully"
  final String? lastOperationType;        // "delete", "add", "update" (optional)

  const PaginatedState({
    this.items = const [],
    this.isInitialLoading = false,
    this.isRefreshing = false,
    this.isPaginating = false,
    this.hasMore = true,
    this.error,
    this.currentPage = 1,
    this.total,
    this.operationSuccess,
    this.operationMessage,
    this.lastOperationType,
  });

  factory PaginatedState.initial() => const PaginatedState();

  PaginatedState<T> copyWith({
    List<T>? items,
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
    bool clearOperation = false,   // helper to reset success flags
  }) {
    return PaginatedState<T>(
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
    );
  }

  @override
  List<Object?> get props => [
    items, isInitialLoading, isRefreshing, isPaginating, hasMore,
    error, currentPage, total,
    operationSuccess, operationMessage, lastOperationType,
  ];
}
