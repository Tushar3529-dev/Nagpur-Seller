part of 'system_user_bloc.dart';

abstract class SystemUserEvent {}

class FetchSystemUsersEvent extends SystemUserEvent {
  final bool isRefresh;
  final bool silent;
  final String? search;

  FetchSystemUsersEvent({
    this.isRefresh = false,
    this.silent = false,
    this.search,
  });
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

class ApproveSystemUserLoginEvent extends SystemUserEvent {
  final int id;
  ApproveSystemUserLoginEvent({required this.id});
}

class DisapproveSystemUserLoginEvent extends SystemUserEvent {
  final int id;
  DisapproveSystemUserLoginEvent({required this.id});
}

class ApplyLoginApprovalResultEvent extends SystemUserEvent {
  final LoginApprovalResult result;
  ApplyLoginApprovalResultEvent(this.result);
}
