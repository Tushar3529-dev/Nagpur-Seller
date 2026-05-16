
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/bloc/pagination/paginated_state.dart';
import 'package:hyper_local_seller/bloc/pagination/pagination_controller.dart';
import 'package:hyper_local_seller/bloc/pagination/pagination_response.dart';
import 'package:hyper_local_seller/config/global_keys.dart';
import 'package:hyper_local_seller/screen/more_page/view/roles_and_permissions/model/roles_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/roles_and_permissions/repo/roles_repo.dart';

part 'roles_event.dart';
part 'roles_state.dart';

class RolesBloc extends Bloc<RolesEvent, RolesState> {
  final RolesRepo _repo;
  late final PaginationController<Role> _paginationController;
  String? _searchQuery;

  RolesBloc(this._repo) : super(const RolesState()) {
    _paginationController = PaginationController<Role>(
      fetcher: _fetchRoles,
      emit: (paginatedState) => emit(state.copyWith(
        items: paginatedState.items,
        isInitialLoading: paginatedState.isInitialLoading,
        isRefreshing: paginatedState.isRefreshing,
        isPaginating: paginatedState.isPaginating,
        hasMore: paginatedState.hasMore,
        error: paginatedState.error,
        currentPage: paginatedState.currentPage,
        total: paginatedState.total,
      )),
      perPage: GlobalKeys.perPage,
    );

    on<LoadRolesInitial>(_onLoadRolesInitial);
    on<LoadMoreRoles>(_onLoadMoreRoles);
    on<RefreshRoles>(_onRefreshRoles);
    on<SearchRoles>(_onSearchRoles);
    on<ManageRole>(_onManageRole);
    on<DeleteRole>(_onDeleteRole);
    on<RolesReset>(_onRolesReset);
  }

  Future<PaginationResponse<Role>> _fetchRoles(int page, int perPage) async {
    final response = await _repo.getRoles(
      page: page,
      perPage: perPage,
      search: _searchQuery,
    );

    final rolesResponse = RolesResponse.fromJson(response);
    return PaginationResponse(
      items: rolesResponse.data?.roles ?? [],
      total: rolesResponse.data?.total,
      hasMore: rolesResponse.data?.currentPage != rolesResponse.data?.lastPage,
      currentPage: page,
    );
  }

  Future<void> _onLoadRolesInitial(
    LoadRolesInitial event,
    Emitter<RolesState> emit,
  ) async {
    _searchQuery = event.search;
    await _paginationController.loadInitial(currentState: state);
  }

  Future<void> _onLoadMoreRoles(
    LoadMoreRoles event,
    Emitter<RolesState> emit,
  ) async {
    await _paginationController.loadNextPage(state);
  }

  Future<void> _onRefreshRoles(
    RefreshRoles event,
    Emitter<RolesState> emit,
  ) async {
    await _paginationController.refresh(state);
  }

  Future<void> _onSearchRoles(
    SearchRoles event,
    Emitter<RolesState> emit,
  ) async {
    _searchQuery = event.query;
    await _paginationController.loadInitial(currentState: state);
  }

  Future<void> _onManageRole(ManageRole event, Emitter<RolesState> emit) async {
    emit(state.copyWith(clearOperation: true));
    try {
      final response = await _repo.manageRole(event.name, event.id);
      if (response['success'] == true) {
        emit(state.copyWith(
          operationSuccess: true,
          operationMessage:
              response['message'] ?? 'Role operation success',
          lastOperationType: event.id == null ? 'add' : 'edit',
        ));
        add(RefreshRoles());
      } else {
        emit(state.copyWith(
          operationSuccess: false,
          operationMessage: response['message'] ?? 'Failed to manage role',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        operationSuccess: false,
        operationMessage: e.toString(),
      ));
    }
  }

  Future<void> _onDeleteRole(DeleteRole event, Emitter<RolesState> emit) async {
    emit(state.copyWith(clearOperation: true));
    try {
      final response = await _repo.deleteRole(event.id);
      if (response['success'] == true) {
        emit(state.copyWith(
          operationSuccess: true,
          operationMessage: response['message'] ?? 'Role deleted successfully',
          lastOperationType: 'delete',
        ));
        add(RefreshRoles());
      } else {
        emit(state.copyWith(
          operationSuccess: false,
          operationMessage: response['message'] ?? 'Failed to delete role',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        operationSuccess: false,
        operationMessage: e.toString(),
      ));
    }
  }

  Future<void> _onRolesReset(
      RolesReset event,
      Emitter<RolesState> emit,
      ) async {
    _searchQuery = null;
    emit(const RolesState());
    _paginationController.reset();
  }
}
