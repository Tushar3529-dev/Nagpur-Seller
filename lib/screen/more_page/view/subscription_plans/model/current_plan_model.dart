import 'package:hyper_local_seller/service/json_parser.dart';
import 'package:intl/intl.dart';
import 'subscription_plans_model.dart';

const String modelName = 'current_plan_model';

class CurrentPlanResponse {
  bool? success;
  String? message;
  CurrentPlanData? data;

  CurrentPlanResponse({this.success, this.message, this.data});

  factory CurrentPlanResponse.fromJson(Map<String, dynamic> json) {
    return CurrentPlanResponse(
      success: JsonParser.boolValue(json['success'] ?? false),
      message: JsonParser.string(json['message'] ?? ''),
      data: json['data'] != null
          ? CurrentPlanData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class CurrentPlanData {
  int id;
  int sellerId;
  int planId;
  String status;
  String startDate;
  String? endDate;
  int? pricePaid;
  SubscriptionPlan? plan;
  PlanSnapshot? snapshot;
  List<SubscriptionTransaction>? transactions;

  CurrentPlanData({
    required this.id,
    required this.sellerId,
    required this.planId,
    required this.status,
    required this.startDate,
    this.endDate,
    this.pricePaid,
    this.plan,
    this.snapshot,
    this.transactions,
  });

  factory CurrentPlanData.fromJson(Map<String, dynamic> json) {
    return CurrentPlanData(
      id: JsonParser.requireInt(json['id'], model: modelName, field: 'id'),
      sellerId: JsonParser.requireInt(
        json['seller_id'],
        model: modelName,
        field: 'seller_id',
      ),
      planId: JsonParser.requireInt(
        json['plan_id'],
        model: modelName,
        field: 'plan_id',
      ),

      status: _parseValidatedStatus(json['status'], json['end_date']),
      startDate: JsonParser.string(json['start_date'] ?? ''),
      endDate: JsonParser.string(json['end_date']),

      pricePaid: JsonParser.intValue(json['price_paid']),

      plan: json['plan'] != null
          ? SubscriptionPlan.fromJson(json['plan'] as Map<String, dynamic>)
          : null,

      snapshot: json['snapshot'] != null
          ? PlanSnapshot.fromJson(json['snapshot'] as Map<String, dynamic>)
          : null,

      transactions: JsonParser.list<SubscriptionTransaction>(
        json['transactions'],
        (v) => SubscriptionTransaction.fromJson(v as Map<String, dynamic>),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['seller_id'] = sellerId;
    data['plan_id'] = planId;
    data['status'] = status;
    data['start_date'] = startDate;
    data['end_date'] = endDate;
    data['price_paid'] = pricePaid;
    if (plan != null) data['plan'] = plan!.toJson();
    if (snapshot != null) data['snapshot'] = snapshot!.toJson();
    if (transactions != null) {
      data['transactions'] = transactions!.map((v) => v.toJson()).toList();
    }
    return data;
  }

  static String _parseValidatedStatus(dynamic statusVal, dynamic endDateVal) {
    String status = JsonParser.string(statusVal ?? 'inactive');
    String? endDate = JsonParser.string(endDateVal);

    if (status == 'active' && endDate != null && endDate.isNotEmpty) {
      try {
        final format = DateFormat('dd MMM yyyy HH:mm:ss');
        final expiryDate = format.parse(endDate);
        if (expiryDate.isBefore(DateTime.now())) {
          return 'expired';
        }
      } catch (e) {
        // Ignore parsing errors, keep original status
      }
    }
    return status;
  }
}

