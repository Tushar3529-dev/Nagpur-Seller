import 'package:hyper_local_seller/service/json_parser.dart';

enum EarningType { credit, debit }

class EarningsHistoryModel {
  final bool success;
  final String message;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final List<EarningData> data;

  EarningsHistoryModel({
    required this.success,
    required this.message,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    required this.data,
  });

  factory EarningsHistoryModel.fromJson(Map<String, dynamic> json) {
    final success = JsonParser.boolValue(json['success'] ?? true);
    final message = JsonParser.string(json['message'] ?? '');
    final dataMap = json['data'] as Map<String, dynamic>?;

    return EarningsHistoryModel(
      success: success,
      message: message,
      currentPage: JsonParser.intValue(dataMap?['current_page'] ?? 1),
      lastPage: JsonParser.intValue(dataMap?['last_page'] ?? 1),
      perPage: JsonParser.intValue(dataMap?['per_page'] ?? 15),
      total: JsonParser.intValue(dataMap?['total'] ?? 0),
      data: (dataMap?['data'] as List? ?? [])
          .map((e) => EarningData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class EarningData {
  final int id;
  final String entryType;
  final String description;
  final int orderId;
  final int orderItemId;
  final int sellerOrderId;
  final String productTitle;
  final String? variantTitle;
  final String storeName;
  final String amountFormatted;
  final double amountRaw;
  final String? adminCommissionFormatted;
  final double? adminCommissionRaw;
  final String postedAt;
  final String? settledAt;
  final String settlementStatus;

  EarningData({
    required this.id,
    required this.entryType,
    required this.description,
    required this.orderId,
    required this.orderItemId,
    required this.sellerOrderId,
    required this.productTitle,
    this.variantTitle,
    required this.storeName,
    required this.amountFormatted,
    required this.amountRaw,
    this.adminCommissionFormatted,
    this.adminCommissionRaw,
    required this.postedAt,
    this.settledAt,
    required this.settlementStatus,
  });

  factory EarningData.fromJson(Map<String, dynamic> json) {
    final orderMap = json['order'] as Map<String, dynamic>?;
    final amountMap = json['amount'] as Map<String, dynamic>?;
    final commissionMap = json['admin_commission'] as Map<String, dynamic>?;

    return EarningData(
      id: JsonParser.intValue(json['id']),
      entryType: JsonParser.string(json['entry_type']),
      description: JsonParser.string(json['description']),
      orderId: JsonParser.intValue(orderMap?['order_id']),
      orderItemId: JsonParser.intValue(orderMap?['order_item_id']),
      sellerOrderId: JsonParser.intValue(orderMap?['seller_order_id']),
      productTitle: JsonParser.string(orderMap?['product_title']),
      variantTitle: JsonParser.string(orderMap?['variant_title']),
      storeName: JsonParser.string(orderMap?['store_name']),
      amountFormatted: JsonParser.string(amountMap?['formatted']),
      amountRaw: JsonParser.doubleValue(amountMap?['raw']),
      adminCommissionFormatted: JsonParser.string(commissionMap?['formatted']),
      adminCommissionRaw: JsonParser.doubleValue(commissionMap?['raw']),
      postedAt: JsonParser.string(json['posted_at']),
      settledAt: JsonParser.string(json['settled_at']),
      settlementStatus: JsonParser.string(json['settlement_status']),
    );
  }
}
