part of 'notification_list_bloc.dart';

class NotificationListState extends PaginatedState<NotificationItem> {
  final int unreadCount;

  const NotificationListState({
    super.items = const [],
    super.isInitialLoading = false,
    super.isRefreshing = false,
    super.isPaginating = false,
    super.hasMore = true,
    super.error,
    super.currentPage = 1,
    super.total,
    this.unreadCount = 0,
  });

  @override
  NotificationListState copyWith({
    List<NotificationItem>? items,
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
    int? unreadCount,
  }) {
    return NotificationListState(
      items: items ?? this.items,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isPaginating: isPaginating ?? this.isPaginating,
      hasMore: hasMore ?? this.hasMore,
      error: clearOperation ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
      total: total ?? this.total,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  List<Object?> get props => [
        ...super.props,
        unreadCount,
      ];
}
