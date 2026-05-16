import 'package:hyper_local_seller/service/json_parser.dart';

const String modelName = 'roles_list_model';

class RolesListResponse {
  bool? success;
  String? message;
  List<Role>? roles;

  RolesListResponse({
    this.success,
    this.message,
    this.roles,
  });

  factory RolesListResponse.fromJson(Map<String, dynamic> json) {
    return RolesListResponse(
      success: JsonParser.boolValue(json['success'] ?? false),
      message: JsonParser.string(json['message'] ?? ''),
      roles: JsonParser.list<Role>(
        json['data'],
            (v) => Role.fromJson(v as Map<String, dynamic>),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    if (roles != null) {
      data['data'] = roles!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Role {
  int id;
  String name;

  Role({
    required this.id,
    required this.name,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
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
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    return data;
  }
}