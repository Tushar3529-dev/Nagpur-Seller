import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local_seller/config/global_keys.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/router/app_routes.dart';
import 'package:hyper_local_seller/service/master_api_service.dart';

/// Handles an expired/invalid auth token (HTTP 401) globally:
/// clears the stored session, resets every BLoC and sends the user to login.
class SessionManager {
  static bool _isHandling = false;

  static Future<void> handleUnauthorized() async {
    // Several requests can fail with 401 at once — only react to the first.
    if (_isHandling) return;
    final token = HiveStorage.userToken;
    if (token == null || token.trim().isEmpty) return;

    _isHandling = true;
    try {
      debugPrint('[SessionManager] 401 received — logging out');
      await HiveStorage.clearAll();

      final context = GlobalKeys.navigatorKey.currentContext;
      if (context != null && context.mounted) {
        MasterApiService.clearAllApisData(context);
        context.go(AppRoutes.login);
      }
    } finally {
      _isHandling = false;
    }
  }
}
