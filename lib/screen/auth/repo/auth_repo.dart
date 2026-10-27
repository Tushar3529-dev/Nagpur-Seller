// ignore_for_file: unused_local_variable

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:hyper_local_seller/config/api_routes.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';
import 'package:hyper_local_seller/service/popup_presence_service.dart';
import 'package:hyper_local_seller/utils/auth_log.dart';

/// Thrown by [AuthRepository.login] when a seller-created system user signs in
/// with valid credentials but the seller has not approved the login yet.
/// No access token is issued in this case.
class LoginApprovalPendingException implements Exception {
  final String message;
  final DateTime? requestedAt;

  LoginApprovalPendingException(this.message, {this.requestedAt});

  @override
  String toString() => message;
}

class AuthRepository {
  final ApiBaseHelper _helper = ApiBaseHelper();

  Future<dynamic> login({
    required String email,
    required String password,
  }) async {
    try {
      // Either email or mobile identifies the user; this form uses email.
      final body = {
        "email": email,
        "password": password,
        ..._deviceFields,
      };
      authLog(
        'login → POST ${ApiRoutes.loginApi} email=$email '
        'fcm_token=${mask(HiveStorage.fcmToken)} '
        'device_type=${body['device_type']}',
      );

      final responseData = await _helper.post(ApiRoutes.loginApi, body);
      authLog('login ← success: ${responseData is Map ? responseData['message'] : responseData}');

      await _extractAndSaveToken(responseData);

      return responseData;
    } on ApiException catch (e) {
      authLog(
        'login ✗ HTTP ${e.statusCode ?? '-'}: ${e.message} '
        'data=${e.responseData?['data']}',
      );
      // HTTP 403 with `login_approval_status: pending` means the credentials
      // are valid but the seller still has to approve this system user.
      // Disapproved/expired and every other failure surface as plain errors.
      final data = e.responseData?['data'];
      if (e.statusCode == 403 &&
          data is Map &&
          data['login_approval_status'] == 'pending') {
        authLog('login → approval pending; showing "Waiting for seller approval"');
        throw LoginApprovalPendingException(
          e.message,
          requestedAt: DateTime.tryParse(
            data['approval_requested_at']?.toString() ?? '',
          )?.toLocal(),
        );
      }
      rethrow;
    }
  }

  Future<dynamic> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String address,
    required String city,
    required String state,
    required String landmark,
    required String zipcode,
    required String country,
    required String latitude,
    required String longitude,
    required String businessLicensePath,
    required String articlesOfIncorporationPath,
    required String nationalIdCardPath,
    required String authorizedSignaturePath,
  }) async {
    try {
      final Map<String, dynamic> fields = {
        "name": name,
        "email": email,
        "mobile": phone,
        "password": password,
        "user_id": "",
        "address": address,
        "city": city,
        "state": state,
        "landmark": landmark,
        "zipcode": zipcode,
        "country": country,
        "latitude": latitude,
        "longitude": longitude,
        "verification_status": "approved",
        "visibility_status": "visible",
        ..._deviceFields,
      };

      final Map<String, dynamic> files = {
        "business_license": businessLicensePath.isNotEmpty
            ? await MultipartFile.fromFile(businessLicensePath)
            : null,
        "articles_of_incorporation": articlesOfIncorporationPath.isNotEmpty
            ? await MultipartFile.fromFile(articlesOfIncorporationPath)
            : null,
        "national_identity_card": nationalIdCardPath.isNotEmpty
            ? await MultipartFile.fromFile(nationalIdCardPath)
            : null,
        "authorized_signature": authorizedSignaturePath.isNotEmpty
            ? await MultipartFile.fromFile(authorizedSignaturePath)
            : null,
      };

      // Remove null files
      files.removeWhere((key, value) => value == null);

      final formData = FormData.fromMap({...fields, ...files});

      for (var field in formData.fields) {}

      for (var file in formData.files) {}

      final responseData = await _helper.postMultipart(
        ApiRoutes.registerApi,
        formData,
      );

      await _extractAndSaveToken(responseData);

      return responseData;
    } catch (e) {
      rethrow;
    }
  }

  /// Push token and platform, both optional. A missing token is left out
  /// rather than sent as the string "null".
  static Map<String, String> get _deviceFields => {
    if (HiveStorage.fcmToken case final token? when token.isNotEmpty)
      'fcm_token': token,
    'device_type': Platform.isAndroid ? 'android' : 'ios',
  };

  Future<void> logout() async {
    try {
      // Logout doesn't clear popup presence, so end it while the token
      // still works; otherwise orders keep being offered until it's stale.
      authLog('logout → presence off, POST ${ApiRoutes.logoutApi}');
      await PopupPresenceService().stop();
      await _helper.post(ApiRoutes.logoutApi, null);
      authLog('logout ← server done');
    } catch (e) {
      // Ignore logout errors
      authLog('logout ✗ server call failed (ignored): $e');
    } finally {
      await HiveStorage.clearAll();
      authLog('logout → local session cleared');
    }
  }

  Future<dynamic> forgotPassword(String email) async {
    try {
      final body = {"email": email};

      final responseData = await _helper.post(
        ApiRoutes.forgetPasswordApi,
        body,
      );

      return responseData;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _extractAndSaveToken(dynamic data) async {
    if (data is! Map<String, dynamic>) {
      authLog('save ✗ response is not a JSON object; nothing saved');
      return;
    }
    {
      final user = data['data'];
      authLog(
        'save → access_token=${mask(data['access_token']?.toString() ?? data['token']?.toString())} '
        'user_id=${user is Map ? user['id'] : '-'} '
        'name=${user is Map ? user['name'] : '-'} '
        'permissions=${(data['assigned_permissions'] as List?)?.length ?? 0}',
      );
      // Save Access Token
      if (data.containsKey('access_token')) {
        await HiveStorage.setAccessToken(data['access_token'].toString());
      }

      // Save User Data
      if (data.containsKey('data') && data['data'] is Map) {
        final Map<dynamic, dynamic> userDataToSave = Map.from(data['data']);
        
        // Inject assigned permissions into the userData map
        if (data.containsKey('assigned_permissions')) {
           userDataToSave['assigned_permissions'] = data['assigned_permissions'];
        }
        
        await HiveStorage.setUserData(userDataToSave);
      }

      // Legacy fallback (optional, but good for safety if API varies)
      if (data.containsKey('token')) {
        await HiveStorage.setAccessToken(data['token'].toString());
      }
    }
  }

  Future<dynamic> phoneCallback({required String idToken}) async {
    try {
      final body = {
        "idToken": idToken,
        ..._deviceFields,
      };

      authLog(
        'phone callback → POST ${ApiRoutes.callbackApi} '
        'idToken=${mask(idToken)}',
      );
      final responseData = await _helper.post(ApiRoutes.callbackApi, body);
      authLog('phone callback ← success');

      await _extractAndSaveToken(responseData);

      return responseData;
    } catch (e) {
      authLog('phone callback ✗ $e');
      rethrow;
    }
  }

  Future<dynamic> verifyUser(String type, String value) async {
    try {
      final body = {"type": type, "value": value};

      final responseData = await _helper.post(ApiRoutes.verifyUserApi, body);

      return responseData;
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> customSendOtp({required String phone}) async {
    try {
      final body = {"mobile": phone};
      authLog('custom OTP send → POST ${ApiRoutes.customSendOtpApi} mobile=$phone');
      final responseData = await _helper.post(ApiRoutes.customSendOtpApi, body);
      authLog('custom OTP send ← ${responseData is Map ? 'success=${responseData['success']} ${responseData['message']}' : responseData}');
      return responseData;
    } catch (e) {
      authLog('custom OTP send ✗ $e');
      rethrow;
    }
  }

  Future<dynamic> customVerifyOtp({
    required String phone,
    required String otp,
  }) async {
    try {
      final body = {
        "mobile": phone,
        "otp": otp,
        ..._deviceFields,
      };
      authLog('custom OTP verify → POST ${ApiRoutes.customVerifyOtpApi} mobile=$phone');
      final responseData = await _helper.post(ApiRoutes.customVerifyOtpApi, body);
      authLog('custom OTP verify ← ${responseData is Map ? 'success=${responseData['success']} ${responseData['message']}' : responseData}');
      await _extractAndSaveToken(responseData);
      return responseData;
    } catch (e) {
      authLog('custom OTP verify ✗ $e');
      rethrow;
    }
  }
}
