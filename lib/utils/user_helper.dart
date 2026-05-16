
import 'package:hyper_local_seller/config/hive_storage.dart';

class UserHelper {
  static Map<dynamic, dynamic>? get _userData => HiveStorage.userData;

  static String get name => _userData?['name'] ?? 'Guest';
  
  static String get email => _userData?['email'] ?? '';
  
  static String get mobile => _userData?['mobile']?.toString() ?? '';
  
  static String get profileImage => _userData?['profile_image'] ?? '';
  
  static int get id => _userData?['id'] ?? 0;
  
  static String get walletBalance => _userData?['wallet_balance']?.toString() ?? '0.00';
  
  static bool get isLoggedIn => HiveStorage.fcmToken != null || HiveStorage.userToken != null;
}
