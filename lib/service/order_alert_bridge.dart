import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Dart side of the native new-order alert (Android only; see
/// `android/.../orderalert/`). Same approach as the rider app.
///
/// A new-order push starts ringing natively, even while the app is closed or
/// swiped away. While the app is open, [sync] adds its unaccepted orders.
/// Ringing for an order stops only when the seller accepts it, or when it is
/// reassigned to another seller (a reassign push, or the server's pending
/// list no longer having it).
///
/// Every call is a no-op off Android and in isolates without the channel.
class OrderAlertBridge {
  OrderAlertBridge._();

  static const _channel = MethodChannel('com.nagpurmart.seller/order_alert');

  static bool get isSupported => !kIsWeb && Platform.isAndroid;

  /// Alerts only ring while someone who gets incoming orders is logged in.
  static Future<void> setLoggedIn(bool loggedIn) =>
      _invoke('setLoggedIn', {'loggedIn': loggedIn});

  /// [alerts] ring (if not ringing already); [acceptedIds] stop. Pass
  /// [serverIds] right after a fetch: every order the server still offers
  /// this seller. Ringing orders missing from it were reassigned and stop.
  static Future<void> sync(
    List<OrderAlertEntry> alerts, {
    required Iterable<int> acceptedIds,
    Iterable<int>? serverIds,
  }) => _invoke('sync', {
    'alerts': [
      for (final alert in alerts)
        {'orderId': alert.orderId, 'title': alert.title, 'body': alert.body},
    ],
    'acceptedIds': [for (final id in acceptedIds) id.toString()],
    if (serverIds != null)
      'serverIds': [for (final id in serverIds) id.toString()],
  });

  static Future<void> _invoke(String method, [Object? arguments]) async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } on MissingPluginException {
      return;
    } catch (e) {
      debugPrint('[OrderAlert] $method failed: $e');
    }
  }
}

class OrderAlertEntry {
  final String orderId;
  final String title;
  final String body;

  const OrderAlertEntry({
    required this.orderId,
    required this.title,
    required this.body,
  });
}
