import 'package:hyper_local_seller/config/api_routes.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';

class HomeDataRepo {
  final ApiBaseHelper _helper = ApiBaseHelper();

  Future<dynamic> getChartsData({int? storeId}) async {
    try {
      final Map<String, dynamic> queryParams = {
        'store_id': storeId ?? HiveStorage.selectedStoreId,
      };

      final response = await _helper.get(ApiRoutes.dashboardDataApi, queryParameters: queryParams);

      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
