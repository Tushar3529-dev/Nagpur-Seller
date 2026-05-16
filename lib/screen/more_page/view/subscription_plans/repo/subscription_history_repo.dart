import 'package:hyper_local_seller/config/api_routes.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';

class SubscriptionHistoryRepo {
  final ApiBaseHelper _helper = ApiBaseHelper();

  Future<dynamic> getSubscriptionPlanHistory({int? page, int? perPage}) async {
    try {
      final queryParameters = {
        if (page != null) 'page': page.toString(),
        if (perPage != null) 'per_page': perPage.toString(),
      };

      final response = await _helper.get(
        ApiRoutes.subscriptionPlanHistoryApi,
        queryParameters: queryParameters,
      );

      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
