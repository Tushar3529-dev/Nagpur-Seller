import 'package:dio/dio.dart';
import 'package:hyper_local_seller/config/api_routes.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';

class AddStoreRepository {
  final ApiBaseHelper _helper = ApiBaseHelper();

  Future<dynamic> createStore(FormData formData) async {
    try {
      final responseData = await _helper.postMultipart(
        ApiRoutes.storesApi,
        formData,
      );
      return responseData;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<dynamic> updateStore(int storeId, FormData formData) async {
    try {
      final responseData = await _helper.postMultipart(
        '${ApiRoutes.storesApi}/$storeId',
        formData,
      );
      return responseData;
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
