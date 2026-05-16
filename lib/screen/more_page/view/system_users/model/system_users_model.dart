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
  });

  factory SystemUser.fromJson(Map<String, dynamic> json) {
    return SystemUser(
      id: JsonParser.requireInt(json['id'], model: modelName, field: 'id'),
      mobile: JsonParser.requireString(json['mobile'], model: modelName, field: 'mobile'),

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
    return data;
  }
}