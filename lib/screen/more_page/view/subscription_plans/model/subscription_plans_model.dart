import 'package:hyper_local_seller/service/json_parser.dart';

const String modelName = 'subscription_plans_model';

class SubscriptionPlansResponse {
  bool? success;
  String? message;
  SubscriptionPlansData? data;

  SubscriptionPlansResponse({this.success, this.message, this.data});

  factory SubscriptionPlansResponse.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlansResponse(
      success: JsonParser.boolValue(json['success'] ?? false),
      message: JsonParser.string(json['message'] ?? ''),
      data: json['data'] != null
          ? SubscriptionPlansData.fromJson(json['data'] as Map<String, dynamic>)
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

class SubscriptionPlansData {
  List<SubscriptionPlan>? plans;
  SubscriptionSettings? settings;

  SubscriptionPlansData({this.plans, this.settings});

  factory SubscriptionPlansData.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlansData(
      plans: JsonParser.list<SubscriptionPlan>(
        json['plans'],
        (v) => SubscriptionPlan.fromJson(v as Map<String, dynamic>),
      ),
      settings: json['settings'] != null
          ? SubscriptionSettings.fromJson(
              json['settings'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (plans != null) {
      data['plans'] = plans!.map((v) => v.toJson()).toList();
    }
    if (settings != null) {
      data['settings'] = settings!.toJson();
    }
    return data;
  }
}

class SubscriptionPlan {
  int id;
  String name;
  String? description;
  int price;
  String durationType;
  int? durationDays;
  bool isFree;
  bool isDefault;
  bool isRecommended;
  bool status;
  PlanLimits? limits;

  SubscriptionPlan({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.durationType,
    this.durationDays,
    this.isFree = false,
    this.isDefault = false,
    this.isRecommended = false,
    this.status = true,
    this.limits,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: JsonParser.requireInt(json['id'], model: modelName, field: 'id'),
      name: JsonParser.requireString(
        json['name'],
        model: modelName,
        field: 'name',
      ),

      description: JsonParser.string(json['description'] ?? ''),
      price: JsonParser.intValue(json['price'] ?? 0),
      durationType: JsonParser.string(json['duration_type'] ?? 'monthly'),
      durationDays: JsonParser.intValue(json['duration_days']),

      isFree: JsonParser.boolValue(json['is_free'] ?? false),
      isDefault: JsonParser.boolValue(json['is_default'] ?? false),
      isRecommended: JsonParser.boolValue(json['is_recommended'] ?? false),
      status: JsonParser.boolValue(json['status'] ?? true),

      limits: json['limits'] != null
          ? PlanLimits.fromJson(json['limits'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['description'] = description;
    data['price'] = price;
    data['duration_type'] = durationType;
    data['duration_days'] = durationDays;
    data['is_free'] = isFree;
    data['is_default'] = isDefault;
    data['is_recommended'] = isRecommended;
    data['status'] = status;
    if (limits != null) {
      data['limits'] = limits!.toJson();
    }
    return data;
  }
}

class PlanLimits {
  int? storeLimit;
  int? productLimit;
  int? roleLimit;
  int? systemUserLimit;

  PlanLimits({
    this.storeLimit,
    this.productLimit,
    this.roleLimit,
    this.systemUserLimit,
  });

  factory PlanLimits.fromJson(Map<String, dynamic> json) {
    return PlanLimits(
      storeLimit: JsonParser.intValue(json['store_limit']),
      productLimit: JsonParser.intValue(json['product_limit']),
      roleLimit: JsonParser.intValue(json['role_limit']),
      systemUserLimit: JsonParser.intValue(json['system_user_limit']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['store_limit'] = storeLimit;
    data['product_limit'] = productLimit;
    data['role_limit'] = roleLimit;
    data['system_user_limit'] = systemUserLimit;
    return data;
  }
}

class SubscriptionSettings {
  String? heading;
  String? description;

  SubscriptionSettings({this.heading, this.description});

  factory SubscriptionSettings.fromJson(Map<String, dynamic> json) {
    return SubscriptionSettings(
      heading: JsonParser.string(json['subscriptionHeading'] ?? ''),
      description: JsonParser.string(json['subscriptionDescription'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['subscriptionHeading'] = heading;
    data['subscriptionDescription'] = description;
    return data;
  }
}

class PlanSnapshot {
  String? planName;
  int? price;
  int? durationDays;
  PlanLimits? limits;

  PlanSnapshot({this.planName, this.price, this.durationDays, this.limits});

  factory PlanSnapshot.fromJson(Map<String, dynamic> json) {
    return PlanSnapshot(
      planName: JsonParser.string(json['plan_name'] ?? ''),
      price: JsonParser.intValue(json['price']),
      durationDays: JsonParser.intValue(json['duration_days']),
      limits: json['limits'] != null
          ? PlanLimits.fromJson(json['limits'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['plan_name'] = planName;
    data['price'] = price;
    data['duration_days'] = durationDays;
    if (limits != null) data['limits'] = limits!.toJson();
    return data;
  }
}

class SubscriptionTransaction {
  int id;
  int sellerId;
  int sellerSubscriptionId;
  int planId;
  String? paymentGateway;
  String? transactionId;
  int? amount;
  String? status;
  String? createdAt;

  SubscriptionTransaction({
    required this.id,
    required this.sellerId,
    required this.sellerSubscriptionId,
    required this.planId,
    this.paymentGateway,
    this.transactionId,
    this.amount,
    this.status,
    this.createdAt,
  });

  factory SubscriptionTransaction.fromJson(Map<String, dynamic> json) {
    return SubscriptionTransaction(
      id: JsonParser.requireInt(
        json['id'],
        model: modelName,
        field: 'transactions[].id',
      ),
      sellerId: JsonParser.requireInt(
        json['seller_id'],
        model: modelName,
        field: 'transactions[].seller_id',
      ),
      sellerSubscriptionId: JsonParser.requireInt(
        json['seller_subscription_id'],
        model: modelName,
        field: 'transactions[].seller_subscription_id',
      ),
      planId: JsonParser.requireInt(
        json['plan_id'],
        model: modelName,
        field: 'transactions[].plan_id',
      ),

      paymentGateway: JsonParser.string(json['payment_gateway']),
      transactionId: JsonParser.string(json['transaction_id']),
      amount: JsonParser.intValue(json['amount']),
      status: JsonParser.string(json['status'] ?? 'pending'),
      createdAt: JsonParser.string(json['created_at'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['seller_id'] = sellerId;
    data['seller_subscription_id'] = sellerSubscriptionId;
    data['plan_id'] = planId;
    data['payment_gateway'] = paymentGateway;
    data['transaction_id'] = transactionId;
    data['amount'] = amount;
    data['status'] = status;
    data['created_at'] = createdAt;
    return data;
  }
}
