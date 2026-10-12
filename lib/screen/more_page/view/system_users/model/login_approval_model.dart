/// A system user's pending login request, as returned by
/// `GET /seller/system-users/login-approvals`.
class LoginApprovalRequest {
  final int userId;
  final String name;
  final String? email;
  final String? mobile;
  final String status;
  final DateTime? requestedAt;
  final DateTime? approvedUntil;

  const LoginApprovalRequest({
    required this.userId,
    required this.name,
    this.email,
    this.mobile,
    required this.status,
    this.requestedAt,
    this.approvedUntil,
  });

  factory LoginApprovalRequest.fromJson(Map<String, dynamic> json) {
    return LoginApprovalRequest(
      userId: int.tryParse(json['user_id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString(),
      mobile: json['mobile']?.toString(),
      status: json['login_approval_status']?.toString() ?? 'pending',
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
