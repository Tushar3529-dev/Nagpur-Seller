import 'package:flutter/foundation.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';

class PermissionChecker {
  /// Checks if the current user has the specified permission.
  /// It reads from `HiveStorage.userData` which contains the latest
  /// `assigned` permissions array from the login/profile API.
  static bool hasPermission(String permissionName) {
    if (permissionName.isEmpty) return true;

    try {
      final userData = HiveStorage.userData;

      if (userData == null || !userData.containsKey('assigned_permissions')) {
        return false;
      }

      final assignedPermissions = List<String>.from(userData['assigned_permissions'] as List);
      debugPrint('ASSIGNED PERMISSIONS :::: $assignedPermissions');
      return assignedPermissions.contains(permissionName);
    } catch (e) {
      // Return false in case of parsing error to prevent unhandled access
      return false;
    }
  }
}
