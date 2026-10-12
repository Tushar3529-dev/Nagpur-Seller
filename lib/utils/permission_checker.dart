import 'package:flutter/foundation.dart';
import 'package:hyper_local_seller/config/app_permissions.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';

class PermissionChecker {
  /// Name of the store owner's role. It keeps the incoming-order popup even
  /// without `order.popup` assigned.
  static const String defaultSellerRole = 'seller';

  /// Checks if the current user has the specified permission.
  /// It reads from `HiveStorage.userData` which contains the latest
  /// `assigned` permissions array from the login/profile API.
  static bool hasPermission(String permissionName) {
    if (permissionName.isEmpty) return true;

    final assignedPermissions = _assignedPermissions;
    if (assignedPermissions == null) return false;
    debugPrint('ASSIGNED PERMISSIONS :::: $assignedPermissions');
    return assignedPermissions.contains(permissionName);
  }

  static List<String>? get _assignedPermissions {
    try {
      final userData = HiveStorage.userData;

      if (userData == null || !userData.containsKey('assigned_permissions')) {
        return null;
      }

      return List<String>.from(userData['assigned_permissions'] as List);
    } catch (e) {
      // Return null in case of parsing error to prevent unhandled access
      return null;
    }
  }

  /// Role names of the current user, lowercased, read from the `role` or
  /// `roles` field of the login/profile user data (a name, a `{name}` map, or
  /// a list of either). Null when the user data carries no role at all.
  static Set<String>? get roleNames {
    final userData = HiveStorage.userData;
    if (userData == null) return null;
    final raw = userData['roles'] ?? userData['role'];
    if (raw == null) return null;

    String? nameOf(dynamic value) {
      if (value is Map) value = value['name'];
      final name = value?.toString().trim().toLowerCase();
      return name == null || name.isEmpty ? null : name;
    }

    final names = raw is List ? raw.map(nameOf) : [nameOf(raw)];
    return names.whereType<String>().toSet();
  }

  /// True for the store owner's default seller role. False when the user data
  /// carries no role (the login/profile APIs don't send one today); the
  /// owner's assigned list includes `order.popup` anyway.
  static bool get isDefaultSeller =>
      roleNames?.contains(defaultSellerRole) ?? false;

  /// Whether the incoming-order popup may be shown and its pending-orders
  /// endpoint polled.
  static bool get canShowOrderPopup =>
      isDefaultSeller || hasPermission(AppPermissions.orderPopup);
}
