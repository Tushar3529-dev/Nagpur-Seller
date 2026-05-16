import 'package:hyper_local_seller/service/json_parser.dart';

const String modelName = 'roles_model';

class RolesResponse {
  bool? success;
  String? message;
  RolesPageData? data;

  RolesResponse({this.success, this.message, this.data});

  factory RolesResponse.fromJson(Map<String, dynamic> json) {
    return RolesResponse(
      success: JsonParser.boolValue(json['success'] ?? false),
      message: JsonParser.string(json['message'] ?? ''),
      data: json['data'] != null
          ? RolesPageData.fromJson(json['data'] as Map<String, dynamic>)
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

class RolesPageData {
  int? currentPage;
  int? lastPage;
  int? perPage;
  int? total;
  String? firstPageUrl;
  int? from;
  String? lastPageUrl;
  String? nextPageUrl;
  String? path;
  String? prevPageUrl;
  int? to;
  List<Role>? roles;
  List<PaginationLink>? links;

  RolesPageData({
    this.currentPage,
    this.lastPage,
    this.perPage,
    this.total,
    this.firstPageUrl,
    this.from,
    this.lastPageUrl,
    this.nextPageUrl,
    this.path,
    this.prevPageUrl,
    this.to,
    this.roles,
    this.links,
  });

  factory RolesPageData.fromJson(Map<String, dynamic> json) {
    return RolesPageData(
      currentPage: JsonParser.intValue(json['current_page'] ?? 1),
      lastPage: JsonParser.intValue(json['last_page'] ?? 1),
      perPage: JsonParser.intValue(json['per_page'] ?? 15),
      total: JsonParser.intValue(json['total'] ?? 0),
      firstPageUrl: JsonParser.string(json['first_page_url']),
      from: JsonParser.intValue(json['from']),
      lastPageUrl: JsonParser.string(json['last_page_url']),
      nextPageUrl: JsonParser.string(json['next_page_url']),
      path: JsonParser.string(json['path']),
      prevPageUrl: JsonParser.string(json['prev_page_url']),
      to: JsonParser.intValue(json['to']),

      roles: JsonParser.list<Role>(
        json['data'],
            (v) => Role.fromJson(v as Map<String, dynamic>),
      ),

      links: JsonParser.list<PaginationLink>(
        json['links'],
            (v) => PaginationLink.fromJson(v as Map<String, dynamic>),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['current_page'] = currentPage;
    data['last_page'] = lastPage;
    data['per_page'] = perPage;
    data['total'] = total;
    data['first_page_url'] = firstPageUrl;
    data['from'] = from;
    data['last_page_url'] = lastPageUrl;
    data['next_page_url'] = nextPageUrl;
    data['path'] = path;
    data['prev_page_url'] = prevPageUrl;
    data['to'] = to;
    if (roles != null) {
      data['data'] = roles!.map((v) => v.toJson()).toList();
    }
    if (links != null) {
      data['links'] = links!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Role {
  int id;
  int? teamId;
  String name;
  String guardName;
  String? createdAt;
  String? updatedAt;

  Role({
    required this.id,
    this.teamId,
    required this.name,
    required this.guardName,
    this.createdAt,
    this.updatedAt,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: JsonParser.requireInt(json['id'], model: modelName, field: 'id'),
      teamId: JsonParser.intValue(json['team_id']),
      name: JsonParser.requireString(
        json['name'],
        model: modelName,
        field: 'name',
      ),
      guardName: JsonParser.requireString(
        json['guard_name'],
        model: modelName,
        field: 'guard_name',
      ),
      createdAt: JsonParser.string(json['created_at'] ?? ''),
      updatedAt: JsonParser.string(json['updated_at'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['team_id'] = teamId;
    data['name'] = name;
    data['guard_name'] = guardName;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}

class PaginationLink {
  String? url;
  String label;
  int? page;
  bool active;

  PaginationLink({
    this.url,
    required this.label,
    this.page,
    required this.active,
  });

  factory PaginationLink.fromJson(Map<String, dynamic> json) {
    return PaginationLink(
      url: JsonParser.string(json['url']),
      label: JsonParser.requireString(
        json['label'],
        model: modelName,
        field: 'links[].label',
      ),
      page: JsonParser.intValue(json['page']),
      active: JsonParser.boolValue(json['active'] ?? false),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['url'] = url;
    data['label'] = label;
    data['page'] = page;
    data['active'] = active;
    return data;
  }
}