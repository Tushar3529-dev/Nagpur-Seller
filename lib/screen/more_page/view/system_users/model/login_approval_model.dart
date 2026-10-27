import 'package:hyper_local_seller/screen/more_page/view/system_users/model/system_users_model.dart';
import 'package:hyper_local_seller/service/json_parser.dart';

/// A system user's pending login request, as returned by
/// `GET /seller/system-users/login-approvals`.
class LoginApprovalRequest {
  final int userId;
  final String name;
  final String? email;
  final String? mobile;
  final String status;
  final String systemUserStatus;
  final DateTime? requestedAt;
  final DateTime? approvedUntil;

  const LoginApprovalRequest({
    required this.userId,
    required this.name,
    this.email,
    this.mobile,
    required this.status,
    this.systemUserStatus = 'inactive',
    this.requestedAt,
    this.approvedUntil,
  });

  factory LoginApprovalRequest.fromJson(Map<String, dynamic> json) {
    return LoginApprovalRequest(
      userId: int.tryParse(json['user_id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString(),
      mobile: json['mobile']?.toString(),
      status: SystemUser.parseApprovalStatus(json['login_approval_status']),
      systemUserStatus: SystemUser.parseActivityStatus(
        json['system_user_status'],
      ),
      requestedAt: _parseDate(json['login_approval_requested_at']),
      approvedUntil: _parseDate(json['login_approved_until']),
    );
  }

  static DateTime? _parseDate(dynamic value) =>
      DateTime.tryParse(value?.toString() ?? '')?.toLocal();
}

class LoginApprovalsPage {
  final int currentPage;
  final int lastPage;
  final int total;
  final List<LoginApprovalRequest> items;

  const LoginApprovalsPage({
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.items,
  });

  factory LoginApprovalsPage.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'])
        : <String, dynamic>{};
    final list = data['data'] is List ? data['data'] as List : const [];
    return LoginApprovalsPage(
      currentPage: int.tryParse(data['current_page']?.toString() ?? '') ?? 1,
      lastPage: int.tryParse(data['last_page']?.toString() ?? '') ?? 1,
      total: int.tryParse(data['total']?.toString() ?? '') ?? list.length,
      items: list
          .whereType<Map>()
          .map(
            (e) => LoginApprovalRequest.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList(),
    );
  }
}

class LoginApprovalResult {
  final int userId;
  final String loginApprovalStatus;
  final DateTime? loginApprovedUntil;
  final String systemUserStatus;

  const LoginApprovalResult({
    required this.userId,
    required this.loginApprovalStatus,
    this.loginApprovedUntil,
    required this.systemUserStatus,
  });

  factory LoginApprovalResult.fromJson(Map<String, dynamic> json) =>
      LoginApprovalResult(
        userId: JsonParser.intValue(json['user_id']),
        loginApprovalStatus: SystemUser.parseApprovalStatus(
          json['login_approval_status'],
        ),
        loginApprovedUntil: DateTime.tryParse(
          JsonParser.string(json['login_approved_until']),
        )?.toLocal(),
        systemUserStatus: SystemUser.parseActivityStatus(
          json['system_user_status'],
        ),
      );
}
