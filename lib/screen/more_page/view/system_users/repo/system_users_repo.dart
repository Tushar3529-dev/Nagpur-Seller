import 'package:hyper_local_seller/config/api_routes.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';

class SystemUsersRepo {
  final ApiBaseHelper _helper = ApiBaseHelper();

  Future<dynamic> getSystemUsers({
    int? page,
    int? perPage,
    String? search,
  }) async {
    try {
      final queryParameters = {
        if (page != null) 'page': page.toString(),
        if (perPage != null) 'per_page': perPage.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final response = await _helper.get(
        ApiRoutes.systemUsersApi,
        queryParameters: queryParameters,
      );

      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<dynamic> getSystemUserById(int id) async {
    try {
      final response = await _helper.get('${ApiRoutes.systemUsersApi}/$id');
      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<dynamic> manageSystemUser(Map<String, dynamic> data) async {
    try {
      dynamic response;

      if (data['id'] != null) {
        response = await _helper.post(
          '${ApiRoutes.systemUsersApi}/${data['id']}',
          data,
        );
      } else {
        response = await _helper.post(ApiRoutes.systemUsersApi, data);
      }

      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<dynamic> deleteSystemUser(int id) async {
    try {
      final response = await _helper.delete('${ApiRoutes.systemUsersApi}/$id');

      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
