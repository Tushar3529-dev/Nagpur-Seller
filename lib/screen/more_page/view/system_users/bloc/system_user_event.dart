part of 'system_user_bloc.dart';

abstract class SystemUserEvent {}

class FetchSystemUsersEvent extends SystemUserEvent {
  final bool isRefresh;
  final String? search;

  FetchSystemUsersEvent({this.isRefresh = false, this.search});
}

class LoadMoreSystemUsersEvent extends SystemUserEvent {}

class ManageSystemUserEvent extends SystemUserEvent {
  final Map<String, dynamic> data;

  ManageSystemUserEvent({required this.data});
}

class DeleteSystemUserEvent extends SystemUserEvent {
  final int id;

  DeleteSystemUserEvent({required this.id});
}

class ClearSystemUserMessages extends SystemUserEvent {}

class SystemUserReset extends SystemUserEvent {}
