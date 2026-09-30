import 'package:hyper_local_seller/config/api_routes.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';

class PermissionsRepo {
  final ApiBaseHelper _helper = ApiBaseHelper();

  Future<dynamic> getSellerPermissions(String role) async {
    try {
      final response = await _helper.get('${ApiRoutes.permissionsApi}/$role');

      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<dynamic> syncSellerPermissions(Map<String, dynamic> data) async {
    try {
      final response = await _helper.post(ApiRoutes.permissionsApi, data);

      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
