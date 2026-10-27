import 'package:hyper_local_seller/config/api_routes.dart';
import 'package:hyper_local_seller/screen/order_page/dispatch/model/dispatch_model.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';
import 'package:hyper_local_seller/service/json_parser.dart';

class DispatchRepo {
  final ApiBaseHelper _helper = ApiBaseHelper();
  String lastMessage = '';

  Future<DispatchDashboard> getDashboard() async => DispatchDashboard.fromJson(
    Map<String, dynamic>.from(
      await _helper.get(ApiRoutes.dispatchDashboardApi),
    ),
  );

  Future<RiderAvailability> getRiderAvailability() async =>
      RiderAvailability.fromJson(
        Map<String, dynamic>.from(
          await _helper.get(ApiRoutes.riderAvailabilityApi),
        ),
      );

  Future<int> markSelfDelivery(int orderId) async {
    final response = await _helper.post(ApiRoutes.selfDeliverApi(orderId), {});
    lastMessage = JsonParser.string(response['message']);
    final data = response['data'];
    return JsonParser.intValue(
      data is Map ? data['order_id'] : null,
      fallback: orderId,
    );
  }
}
