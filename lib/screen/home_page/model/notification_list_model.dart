import 'package:hyper_local_seller/service/json_parser.dart';

const String _modelName = 'notification_list_model';

class NotificationListResponse {
  bool? success;
  String? message;
  NotificationPageData? data;

  NotificationListResponse({this.success, this.message, this.data});

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) {
    return NotificationListResponse(
      success: JsonParser.boolValue(json['success'] ?? false),
      message: JsonParser.string(json['message'] ?? ''),
      data: json['data'] != null
          ? NotificationPageData.fromJson(json['data'] as Map<String, dynamic>)
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

class NotificationPageData {
  int? currentPage;
  int? lastPage;
  int? perPage;
  int? total;
  List<NotificationItem>? notifications;

  NotificationPageData({
    this.currentPage,
    this.lastPage,
    this.perPage,
    this.total,
    this.notifications,
  });

  factory NotificationPageData.fromJson(Map<String, dynamic> json) {
    // Pagination is nested inside "pagination" key
    final pagination = json['pagination'] as Map<String, dynamic>?;

    return NotificationPageData(
      currentPage: JsonParser.intValue(pagination?['current_page'] ?? 1),
      lastPage: JsonParser.intValue(pagination?['last_page'] ?? 1),
      perPage: JsonParser.intValue(pagination?['per_page'] ?? 15),
      total: JsonParser.intValue(pagination?['total'] ?? 0),
      notifications: JsonParser.list<NotificationItem>(
        json['notifications'],
        (v) => NotificationItem.fromJson(v as Map<String, dynamic>),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['pagination'] = {
      'current_page': currentPage,
      'last_page': lastPage,
      'per_page': perPage,
      'total': total,
    };
    if (notifications != null) {
      data['notifications'] =
          notifications!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class NotificationItem {
  String id;
  int? userId;
  int? storeId;
  int? orderId;
  String type;
  String? sentTo;
  String title;
  String message;
  bool isRead;
  NotificationMetadata? metadata;
  String? createdAt;
  String? updatedAt;

  NotificationItem({
    required this.id,
    this.userId,
    this.storeId,
    this.orderId,
    required this.type,
    this.sentTo,
    required this.title,
    required this.message,
    this.isRead = false,
    this.metadata,
    this.createdAt,
    this.updatedAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: JsonParser.requireString(
        json['id'],
        model: _modelName,
        field: 'id',
      ),
      userId: JsonParser.intValue(json['user_id']),
      storeId: JsonParser.intValue(json['store_id']),
      orderId: JsonParser.intValue(json['order_id']),
      type: JsonParser.string(json['type'] ?? ''),
      sentTo: JsonParser.string(json['sent_to'] ?? ''),
      title: JsonParser.string(json['title'] ?? ''),
      message: JsonParser.string(json['message'] ?? ''),
      isRead: JsonParser.boolValue(json['is_read'] ?? false),
      metadata: json['metadata'] != null
          ? NotificationMetadata.fromJson(
              json['metadata'] as Map<String, dynamic>,
            )
          : null,
      createdAt: JsonParser.string(json['created_at'] ?? ''),
      updatedAt: JsonParser.string(json['updated_at'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['user_id'] = userId;
    data['store_id'] = storeId;
    data['order_id'] = orderId;
    data['type'] = type;
    data['sent_to'] = sentTo;
    data['title'] = title;
    data['message'] = message;
    data['is_read'] = isRead;
    if (metadata != null) {
      data['metadata'] = metadata!.toJson();
    }
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}

class NotificationMetadata {
  int? orderId;
  int? orderItemId;
  int? orderItemReturnId;
  int? sellerOrderId;
  String? returnStatus;
  String? pickupStatus;
  String? statusOld;
  String? statusNew;
  String? orderSlug;

  NotificationMetadata({
    this.orderId,
    this.orderItemId,
    this.orderItemReturnId,
    this.sellerOrderId,
    this.returnStatus,
    this.pickupStatus,
    this.statusOld,
    this.statusNew,
    this.orderSlug,
  });

  factory NotificationMetadata.fromJson(Map<String, dynamic> json) {
    return NotificationMetadata(
      orderId: JsonParser.intValue(json['order_id']),
      orderItemId: JsonParser.intValue(json['order_item_id']),
      sellerOrderId: JsonParser.intValue(json['seller_order_id']),
      orderItemReturnId: JsonParser.intValue(json['order_item_return_id']),
      returnStatus: JsonParser.string(json['return_status'] ?? ''),
      pickupStatus: JsonParser.string(json['pickup_status'] ?? ''),
      statusOld: JsonParser.string(json['status_old'] ?? ''),
      statusNew: JsonParser.string(json['status_new'] ?? ''),
      orderSlug: JsonParser.string(json['order_slug'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['order_id'] = orderId;
    data['order_item_id'] = orderItemId;
    data['order_item_return_id'] = orderItemReturnId;
    data['return_status'] = returnStatus;
    data['seller_order_id'] = sellerOrderId;
    data['pickup_status'] = pickupStatus;
    data['status_old'] = statusOld;
    data['status_new'] = statusNew;
    data['order_slug'] = orderSlug;
    return data;
  }
}
