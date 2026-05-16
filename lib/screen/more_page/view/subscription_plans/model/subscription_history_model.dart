import 'package:hyper_local_seller/service/json_parser.dart';
import 'subscription_plans_model.dart';

export 'package:hyper_local_seller/screen/more_page/view/subscription_plans/model/subscription_plans_model.dart'
    show SubscriptionPlan, PlanLimits, PlanSnapshot, SubscriptionTransaction;

const String modelName = 'subscription_history_model';

class SubscriptionHistoryResponse {
  bool? success;
  String? message;
  SubscriptionHistoryPageData? data;

  SubscriptionHistoryResponse({this.success, this.message, this.data});

  factory SubscriptionHistoryResponse.fromJson(Map<String, dynamic> json) {
    return SubscriptionHistoryResponse(
      success: JsonParser.boolValue(json['success'] ?? false),
      message: JsonParser.string(json['message'] ?? ''),
      data: json['data'] != null
          ? SubscriptionHistoryPageData.fromJson(
              json['data'] as Map<String, dynamic>,
            )
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

class SubscriptionHistoryPageData {
  int? currentPage;
  int? lastPage;
  int? perPage;
  int? total;
  List<SubscriptionHistoryEntry>? history;

  SubscriptionHistoryPageData({
    this.currentPage,
    this.lastPage,
    this.perPage,
    this.total,
    this.history,
  });

  factory SubscriptionHistoryPageData.fromJson(Map<String, dynamic> json) {
    return SubscriptionHistoryPageData(
      currentPage: JsonParser.intValue(json['current_page'] ?? 1),
      lastPage: JsonParser.intValue(json['last_page'] ?? 1),
      perPage: JsonParser.intValue(json['per_page'] ?? 15),
      total: JsonParser.intValue(json['total'] ?? 0),

      history: JsonParser.list<SubscriptionHistoryEntry>(
        json['data'],
        (v) => SubscriptionHistoryEntry.fromJson(v as Map<String, dynamic>),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['current_page'] = currentPage;
    data['last_page'] = lastPage;
    data['per_page'] = perPage;
    data['total'] = total;
    if (history != null) {
      data['data'] = history!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class SubscriptionHistoryEntry {
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

  SubscriptionHistoryEntry({
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

  factory SubscriptionHistoryEntry.fromJson(Map<String, dynamic> json) {
    return SubscriptionHistoryEntry(
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

      status: JsonParser.string(json['status'] ?? 'inactive'),
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
}
