import 'package:hyper_local_seller/service/json_parser.dart';

const String modelName = 'eligibility_model';

class EligibilityResponse {
  bool? success;
  String? message;
  EligibilityData? data;

  EligibilityResponse({this.success, this.message, this.data});

  factory EligibilityResponse.fromJson(Map<String, dynamic> json) {
    return EligibilityResponse(
      success: JsonParser.boolValue(json['success'] ?? false),
      message: JsonParser.string(json['message'] ?? ''),
      data: json['data'] != null
          ? EligibilityData.fromJson(json['data'] as Map<String, dynamic>)
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

class EligibilityData {
  bool eligible;
  EligibilityDetails? details;
  List<String>? failingKeys;

  EligibilityData({required this.eligible, this.details, this.failingKeys});

  factory EligibilityData.fromJson(Map<String, dynamic> json) {
    return EligibilityData(
      eligible: JsonParser.boolValue(json['eligible'] ?? false),

      details: json['details'] != null
          ? EligibilityDetails.fromJson(json['details'] as Map<String, dynamic>)
          : null,

      failingKeys: JsonParser.list<String>(
        json['failing_keys'],
        (v) => JsonParser.string(v),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['eligible'] = eligible;
    if (details != null) data['details'] = details!.toJson();
    data['failing_keys'] = failingKeys;
    return data;
  }
}

class EligibilityDetails {
  LimitCheck? storeLimit;
  LimitCheck? productLimit;
  LimitCheck? roleLimit;
  LimitCheck? systemUserLimit;

  EligibilityDetails({
    this.storeLimit,
    this.productLimit,
    this.roleLimit,
    this.systemUserLimit,
  });

  factory EligibilityDetails.fromJson(Map<String, dynamic> json) {
    return EligibilityDetails(
      storeLimit: _parseLimit(json['store_limit']),
      productLimit: _parseLimit(json['product_limit']),
      roleLimit: _parseLimit(json['role_limit']),
      systemUserLimit: _parseLimit(json['system_user_limit']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    _addIfNotNull(data, 'store_limit', storeLimit);
    _addIfNotNull(data, 'product_limit', productLimit);
    _addIfNotNull(data, 'role_limit', roleLimit);
    _addIfNotNull(data, 'system_user_limit', systemUserLimit);
    return data;
  }

  static LimitCheck? _parseLimit(dynamic value) {
    if (value == null || value is! Map<String, dynamic>) return null;
    return LimitCheck.fromJson(value);
  }

  static void _addIfNotNull(
    Map<String, dynamic> map,
    String key,
    LimitCheck? limit,
  ) {
    if (limit != null) {
      map[key] = limit.toJson();
    }
  }
}

class LimitCheck {
  int used;
  int limit;
  int remaining;
  bool ok;

  LimitCheck({
    required this.used,
    required this.limit,
    required this.remaining,
    required this.ok,
  });

  factory LimitCheck.fromJson(Map<String, dynamic> json) {
    return LimitCheck(
      used: JsonParser.intValue(json['used'] ?? 0),
      limit: JsonParser.intValue(json['limit'] ?? 0),
      remaining: JsonParser.intValue(json['remaining'] ?? 0),
      ok: JsonParser.boolValue(json['ok'] ?? false),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['used'] = used;
    data['limit'] = limit;
    data['remaining'] = remaining;
    data['ok'] = ok;
    return data;
  }
}
