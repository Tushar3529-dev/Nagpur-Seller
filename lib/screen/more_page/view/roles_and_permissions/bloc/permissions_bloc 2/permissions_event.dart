part of 'permissions_bloc.dart';

sealed class PermissionsEvent extends Equatable {
  const PermissionsEvent();

  @override
  List<Object?> get props => [];
}

class GetPermissions extends PermissionsEvent {
  final String role;

  const GetPermissions(this.role);

  @override
  List<Object?> get props => [role];
}

class TogglePermission extends PermissionsEvent {
  final String permission;

  const TogglePermission(this.permission);

  @override
  List<Object?> get props => [permission];
}

class ToggleMultiplePermissions extends PermissionsEvent {
  final List<String> permissions;
  final bool select;

  const ToggleMultiplePermissions(this.permissions, this.select);

  @override
  List<Object?> get props => [permissions, select];
}

class SyncPermissions extends PermissionsEvent {
  final String role;

  const SyncPermissions(this.role);

  @override
  List<Object?> get props => [role];
}
