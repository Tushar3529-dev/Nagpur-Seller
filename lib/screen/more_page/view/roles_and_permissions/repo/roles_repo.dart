import 'package:dio/dio.dart';
import 'package:hyper_local_seller/config/api_routes.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';

class RolesRepo {
  final ApiBaseHelper _helper = ApiBaseHelper();

  Future<dynamic> getRoles({int? page, int? perPage, String? search}) async {
    try {
      final queryParameters = {
        if (page != null) 'page': page.toString(),
        if (perPage != null) 'per_page': perPage.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final response = await _helper.get(
        ApiRoutes.rolesApi,
        queryParameters: queryParameters,
      );

      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<dynamic> manageRole(String name, int? id) async {
    try {
      final Map<String, dynamic> data = {
        'name': name,
      };

      if (id == null) {
        // CREATE
        final response = await _helper.post(ApiRoutes.rolesApi, data);
        return response;
      } else {
        // UPDATE
        final response = await _helper.post(
          '${ApiRoutes.rolesApi}/$id',
          data,
        );
        return response;
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }


  Future<dynamic> deleteRole(int id) async {
    try {
      final response = await _helper.delete('${ApiRoutes.rolesApi}/$id');

      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<dynamic> getRolesList({String? search}) async {
    try {
      final queryParameters = {
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final response = await _helper.get(
        ApiRoutes.rolesListApi,
        queryParameters: queryParameters,
      );

      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
