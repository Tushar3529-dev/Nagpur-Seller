part of 'roles_bloc.dart';

sealed class RolesEvent extends Equatable {
  const RolesEvent();

  @override
  List<Object?> get props => [];
}

class LoadRolesInitial extends RolesEvent {
  final String? search;
  const LoadRolesInitial({this.search});

  @override
  List<Object?> get props => [search];
}

class LoadMoreRoles extends RolesEvent {}

class RefreshRoles extends RolesEvent {}

class SearchRoles extends RolesEvent {
  final String query;
  const SearchRoles(this.query);

  @override
  List<Object?> get props => [query];
}

class ManageRole extends RolesEvent {
  final String name;
  final int? id;

  const ManageRole({required this.name, this.id});

  @override
  List<Object?> get props => [name, id];
}

class DeleteRole extends RolesEvent {
  final int id;

  const DeleteRole(this.id);

  @override
  List<Object?> get props => [id];
}

class RolesReset extends RolesEvent {}
