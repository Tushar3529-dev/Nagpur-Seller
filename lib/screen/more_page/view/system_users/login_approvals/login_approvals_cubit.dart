import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/app_permissions.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/model/login_approval_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/repo/system_users_repo.dart';
import 'package:hyper_local_seller/utils/permission_checker.dart';

enum LoginApprovalsStatus { initial, loading, success, failure }

class LoginApprovalsState {
  final LoginApprovalsStatus status;
  final List<LoginApprovalRequest> items;
  final int total;
  final int currentPage;
  final bool hasReachedMax;
  final bool isLoadingMore;

  /// System users whose approve/disapprove call is in flight.
  final Set<int> processingIds;
  final String? errorMessage;
  final String? actionMessage;

  const LoginApprovalsState({
    this.status = LoginApprovalsStatus.initial,
    this.items = const [],
    this.total = 0,
    this.currentPage = 1,
    this.hasReachedMax = false,
    this.isLoadingMore = false,
    this.processingIds = const {},
    this.errorMessage,
    this.actionMessage,
  });

  LoginApprovalsState copyWith({
    LoginApprovalsStatus? status,
    List<LoginApprovalRequest>? items,
    int? total,
    int? currentPage,
    bool? hasReachedMax,
    bool? isLoadingMore,
    Set<int>? processingIds,
    String? errorMessage,
    String? actionMessage,
    bool clearMessages = false,
  }) {
    return LoginApprovalsState(
      status: status ?? this.status,
      items: items ?? this.items,
      total: total ?? this.total,
      currentPage: currentPage ?? this.currentPage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      processingIds: processingIds ?? this.processingIds,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      actionMessage: clearMessages
          ? null
          : (actionMessage ?? this.actionMessage),
    );
  }
}

/// Seller-admin side of system-user login approval: lists pending requests
/// and approves (24h access) or disapproves them.
class LoginApprovalsCubit extends Cubit<LoginApprovalsState> {
  final SystemUsersRepo _repo;

  LoginApprovalsCubit({required SystemUsersRepo repo})
    : _repo = repo,
      super(const LoginApprovalsState());

  static bool get canView =>
      PermissionChecker.hasPermission(AppPermissions.systemUserView);

  static bool get canManage =>
      PermissionChecker.hasPermission(AppPermissions.systemUserEdit);

  Future<void> fetch() async {
    if (!canView) return;
    emit(
      state.copyWith(status: LoginApprovalsStatus.loading, clearMessages: true),
    );
    try {
      final page = await _repo.getPendingLoginApprovals(page: 1);
      emit(
        state.copyWith(
          status: LoginApprovalsStatus.success,
          items: page.items,
          total: page.total,
          currentPage: 1,
          hasReachedMax: page.currentPage >= page.lastPage,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LoginApprovalsStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.hasReachedMax ||
        state.isLoadingMore ||
        state.status != LoginApprovalsStatus.success) {
      return;
    }
    emit(state.copyWith(isLoadingMore: true));
    try {
      final nextPage = state.currentPage + 1;
      final page = await _repo.getPendingLoginApprovals(page: nextPage);
      final seen = state.items.map((e) => e.userId).toSet();
      emit(
        state.copyWith(
          items: [
            ...state.items,
            ...page.items.where((e) => !seen.contains(e.userId)),
          ],
          total: page.total,
          currentPage: nextPage,
          hasReachedMax: page.currentPage >= page.lastPage,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      emit(state.copyWith(isLoadingMore: false, hasReachedMax: true));
    }
  }

  Future<void> approve(int userId) => _decide(
    userId,
    () => _repo.approveLogin(userId),
    'Login approved for 24 hours',
  );

  Future<void> disapprove(int userId) =>
      _decide(userId, () => _repo.disapproveLogin(userId), 'Login disapproved');

  Future<void> _decide(
    int userId,
    Future<dynamic> Function() call,
    String successMessage,
  ) async {
    if (state.processingIds.contains(userId)) return;
    emit(
      state.copyWith(
        processingIds: {...state.processingIds, userId},
        clearMessages: true,
      ),
    );
    try {
      await call();
      // The request is no longer pending either way, so drop it locally.
      final remaining = state.items.where((e) => e.userId != userId).toList();
      emit(
        state.copyWith(
          items: remaining,
          total: (state.total - 1).clamp(0, 1 << 30),
          processingIds: {...state.processingIds}..remove(userId),
          actionMessage: successMessage,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          processingIds: {...state.processingIds}..remove(userId),
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void clearMessages() => emit(state.copyWith(clearMessages: true));

  void reset() => emit(const LoginApprovalsState());
}
