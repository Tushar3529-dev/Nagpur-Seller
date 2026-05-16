import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/model/system_users_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/repo/system_users_repo.dart';

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
    on<ClearSystemUserMessages>((event, emit) => emit(state.copyWith(clearMessages: true)));
    on<SystemUserReset>((event, emit) => emit(SystemUserState()));
  }

  Future<void> _onFetchSystemUsers(
    FetchSystemUsersEvent event,
    Emitter<SystemUserState> emit,
  ) async {
    try {
      if (event.isRefresh) {
        emit(state.copyWith(status: SystemUserStatus.loading, currentPage: 1, hasReachedMax: false, search: event.search, clearMessages: true));
      } else {
        emit(state.copyWith(status: SystemUserStatus.loading, search: event.search, clearMessages: true));
      }

      final response = await _repo.getSystemUsers(
        page: 1,
        search: event.search,
      );

      final systemUsersResponse = SystemUsersResponse.fromJson(response);

      if (systemUsersResponse.success == true) {
        final data = systemUsersResponse.data;
        emit(state.copyWith(
          status: SystemUserStatus.success,
          users: data?.users ?? [],
          total: data?.total ?? 0,
          currentPage: 1,
          hasReachedMax: (data?.currentPage ?? 1) >= (data?.lastPage ?? 1),
        ));
      } else {
        emit(state.copyWith(
          status: SystemUserStatus.failure,
          errorMessage: systemUsersResponse.message,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: SystemUserStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLoadMoreSystemUsers(
    LoadMoreSystemUsersEvent event,
    Emitter<SystemUserState> emit,
  ) async {
    if (state.hasReachedMax || state.status == SystemUserStatus.loadingMore) return;

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
        final List<SystemUser> updatedUsers = List.from(state.users)..addAll(data?.users ?? []);
        emit(state.copyWith(
          status: SystemUserStatus.success,
          users: updatedUsers,
          currentPage: nextPage,
          hasReachedMax: (data?.currentPage ?? 1) >= (data?.lastPage ?? 1),
        ));
      } else {
        emit(state.copyWith(
          status: SystemUserStatus.success, // Keep existing data but stop loading
          hasReachedMax: true,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: SystemUserStatus.success, // Keep existing data but stop loading
        hasReachedMax: true,
      ));
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
        emit(state.copyWith(
          isActionLoading: false,
          actionMessage: response['message'] ?? 'Successfully updated system user',
        ));
        add(FetchSystemUsersEvent(isRefresh: true, search: state.search));
      } else {
        emit(state.copyWith(
          isActionLoading: false,
          errorMessage: response['message'] ?? 'Failed to update system user',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isActionLoading: false,
        errorMessage: e.toString(),
      ));
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
        emit(state.copyWith(
          isActionLoading: false,
          actionMessage: response['message'] ?? 'Successfully deleted system user',
        ));
        add(FetchSystemUsersEvent(isRefresh: true, search: state.search));
      } else {
        emit(state.copyWith(
          isActionLoading: false,
          errorMessage: response['message'] ?? 'Failed to delete system user',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isActionLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }
}
