part of 'permissions_bloc.dart';

sealed class PermissionsState extends Equatable {
  const PermissionsState();

  @override
  List<Object?> get props => [];
}

final class PermissionsInitial extends PermissionsState {}

final class PermissionsLoading extends PermissionsState {}

final class PermissionsLoaded extends PermissionsState {
  final SellerPermissionsData data;
  final List<String> currentAssigned;

  const PermissionsLoaded(this.data, this.currentAssigned);

  @override
  List<Object?> get props => [data, currentAssigned];
}

final class PermissionsError extends PermissionsState {
  final String message;

  const PermissionsError(this.message);

  @override
  List<Object?> get props => [message];
}

final class PermissionsSyncSuccess extends PermissionsState {
  final String message;

  const PermissionsSyncSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
