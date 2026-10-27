import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/model/login_approval_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/model/system_users_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/repo/system_users_repo.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';
import 'package:intl/intl.dart';

part 'system_user_event.dart';
part 'system_user_state.dart';

class SystemUserBloc extends Bloc<SystemUserEvent, SystemUserState> {
  final SystemUsersRepo _repo;

  SystemUserBloc({required SystemUsersRepo repo})
    : _repo = repo,
      super(SystemUserState()) {
    on<FetchSystemUsersEvent>(_onFetchSystemUsers);
    on<LoadMoreSystemUsersEvent>(_onLoadMoreSystemUsers);
    on<ManageSystemUserEvent>(_onManageSystemUser);
    on<DeleteSystemUserEvent>(_onDeleteSystemUser);
    on<ClearSystemUserMessages>(
      (event, emit) => emit(state.copyWith(clearMessages: true)),
    );
    on<ApplyLoginApprovalResultEvent>((event, emit) {
      emit(state.copyWith(users: _patchUsers(event.result)));
    });
    on<ApproveSystemUserLoginEvent>(
      (event, emit) => _decideLogin(
        event.id,
        () => _repo.approveLogin(event.id),
        emit,
      ),
    );
    on<DisapproveSystemUserLoginEvent>(
      (event, emit) =>
          _decideLogin(event.id, () => _repo.disapproveLogin(event.id), emit),
    );
    on<SystemUserReset>((event, emit) => emit(SystemUserState()));
  }

  Future<void> _onFetchSystemUsers(
    FetchSystemUsersEvent event,
    Emitter<SystemUserState> emit,
  ) async {
    try {
      emit(
        state.copyWith(
          status: event.silent ? state.status : SystemUserStatus.loading,
          search: event.search ?? '',
          clearMessages: !event.silent,
        ),
      );

      final response = await _repo.getSystemUsers(
        page: 1,
        search: event.search,
      );

      final systemUsersResponse = SystemUsersResponse.fromJson(response);

      if (systemUsersResponse.success == true) {
        final data = systemUsersResponse.data;
        emit(
          state.copyWith(
            status: SystemUserStatus.success,
            users: data?.users ?? [],
            total: data?.total ?? 0,
            currentPage: 1,
            hasReachedMax: (data?.currentPage ?? 1) >= (data?.lastPage ?? 1),
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: SystemUserStatus.failure,
            errorMessage: systemUsersResponse.message,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: event.silent ? state.status : SystemUserStatus.failure,
          errorMessage: e is ApiException ? e.message : 'Something went wrong',
        ),
      );
    }
  }

  Future<void> _onLoadMoreSystemUsers(
    LoadMoreSystemUsersEvent event,
    Emitter<SystemUserState> emit,
  ) async {
    if (state.hasReachedMax || state.status == SystemUserStatus.loadingMore) {
      return;
    }

    try {
      emit(state.copyWith(status: SystemUserStatus.loadingMore));

      final nextPage = state.currentPage + 1;
      final response = await _repo.getSystemUsers(
        page: nextPage,
        search: state.search,
      );

      final systemUsersResponse = SystemUsersResponse.fromJson(response);

      if (systemUsersResponse.success == true) {
        final data = systemUsersResponse.data;
        final List<SystemUser> updatedUsers = List.from(state.users)
          ..addAll(data?.users ?? []);
        emit(
          state.copyWith(
            status: SystemUserStatus.success,
            users: updatedUsers,
            currentPage: nextPage,
            hasReachedMax: (data?.currentPage ?? 1) >= (data?.lastPage ?? 1),
          ),
        );
      } else {
        emit(
          state.copyWith(
            status:
                SystemUserStatus.success, // Keep existing data but stop loading
            hasReachedMax: true,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status:
              SystemUserStatus.success, // Keep existing data but stop loading
          hasReachedMax: true,
        ),
      );
    }
  }

  Future<void> _onManageSystemUser(
    ManageSystemUserEvent event,
    Emitter<SystemUserState> emit,
  ) async {
    try {
      emit(state.copyWith(isActionLoading: true, clearMessages: true));

      final response = await _repo.manageSystemUser(event.data);

      if (response['success'] == true) {
        emit(
          state.copyWith(
            isActionLoading: false,
            actionMessage:
                response['message'] ?? 'Successfully updated system user',
          ),
        );
        add(FetchSystemUsersEvent(isRefresh: true, search: state.search));
      } else {
        emit(
          state.copyWith(
            isActionLoading: false,
            errorMessage: response['message'] ?? 'Failed to update system user',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          isActionLoading: false,
          errorMessage: e is ApiException ? e.message : 'Something went wrong',
        ),
      );
    }
  }

  Future<void> _onDeleteSystemUser(
    DeleteSystemUserEvent event,
    Emitter<SystemUserState> emit,
  ) async {
    try {
      emit(state.copyWith(isActionLoading: true, actionMessage: null));

      final response = await _repo.deleteSystemUser(event.id);

      if (response['success'] == true) {
        emit(
          state.copyWith(
            isActionLoading: false,
            actionMessage:
                response['message'] ?? 'Successfully deleted system user',
          ),
        );
        add(FetchSystemUsersEvent(isRefresh: true, search: state.search));
      } else {
        emit(
          state.copyWith(
            isActionLoading: false,
            errorMessage: response['message'] ?? 'Failed to delete system user',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          isActionLoading: false,
          errorMessage: e is ApiException ? e.message : 'Something went wrong',
        ),
      );
    }
  }

  List<SystemUser> _patchUsers(LoginApprovalResult result) =>
      state.users.map((user) {
        if (user.id != result.userId) return user;
        return user.copyWithApproval(
          loginApprovalStatus: result.loginApprovalStatus,
          loginApprovedUntil: result.loginApprovedUntil,
          clearApprovedUntil: result.loginApprovedUntil == null,
          systemUserStatus: result.systemUserStatus,
        );
      }).toList();

  Future<void> _decideLogin(
    int id,
    Future<LoginApprovalResult> Function() call,
    Emitter<SystemUserState> emit,
  ) async {
    if (state.processingIds.contains(id)) return;
    emit(
      state.copyWith(
        processingIds: {...state.processingIds, id},
        clearMessages: true,
      ),
    );
    try {
      final result = await call();
      final until = result.loginApprovedUntil;
      emit(
        state.copyWith(
          users: _patchUsers(result),
          processingIds: {...state.processingIds}..remove(id),
          approvalResult: result,
          actionMessage: result.loginApprovalStatus == 'disapproved'
              ? 'Access revoked'
              : until == null
              ? 'Login approved'
              : 'Login approved until ${DateFormat('dd MMM, hh:mm a').format(until)}',
        ),
      );
      add(
        FetchSystemUsersEvent(
          isRefresh: true,
          silent: true,
          search: state.search,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          processingIds: {...state.processingIds}..remove(id),
          approvalErrorId: id,
          approvalErrorStatus: e is ApiException ? e.statusCode : null,
          errorMessage: e is ApiException ? e.message : 'Something went wrong',
        ),
      );
      if (e is ApiException && e.statusCode == 404) {
        add(
          FetchSystemUsersEvent(
            isRefresh: true,
            silent: true,
            search: state.search,
          ),
        );
      }
    }
  }
}
