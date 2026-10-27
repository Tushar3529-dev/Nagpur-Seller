import 'dart:async';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hyper_local_seller/config/app_permissions.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/model/login_approval_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/model/system_users_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/repo/system_users_repo.dart';

Map<String, dynamic> userJson({
  String approval = 'pending',
  String activity = 'inactive',
  String? until,
}) => {
  'id': 196,
  'name': 'Staff User',
  'email': 'staff@example.com',
  'mobile': '9876543210',
  'access_panel': 'seller',
  'profile_image': null,
  'roles': [
    {'name': 'packer'},
  ],
  'login_approval_status': approval,
  'system_user_status': activity,
  'login_approval_requested_at': null,
  'login_approved_until': until,
};

Future<void> initSystemUserHive({bool manage = true}) async {
  Hive.init(Directory.systemTemp.createTempSync('system-user-test').path);
  await HiveStorage.setUserData({
    'id': 1,
    'assigned_permissions': [
      AppPermissions.systemUserView,
      if (manage) AppPermissions.systemUserEdit,
      AppPermissions.systemUserCreate,
      AppPermissions.systemUserDelete,
    ],
  });
}

class FakeSystemUsersRepo extends SystemUsersRepo {
  int fetches = 0;
  int inboxFetches = 0;
  int approvals = 0;
  int rejections = 0;
  int detailFetches = 0;
  String? search;
  Object? decisionError;
  Object? detailError;
  Completer<void>? decisionGate;
  Completer<void>? refreshGate;
  Map<String, dynamic> row = userJson();
  LoginApprovalResult result = LoginApprovalResult.fromJson({
    'user_id': 196,
    'login_approval_status': 'approved',
    'login_approved_until': '2026-10-26T08:00:00Z',
    'system_user_status': 'inactive',
  });

  @override
  Future<dynamic> getSystemUsers({
    int? page,
    int? perPage,
    String? search,
  }) async {
    fetches++;
    this.search = search;
    if (fetches > 1 && refreshGate != null) await refreshGate!.future;
    return {
      'success': true,
      'data': {
        'current_page': page ?? 1,
        'last_page': 1,
        'total': 1,
        'data': [row],
      },
    };
  }

  @override
  Future<SystemUser> getSystemUserDetail(int id) async {
    detailFetches++;
    if (detailError != null) throw detailError!;
    return SystemUser.fromJson(row);
  }

  @override
  Future<LoginApprovalsPage> getPendingLoginApprovals({
    int page = 1,
    int perPage = 15,
  }) async {
    inboxFetches++;
    final pending = row['login_approval_status'] == 'pending';
    return LoginApprovalsPage(
      currentPage: 1,
      lastPage: 1,
      total: pending ? 1 : 0,
      items: pending
          ? [
              LoginApprovalRequest.fromJson({...row, 'user_id': 196}),
            ]
          : [],
    );
  }

  Future<LoginApprovalResult> decide() async {
    if (decisionGate != null) await decisionGate!.future;
    if (decisionError != null) throw decisionError!;
    row = {
      ...row,
      'login_approval_status': result.loginApprovalStatus,
      'system_user_status': result.systemUserStatus,
      'login_approved_until': result.loginApprovedUntil?.toIso8601String(),
    };
    return result;
  }

  @override
  Future<LoginApprovalResult> approveLogin(int userId) async {
    approvals++;
    return decide();
  }

  @override
  Future<LoginApprovalResult> disapproveLogin(int userId) async {
    rejections++;
    result = LoginApprovalResult.fromJson({
      'user_id': userId,
      'login_approval_status': 'disapproved',
      'system_user_status': 'inactive',
      'login_approved_until': null,
      'duration_hours': null,
    });
    return decide();
  }

  @override
  Future<dynamic> manageSystemUser(Map<String, dynamic> data) async => {
    'success': true,
    'message': 'Saved',
  };
  @override
  Future<dynamic> deleteSystemUser(int id) async => {
    'success': true,
    'message': 'Deleted',
  };
}
