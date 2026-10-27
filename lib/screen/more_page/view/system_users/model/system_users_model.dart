import 'package:hyper_local_seller/service/api_base_helper.dart';
import 'package:hyper_local_seller/service/json_parser.dart';

const String modelName = 'system_users_model';

class SystemUsersResponse {
  bool? success;
  String? message;
  SystemUsersPageData? data;

  SystemUsersResponse({this.success, this.message, this.data});

  factory SystemUsersResponse.fromJson(Map<String, dynamic> json) {
    return SystemUsersResponse(
      success: JsonParser.boolValue(json['success'] ?? false),
      message: JsonParser.string(json['message'] ?? ''),
      data: json['data'] != null
          ? SystemUsersPageData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class SystemUsersPageData {
  int? currentPage;
  int? lastPage;
  int? perPage;
  int? total;
  List<SystemUser>? users;

  SystemUsersPageData({
    this.currentPage,
    this.lastPage,
    this.perPage,
    this.total,
    this.users,
  });

  factory SystemUsersPageData.fromJson(Map<String, dynamic> json) {
    return SystemUsersPageData(
      currentPage: JsonParser.intValue(json['current_page'] ?? 1),
      lastPage: JsonParser.intValue(json['last_page'] ?? 1),
      perPage: JsonParser.intValue(json['per_page'] ?? 15),
      total: JsonParser.intValue(json['total'] ?? 0),

      users: JsonParser.list<SystemUser>(
        json['data'],
        (v) => SystemUser.fromJson(v as Map<String, dynamic>),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['current_page'] = currentPage;
    data['last_page'] = lastPage;
    data['per_page'] = perPage;
    data['total'] = total;
    if (users != null) {
      data['data'] = users!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class SystemUser {
  int id;
  String mobile;
  String? referralCode;
  String? friendsCode;
  int rewardPoints;
  bool status;
  String? name;
  String? email;
  String? country;
  String? iso2;
  String? emailVerifiedAt;
  String? accessPanel;
  String? deletedAt;
  String? createdAt;
  String? updatedAt;
  String? profileImage;
  String loginApprovalStatus;
  DateTime? loginApprovalRequestedAt;
  DateTime? loginApprovedUntil;
  String systemUserStatus;
  List<dynamic>? media; // usually empty or list of media objects/urls

  SystemUser({
    required this.id,
    required this.mobile,
    this.referralCode,
    this.friendsCode,
    this.rewardPoints = 0,
    this.status = true,
    this.name,
    this.email,
    this.country,
    this.iso2,
    this.emailVerifiedAt,
    this.accessPanel,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
    this.profileImage,
    this.media,
    this.loginApprovalStatus = 'not_requested',
    this.loginApprovalRequestedAt,
    this.loginApprovedUntil,
    this.systemUserStatus = 'inactive',
  });

  bool get isActive => systemUserStatus == 'active';
  bool get isApprovalPending => loginApprovalStatus == 'pending';
  bool get isApproved => loginApprovalStatus == 'approved';
  bool get isDisapproved => loginApprovalStatus == 'disapproved';

  static String parseApprovalStatus(dynamic value) {
    final status = JsonParser.string(value);
    return const [
          'not_requested',
          'pending',
          'approved',
          'disapproved',
        ].contains(status)
        ? status
        : 'not_requested';
  }

  static String parseActivityStatus(dynamic value) =>
      JsonParser.string(value) == 'active' ? 'active' : 'inactive';

  SystemUser copyWithApproval({
    String? loginApprovalStatus,
    DateTime? loginApprovedUntil,
    bool clearApprovedUntil = false,
    String? systemUserStatus,
  }) => SystemUser.fromJson({
    ...toJson(),
    'login_approval_status': loginApprovalStatus ?? this.loginApprovalStatus,
    'login_approved_until': clearApprovedUntil
        ? null
        : (loginApprovedUntil ?? this.loginApprovedUntil)?.toIso8601String(),
    'system_user_status': systemUserStatus ?? this.systemUserStatus,
  });

  factory SystemUser.fromJson(Map<String, dynamic> json) {
    return SystemUser(
      id: JsonParser.requireInt(json['id'], model: modelName, field: 'id'),
      mobile: JsonParser.requireString(
        json['mobile'],
        model: modelName,
        field: 'mobile',
      ),

      referralCode: JsonParser.string(json['referral_code']),
      friendsCode: JsonParser.string(json['friends_code']),

      rewardPoints: JsonParser.intValue(json['reward_points'] ?? 0),
      status: JsonParser.boolValue(json['status'] ?? true),

      name: JsonParser.string(json['name'] ?? ''),
      email: JsonParser.string(json['email'] ?? ''),
      country: JsonParser.string(json['country']),
      iso2: JsonParser.string(json['iso_2']),
      emailVerifiedAt: JsonParser.string(json['email_verified_at']),
      accessPanel: JsonParser.string(json['access_panel']),

      deletedAt: JsonParser.string(json['deleted_at']),
      createdAt: JsonParser.string(json['created_at'] ?? ''),
      updatedAt: JsonParser.string(json['updated_at'] ?? ''),

      loginApprovalStatus: parseApprovalStatus(json['login_approval_status']),
      loginApprovalRequestedAt: DateTime.tryParse(
        JsonParser.string(json['login_approval_requested_at']),
      )?.toLocal(),
      loginApprovedUntil: DateTime.tryParse(
        JsonParser.string(json['login_approved_until']),
      )?.toLocal(),
      systemUserStatus: parseActivityStatus(json['system_user_status']),
      profileImage: JsonParser.string(json['profile_image']),

      media: JsonParser.list<dynamic>(
        json['media'],
        (v) => v, // can be refined later if media has known structure
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['mobile'] = mobile;
    data['referral_code'] = referralCode;
    data['friends_code'] = friendsCode;
    data['reward_points'] = rewardPoints;
    data['status'] = status;
    data['name'] = name;
    data['email'] = email;
    data['country'] = country;
    data['iso_2'] = iso2;
    data['email_verified_at'] = emailVerifiedAt;
    data['access_panel'] = accessPanel;
    data['deleted_at'] = deletedAt;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['profile_image'] = profileImage;
    data['media'] = media;
    data['login_approval_status'] = loginApprovalStatus;
    data['login_approval_requested_at'] = loginApprovalRequestedAt
        ?.toIso8601String();
    data['login_approved_until'] = loginApprovedUntil?.toIso8601String();
    data['system_user_status'] = systemUserStatus;
    return data;
  }
}

/// Detail statuses live beside `user` and always override the nested fields.
class SystemUserDetail {
  final SystemUser user;

  const SystemUserDetail({required this.user});

  factory SystemUserDetail.fromJson(Map<String, dynamic> data) {
    final user = data['user'];
    if (user is! Map) {
      throw ApiException('System user details are unavailable.');
    }
    return SystemUserDetail(
      user: SystemUser.fromJson({
        ...Map<String, dynamic>.from(user),
        for (final key in const [
          'login_approval_status',
          'login_approval_requested_at',
          'login_approved_until',
          'system_user_status',
        ])
          key: data[key],
      }),
    );
  }
}
