import 'package:hyper_local_seller/service/json_parser.dart';

const String modelName = 'user_profile';

class UserProfile {
  bool? success;
  String? message;
  Data? data;
  List<String>? assignedPermissions;

  UserProfile({
    this.success,
    this.message,
    this.data,
    this.assignedPermissions,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      success: JsonParser.boolValue(json['success']),
      message: JsonParser.string(json['message']),
      data: json['data'] != null
          ? Data.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      assignedPermissions: json['assigned_permissions'] != null 
          ? List<String>.from(json['assigned_permissions'] as List)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {};
    map['success'] = success;
    map['message'] = message;
    if (data != null) {
      map['data'] = data!.toJson();
    }
    if (assignedPermissions != null) {
      map['assigned_permissions'] = assignedPermissions;
    }
    return map;
  }
}

class Data {
  int? id;
  String? name;
  String? email;
  String? mobile;
  String? country;           // changed Null? → String? (more idiomatic)
  String? iso2;
  String? walletBalance;     // often string from API ("124.50")
  String? referralCode;
  String? friendsCode;
  int? rewardPoints;
  String? profileImage;
  String? emailVerifiedAt;   // usually ISO string or null
  String? createdAt;
  String? updatedAt;

  Data({
    this.id,
    this.name,
    this.email,
    this.mobile,
    this.country,
    this.iso2,
    this.walletBalance,
    this.referralCode,
    this.friendsCode,
    this.rewardPoints,
    this.profileImage,
    this.emailVerifiedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      // Critical / identifying fields → strict parsing (throw if really broken)
      id: JsonParser.requireInt(
        json['id'],
        model: modelName,
        field: 'id',
      ),
      name: JsonParser.requireString(
        json['name'],
        model: modelName,
        field: 'name',
      ),
      email: JsonParser.requireString(
        json['email'],
        model: modelName,
        field: 'email',
      ),

      // Optional / flexible fields
      mobile: JsonParser.string(json['mobile']),
      country: JsonParser.string(json['country']),
      iso2: JsonParser.string(json['iso_2']),
      walletBalance: JsonParser.string(json['wallet_balance']),
      referralCode: JsonParser.string(json['referral_code']),
      friendsCode: JsonParser.string(json['friends_code']),

      rewardPoints: JsonParser.intValue(json['reward_points']),

      profileImage: JsonParser.string(json['profile_image']),

      // Timestamps usually come as strings → keep as String?
      // (you can add DateTime getters later if needed)
      emailVerifiedAt: JsonParser.string(json['email_verified_at']),
      createdAt: JsonParser.string(json['created_at']),
      updatedAt: JsonParser.string(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {};

    map['id'] = id;
    map['name'] = name;
    map['email'] = email;
    map['mobile'] = mobile;
    map['country'] = country;
    map['iso_2'] = iso2;
    map['wallet_balance'] = walletBalance;
    map['referral_code'] = referralCode;
    map['friends_code'] = friendsCode;
    map['reward_points'] = rewardPoints;
    map['profile_image'] = profileImage;
    map['email_verified_at'] = emailVerifiedAt;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;

    return map;
  }

  // Optional: nice computed getters if you later want DateTime
  DateTime? get createdAtDate => JsonParser.dateTimeValue(createdAt);
  DateTime? get updatedAtDate => JsonParser.dateTimeValue(updatedAt);
  DateTime? get emailVerifiedAtDate => JsonParser.dateTimeValue(emailVerifiedAt);
}