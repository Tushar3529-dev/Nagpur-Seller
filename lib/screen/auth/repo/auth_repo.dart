// ignore_for_file: unused_local_variable

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:hyper_local_seller/config/api_routes.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';

class AuthRepository {
  final ApiBaseHelper _helper = ApiBaseHelper();

  Future<dynamic> login({
    required String email,
    required String password,
  }) async {
    try {
      final body = {
        "email": email,
        "password": password,
        "mobile": 0,
        "fcm_token": HiveStorage.fcmToken.toString(),
        "device_type": Platform.isAndroid ? 'android' : 'ios',
      };

      final responseData = await _helper.post(ApiRoutes.loginApi, body);

      await _extractAndSaveToken(responseData);

      return responseData;
    } catch (e) {
      throw Exception(e.toString());
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
        "fcm_token": HiveStorage.fcmToken.toString(),
        "device_type": Platform.isAndroid ? 'android' : 'ios',
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
      throw Exception(e.toString());
    }
  }

  Future<void> logout() async {
    try {
      await _helper.post(ApiRoutes.logoutApi, {});
    } catch (_) {
      // Ignore logout errors
    } finally {
      await HiveStorage.clearAll();
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
      throw Exception(e.toString());
    }
  }

  Future<void> _extractAndSaveToken(dynamic data) async {
    if (data is Map<String, dynamic>) {
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
        "fcm_token": HiveStorage.fcmToken.toString(),
        "device_type": Platform.isAndroid ? 'android' : 'ios',
      };

      final responseData = await _helper.post(ApiRoutes.callbackApi, body);

      await _extractAndSaveToken(responseData);

      return responseData;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<dynamic> verifyUser(String type, String value) async {
    try {
      final body = {"type": type, "value": value};

      final responseData = await _helper.post(ApiRoutes.verifyUserApi, body);

      return responseData;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<dynamic> customSendOtp({required String phone}) async {
    try {
      final body = {"mobile": phone};
      final responseData = await _helper.post(ApiRoutes.customSendOtpApi, body);
      return responseData;
    } catch (e) {
      throw Exception(e.toString());
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
        "fcm_token": HiveStorage.fcmToken.toString(),
        "device_type": Platform.isAndroid ? 'android' : 'ios',
      };
      final responseData = await _helper.post(ApiRoutes.customVerifyOtpApi, body);
      await _extractAndSaveToken(responseData);
      return responseData;
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
