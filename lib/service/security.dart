import 'package:hyper_local_seller/config/hive_storage.dart';

class Security {
  static Future<Map<String, String>> get headers async {
    String? token = HiveStorage.userToken;

    final Map<String, String> headers = {
      "Accept": "application/json",
    };

    if (token != null && token.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }
}
