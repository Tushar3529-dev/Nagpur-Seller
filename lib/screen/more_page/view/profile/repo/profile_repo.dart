import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:hyper_local_seller/config/api_routes.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';

class ProfileRepo {
  final ApiBaseHelper _helper = ApiBaseHelper();

  Future<dynamic> getUserProfile() async {
    try {
      final response = await _helper.get(ApiRoutes.updateUserApi);

      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<dynamic> updateProfile({
    String? userName,
    String? profileImagePath,
  }) async {
    try {
      final Map<String, dynamic> fields = {};

      if (userName != null && userName.isNotEmpty) {
        fields['name'] = userName;
      }

      if (profileImagePath != null && profileImagePath.isNotEmpty) {
        fields['profile_image'] = await MultipartFile.fromFile(
          profileImagePath,
        );
      }

      final formData = FormData.fromMap(fields);
      log('wefdshkh ::::::: $formData');
      final response = await _helper.postMultipart(
        ApiRoutes.updateUserApi,
        formData,
      );

      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<dynamic> changePassword(
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    try {
      final response = await _helper.post(ApiRoutes.changePasswordApi, {
        'current_password': currentPassword,
        'password': newPassword,
        'password_confirmation': confirmPassword,
      });
      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
