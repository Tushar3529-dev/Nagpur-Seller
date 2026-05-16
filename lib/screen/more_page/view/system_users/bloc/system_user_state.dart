part of 'system_user_bloc.dart';

enum SystemUserStatus { initial, loading, success, failure, loadingMore }

class SystemUserState {
  final SystemUserStatus status;
  final List<SystemUser> users;
  final bool hasReachedMax;
  final String? errorMessage;
  final int currentPage;
  final int total;
  final String? search;
  final bool isActionLoading;
  final String? actionMessage;

  SystemUserState({
    this.status = SystemUserStatus.initial,
    this.users = const [],
    this.hasReachedMax = false,
    this.errorMessage,
    this.currentPage = 1,
    this.total = 0,
    this.search,
    this.isActionLoading = false,
    this.actionMessage,
  });

  SystemUserState copyWith({
    SystemUserStatus? status,
    List<SystemUser>? users,
    bool? hasReachedMax,
    String? errorMessage,
    int? currentPage,
    int? total,
    String? search,
    bool? isActionLoading,
    String? actionMessage,
    bool clearMessages = false,
  }) {
    return SystemUserState(
      status: status ?? this.status,
      users: users ?? this.users,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      currentPage: currentPage ?? this.currentPage,
      total: total ?? this.total,
      search: search ?? this.search,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      actionMessage: clearMessages ? null : (actionMessage ?? this.actionMessage),
    );
  }
}
