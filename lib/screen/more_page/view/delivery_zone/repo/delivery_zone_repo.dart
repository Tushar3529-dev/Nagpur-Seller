import 'package:hyper_local_seller/config/api_routes.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';

class DeliveryZoneRepo {
  final ApiBaseHelper _helper = ApiBaseHelper();

  Future<dynamic> getDeliveryZone({
    int? page,
    int? perPage,
    String? search,
  }) async {
    try {
      final queryParameters = {
        if (page != null) 'page': page.toString(),
        if (perPage != null) 'per_page': perPage.toString(),
        if (search != null) 'search': search,
      };

      final response = await _helper.get(
        ApiRoutes.deliveryZonesApi,
        queryParameters: queryParameters,
      );

      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
