import 'package:equatable/equatable.dart';
import 'package:hyper_local_seller/service/json_parser.dart';

enum RiderStatus { active, inactive }

enum RiderLoginApproval { disapproved, pending, approved }

DateTime? riderLocalDate(dynamic value) =>
    DateTime.tryParse(JsonParser.string(value))?.toLocal();

class DeliveryBoy extends Equatable {
  final int id;
  final int userId;
  final String name;
  final String email;
  final String mobile;
  final int deliveryZoneId;
  final RiderStatus status;
  final String verificationStatus;
  final RiderLoginApproval loginApproval;
  final DateTime? loginApprovalRequestedAt;
  final DateTime? loginApprovedUntil;
  final DateTime? qrLoginExpiresAt;

  const DeliveryBoy({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.mobile,
    required this.deliveryZoneId,
    required this.status,
    required this.verificationStatus,
    required this.loginApproval,
    this.loginApprovalRequestedAt,
    this.loginApprovedUntil,
    this.qrLoginExpiresAt,
  });

  factory DeliveryBoy.fromJson(Map<String, dynamic> json) => DeliveryBoy(
    id: JsonParser.intValue(json['id']),
    userId: JsonParser.intValue(json['user_id']),
    name: JsonParser.string(json['name']),
    email: JsonParser.string(json['email']),
    mobile: JsonParser.string(json['mobile']),
    deliveryZoneId: JsonParser.intValue(json['delivery_zone_id']),
    status: json['status'] == 'active'
        ? RiderStatus.active
        : RiderStatus.inactive,
    verificationStatus: JsonParser.string(json['verification_status']),
    loginApproval: RiderLoginApproval.values.firstWhere(
      (value) => value.name == json['login_approval_status'],
      orElse: () => RiderLoginApproval.disapproved,
    ),
    loginApprovalRequestedAt: riderLocalDate(
      json['login_approval_requested_at'],
    ),
    loginApprovedUntil: riderLocalDate(json['login_approved_until']),
    qrLoginExpiresAt: riderLocalDate(json['qr_login_expires_at']),
  );

  bool get isActive => status == RiderStatus.active;
  bool get isVerified => verificationStatus == 'verified';
  bool get isApprovalLive =>
      loginApproval == RiderLoginApproval.approved &&
      loginApprovedUntil != null &&
      loginApprovedUntil!.isAfter(DateTime.now());
  bool get isApprovalExpired =>
      loginApproval == RiderLoginApproval.approved && !isApprovalLive;
  bool get isLoginPending => loginApproval == RiderLoginApproval.pending;

  DeliveryBoy copyWith({
    RiderStatus? status,
    RiderLoginApproval? loginApproval,
    DateTime? loginApprovedUntil,
    bool clearApprovedUntil = false,
  }) => DeliveryBoy(
    id: id,
    userId: userId,
    name: name,
    email: email,
    mobile: mobile,
    deliveryZoneId: deliveryZoneId,
    status: status ?? this.status,
    verificationStatus: verificationStatus,
    loginApproval: loginApproval ?? this.loginApproval,
    loginApprovalRequestedAt: loginApprovalRequestedAt,
    loginApprovedUntil: clearApprovedUntil
        ? null
        : loginApprovedUntil ?? this.loginApprovedUntil,
    qrLoginExpiresAt: qrLoginExpiresAt,
  );

  @override
  List<Object?> get props => [
    id,
    userId,
    name,
    email,
    mobile,
    deliveryZoneId,
    status,
    verificationStatus,
    loginApproval,
    loginApprovalRequestedAt,
    loginApprovedUntil,
    qrLoginExpiresAt,
  ];
}

class RiderPage {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final List<DeliveryBoy> data;
  const RiderPage({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    required this.data,
  });
  factory RiderPage.fromJson(Map<String, dynamic> json) => RiderPage(
    currentPage: JsonParser.intValue(json['current_page'], fallback: 1),
    lastPage: JsonParser.intValue(json['last_page'], fallback: 1),
    perPage: JsonParser.intValue(json['per_page'], fallback: 15),
    total: JsonParser.intValue(json['total']),
    data: JsonParser.list(
      json['data'],
      (value) => DeliveryBoy.fromJson(Map<String, dynamic>.from(value)),
    ),
  );
  bool get hasMore => currentPage < lastPage;
}

class DeliveryBoysListResponse {
  final RiderPage assigned;
  final RiderPage available;
  const DeliveryBoysListResponse({
    required this.assigned,
    required this.available,
  });
  factory DeliveryBoysListResponse.fromJson(Map<String, dynamic> json) {
    final data = Map<String, dynamic>.from(json['data'] ?? {});
    return DeliveryBoysListResponse(
      assigned: RiderPage.fromJson(
        Map<String, dynamic>.from(data['assigned_riders'] ?? {}),
      ),
      available: RiderPage.fromJson(
        Map<String, dynamic>.from(data['available_riders'] ?? {}),
      ),
    );
  }
}

// Intentionally not Equatable: diagnostics must never include the credential.
class RiderQrCredential {
  final int riderId;
  final String qrPayload;
  final DateTime? expiresAt;
  const RiderQrCredential({
    required this.riderId,
    required this.qrPayload,
    required this.expiresAt,
  });
  factory RiderQrCredential.fromJson(Map<String, dynamic> json) =>
      RiderQrCredential(
        riderId: JsonParser.intValue(json['rider_id']),
        qrPayload: JsonParser.string(json['qr_payload'], trim: false),
        expiresAt: riderLocalDate(json['expires_at']),
      );
}
