import 'package:flutter/foundation.dart';

/// Debug-console trace of the login flow, prefixed `[Auth]`. Prints only in
/// debug builds. Never pass passwords or OTPs; pass tokens through [mask].
void authLog(String message) {
  if (kDebugMode) debugPrint('[Auth] $message');
}

/// First characters of a secret, enough to tell tokens apart in logs.
String mask(String? secret) {
  if (secret == null || secret.isEmpty) return '<none>';
  return secret.length <= 8
      ? '***'
      : '${secret.substring(0, 6)}…(${secret.length} chars)';
}
