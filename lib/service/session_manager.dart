import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local_seller/utils/auth_log.dart';
import 'package:hyper_local_seller/config/global_keys.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/router/app_routes.dart';
import 'package:hyper_local_seller/service/master_api_service.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';

/// Handles an expired/invalid auth token (HTTP 401) or a withdrawn system-user
/// login approval (HTTP 403) globally: clears the stored session, resets every
/// BLoC and sends the user to login.
class SessionManager {
  static bool _isHandling = false;

  /// True for the 403 body the approval middleware returns once a system
  /// user's approval has expired or been disapproved. Other 403s (e.g. a
  /// missing permission) must not log the user out.
  static bool isLoginApprovalError(dynamic body) {
    if (body is! Map) return false;
    final data = body['data'];
    return data is Map && data['login_approval_status'] != null;
  }

  static Future<void> handleUnauthorized({String? message}) async {
    // Several requests can fail with 401 at once — only react to the first.
    if (_isHandling) return;
    final token = HiveStorage.userToken;
    if (token == null || token.trim().isEmpty) return;

    _isHandling = true;
    try {
      authLog(
        'session rejected by server → forced logout'
        '${message != null ? ' ($message)' : ''}',
      );
      await HiveStorage.clearAll();

      final context = GlobalKeys.navigatorKey.currentContext;
      if (context != null && context.mounted) {
        MasterApiService.clearAllApisData(context);
        context.go(AppRoutes.login);
        if (message != null && message.isNotEmpty) {
          showCustomSnackbar(context: context, message: message, isError: true);
        }
      }
    } finally {
      _isHandling = false;
    }
  }
}
