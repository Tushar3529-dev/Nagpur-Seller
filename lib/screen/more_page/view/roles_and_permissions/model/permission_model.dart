import 'package:hyper_local_seller/service/json_parser.dart';

const String modelName = 'seller_permissions_model';

class SellerPermissionsResponse {
  bool? success;
  String? message;
  SellerPermissionsData? data;

  SellerPermissionsResponse({this.success, this.message, this.data});

  factory SellerPermissionsResponse.fromJson(Map<String, dynamic> json) {
    return SellerPermissionsResponse(
      success: JsonParser.boolValue(json['success'] ?? false),
      message: JsonParser.string(json['message'] ?? ''),
      data: json['data'] != null
          ? SellerPermissionsData.fromJson(json['data'] as Map<String, dynamic>)
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

class SellerPermissionsData {
  RoleBasic? role;
  GroupedPermissions? groupedPermissions;
  List<String> assigned;

  SellerPermissionsData({
    this.role,
    this.groupedPermissions,
    this.assigned = const [],
  });

  factory SellerPermissionsData.fromJson(Map<String, dynamic> json) {
    return SellerPermissionsData(
      role: json['role'] != null
          ? RoleBasic.fromJson(json['role'] as Map<String, dynamic>)
          : null,
      groupedPermissions: json['grouped_permissions'] != null
          ? GroupedPermissions.fromJson(
              json['grouped_permissions'] as Map<String, dynamic>,
            )
          : null,
      assigned: JsonParser.list<String>(
        json['assigned'],
        (v) => JsonParser.string(v),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (role != null) data['role'] = role!.toJson();
    if (groupedPermissions != null) {
      data['grouped_permissions'] = groupedPermissions!.toJson();
    }
    data['assigned'] = assigned;
    return data;
  }
}

class RoleBasic {
  int id;
  String name;

  RoleBasic({required this.id, required this.name});

  factory RoleBasic.fromJson(Map<String, dynamic> json) {
    return RoleBasic(
      id: JsonParser.requireInt(json['id'], model: modelName, field: 'role.id'),
      name: JsonParser.requireString(
        json['name'],
        model: modelName,
        field: 'role.name',
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

class GroupedPermissions {
  PermissionGroup? dashboard;
  PermissionGroup? wallet;
  PermissionGroup? withdrawal;
  PermissionGroup? earning;
  PermissionGroup? order;
  PermissionGroup? returns;
  PermissionGroup? category;
  PermissionGroup? brand;
  PermissionGroup? attribute;
  PermissionGroup? product;
  PermissionGroup? productFaq;
  PermissionGroup? taxRate;
  PermissionGroup? store;
  PermissionGroup? notification;
  PermissionGroup? role;
  PermissionGroup? permission;
  PermissionGroup? systemUser;
  PermissionGroup? subscription;

  GroupedPermissions({
    this.dashboard,
    this.wallet,
    this.withdrawal,
    this.earning,
    this.order,
    this.returns,
    this.category,
    this.brand,
    this.attribute,
    this.product,
    this.productFaq,
    this.taxRate,
    this.store,
    this.notification,
    this.role,
    this.permission,
    this.systemUser,
    this.subscription,
  });

  factory GroupedPermissions.fromJson(Map<String, dynamic> json) {
    return GroupedPermissions(
      dashboard: _parseGroup(json['dashboard']),
      wallet: _parseGroup(json['wallet']),
      withdrawal: _parseGroup(json['withdrawal']),
      earning: _parseGroup(json['earning']),
      order: _parseGroup(json['order']),
      returns: _parseGroup(json['return']),
      category: _parseGroup(json['category']),
      brand: _parseGroup(json['brand']),
      attribute: _parseGroup(json['attribute']),
      product: _parseGroup(json['product']),
      productFaq: _parseGroup(json['product_faq']),
      taxRate: _parseGroup(json['tax_rate']),
      store: _parseGroup(json['store']),
      notification: _parseGroup(json['notification']),
      role: _parseGroup(json['role']),
      permission: _parseGroup(json['permission']),
      systemUser: _parseGroup(json['system_user']),
      subscription: _parseGroup(json['subscription']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    _addIfNotNull(data, 'dashboard', dashboard);
    _addIfNotNull(data, 'wallet', wallet);
    _addIfNotNull(data, 'withdrawal', withdrawal);
    _addIfNotNull(data, 'earning', earning);
    _addIfNotNull(data, 'order', order);
    _addIfNotNull(data, 'return', returns);
    _addIfNotNull(data, 'category', category);
    _addIfNotNull(data, 'brand', brand);
    _addIfNotNull(data, 'attribute', attribute);
    _addIfNotNull(data, 'product', product);
    _addIfNotNull(data, 'product_faq', productFaq);
    _addIfNotNull(data, 'tax_rate', taxRate);
    _addIfNotNull(data, 'store', store);
    _addIfNotNull(data, 'notification', notification);
    _addIfNotNull(data, 'role', role);
    _addIfNotNull(data, 'permission', permission);
    _addIfNotNull(data, 'system_user', systemUser);
    _addIfNotNull(data, 'subscription', subscription);
    return data;
  }

  static PermissionGroup? _parseGroup(dynamic value) {
    if (value == null || value is! Map<String, dynamic>) return null;
    return PermissionGroup.fromJson(value);
  }

  static void _addIfNotNull(
    Map<String, dynamic> map,
    String key,
    PermissionGroup? group,
  ) {
    if (group != null) {
      map[key] = group.toJson();
    }
  }
}

class PermissionGroup {
  String name;
  List<String> permissions;

  PermissionGroup({required this.name, this.permissions = const []});

  factory PermissionGroup.fromJson(Map<String, dynamic> json) {
    return PermissionGroup(
      name: JsonParser.string(json['name'] ?? ''),
      permissions: JsonParser.list<String>(
        json['permissions'],
        (v) => JsonParser.string(v),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['permissions'] = permissions;
    return data;
  }
}
