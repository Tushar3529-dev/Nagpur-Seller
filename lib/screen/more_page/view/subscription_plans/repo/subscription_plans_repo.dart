import 'package:hyper_local_seller/config/api_routes.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';

class SubscriptionPlansRepo {
  final ApiBaseHelper _helper = ApiBaseHelper();

  Future<dynamic> getSubscriptionPlans() async {
    try {
      final response = await _helper.get(ApiRoutes.subscriptionPlansApi);
      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<dynamic> checkSubscriptionEligibility(int planId) async {
    try {
      final Map<String, dynamic> body = {"plan_id": planId};
      final response = await _helper.post(ApiRoutes.checkEligibilityApi, body);
      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<dynamic> buySubscriptionPlan(
    int planId,
    String paymentType,
    String? gatewayTransactionId,
  ) async {
    try {
      final Map<String, dynamic> body = {
        "plan_id": planId,
        "payment_type": paymentType,
        "gateway_transaction_id": gatewayTransactionId,
      };
      final response = await _helper.post(
        ApiRoutes.buySubscriptionPlanApi,
        body,
      );
      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<dynamic> getCurrentSubscriptionPlan() async {
    try {
      final response = await _helper.get(ApiRoutes.currentSubscriptionPlanApi);
      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
