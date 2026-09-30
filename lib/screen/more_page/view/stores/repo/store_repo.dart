import 'package:hyper_local_seller/config/api_routes.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';

class StoresRepo {
  final ApiBaseHelper _helper = ApiBaseHelper();

  Future<dynamic> getStores({
    int? page,
    int? perPage,
    String? search,
    String? status,
    String? visibilityStatus,
    String? verificationStatus,
  }) async {
    try {
      final queryParameters = {
        if (page != null) 'page': page.toString(),
        if (perPage != null) 'per_page': perPage.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null) 'status': status,
        if (visibilityStatus != null) 'visibility_status': visibilityStatus,
        if (verificationStatus != null) 'verification_status': verificationStatus,
      };

      final response = await _helper.get(ApiRoutes.storesApi, queryParameters: queryParameters);

      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<dynamic> getStoreFilters() async {
    try {
      final response = await _helper.get(ApiRoutes.storesEnumsApi);
      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<dynamic> deleteStore(int storeId) async {
    try {
      final responseData = await _helper.delete(
        '${ApiRoutes.storesApi}/$storeId',
      );
      return responseData;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<dynamic> updateStoreStatus(int storeId, String status) async {
    try {
      final responseData = await _helper.post(
        '${ApiRoutes.storesApi}/$storeId/status',
        {"status": status},
      );
      return responseData;
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
