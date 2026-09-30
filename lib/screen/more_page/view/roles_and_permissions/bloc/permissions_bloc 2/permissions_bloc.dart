import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/roles_and_permissions/model/permission_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/roles_and_permissions/repo/permissions_repo.dart';

part 'permissions_event.dart';
part 'permissions_state.dart';

class PermissionsBloc extends Bloc<PermissionsEvent, PermissionsState> {
  final PermissionsRepo _repo;
  List<String> _currentAssigned = [];
  SellerPermissionsData? _allData;

  PermissionsBloc(this._repo) : super(PermissionsInitial()) {
    on<GetPermissions>(_onGetPermissions);
    on<TogglePermission>(_onTogglePermission);
    on<ToggleMultiplePermissions>(_onToggleMultiplePermissions);
    on<SyncPermissions>(_onSyncPermissions);
  }
  void _onToggleMultiplePermissions(ToggleMultiplePermissions event, Emitter<PermissionsState> emit) {
    if (state is PermissionsLoaded) {
      final newList = List<String>.from(_currentAssigned);
      if (event.select) {
        for (var p in event.permissions) {
          if (!newList.contains(p)) newList.add(p);
        }
      } else {
        for (var p in event.permissions) {
          newList.remove(p);
        }
      }
      _currentAssigned = newList;
      emit(PermissionsLoaded(_allData!, _currentAssigned));
    }
  }

  Future<void> _onGetPermissions(GetPermissions event, Emitter<PermissionsState> emit) async {
    emit(PermissionsLoading());
    try {
      final response = await _repo.getSellerPermissions(event.role);
      final permissionsResponse = SellerPermissionsResponse.fromJson(response);
      if (permissionsResponse.success == true && permissionsResponse.data != null) {
        _allData = permissionsResponse.data;
        _currentAssigned = List.from(_allData!.assigned);
        emit(PermissionsLoaded(_allData!, _currentAssigned));
      } else {
        emit(PermissionsError(permissionsResponse.message ?? 'Failed to fetch permissions'));
      }
    } catch (e) {
      emit(PermissionsError(e.toString()));
    }
  }

  void _onTogglePermission(TogglePermission event, Emitter<PermissionsState> emit) {
    if (state is PermissionsLoaded) {
      final newList = List<String>.from(_currentAssigned);
      if (newList.contains(event.permission)) {
        newList.remove(event.permission);
      } else {
        newList.add(event.permission);
      }
      _currentAssigned = newList;
      emit(PermissionsLoaded(_allData!, _currentAssigned));
    }
  }

  Future<void> _onSyncPermissions(SyncPermissions event, Emitter<PermissionsState> emit) async {
    emit(PermissionsLoading());
    try {
      final data = {
        'role': event.role,
        'permissions': _currentAssigned,
      };
      final response = await _repo.syncSellerPermissions(data);
      if (response['success'] == true) {
        emit(PermissionsSyncSuccess(response['message'] ?? 'Permissions synced successfully'));
      } else {
        emit(PermissionsError(response['message'] ?? 'Failed to sync permissions'));
      }
    } catch (e) {
      emit(PermissionsError(e.toString()));
    }
  }
}
