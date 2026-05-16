import 'package:hyper_local_seller/service/json_parser.dart';

const String modelName = 'order_details_model';

class OrderDetailsResponse {
  bool? success;
  String? message;
  OrderDetailsData? data;

  OrderDetailsResponse({this.success, this.message, this.data});

  factory OrderDetailsResponse.fromJson(Map<String, dynamic> json) {
    return OrderDetailsResponse(
      success: JsonParser.boolValue(json['success'] ?? false),
      message: JsonParser.string(json['message'] ?? ''),
      data: json['data'] != null
          ? OrderDetailsData.fromJson(json['data'] as Map<String, dynamic>)
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

class OrderDetailsData {
  int id;
  String uuid;
  String email;
  String status;
  String paymentMethod;
  String paymentStatus;
  String totalPrice; // kept as String (formatted value from API)
  String billingName;
  String billingPhone;
  String shippingName;
  String shippingAddress1;
  String? shippingAddress2;
  String? shippingLandmark;
  String shippingCity;
  String shippingState;
  String shippingZip;
  String shippingCountry;
  String shippingPhone;
  String? orderNote;
  List<OrderItemDetail>? items;
  String createdAt;
  int isRushedOrder;

  OrderDetailsData({
    required this.id,
    required this.uuid,
    required this.email,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.totalPrice,
    required this.billingName,
    required this.billingPhone,
    required this.shippingName,
    required this.shippingAddress1,
    this.shippingAddress2,
    this.shippingLandmark,
    required this.shippingCity,
    required this.shippingState,
    required this.shippingZip,
    required this.shippingCountry,
    required this.shippingPhone,
    this.orderNote,
    this.items,
    required this.createdAt,
    required this.isRushedOrder,
  });

  factory OrderDetailsData.fromJson(Map<String, dynamic> json) {
    return OrderDetailsData(
      id: JsonParser.requireInt(json['id'], model: modelName, field: 'id'),
      uuid: JsonParser.requireString(json['uuid'], model: modelName, field: 'uuid'),
      email: JsonParser.string(json['email'] ?? ''),
      status: JsonParser.string(json['status'] ?? 'pending'),
      paymentMethod: JsonParser.string(json['payment_method'] ?? 'cod'),
      paymentStatus: JsonParser.string(json['payment_status'] ?? 'pending'),
      totalPrice: JsonParser.string(json['total_price'] ?? '0.00'),
      billingName: JsonParser.string(json['billing_name'] ?? ''),
      billingPhone: JsonParser.string(json['billing_phone'] ?? ''),
      shippingName: JsonParser.string(json['shipping_name'] ?? ''),
      shippingAddress1: JsonParser.string(json['shipping_address_1'] ?? ''),
      shippingAddress2: JsonParser.string(json['shipping_address_2']),
      shippingLandmark: JsonParser.string(json['shipping_landmark']),
      shippingCity: JsonParser.string(json['shipping_city'] ?? ''),
      shippingState: JsonParser.string(json['shipping_state'] ?? ''),
      shippingZip: JsonParser.string(json['shipping_zip'] ?? ''),
      shippingCountry: JsonParser.string(json['shipping_country'] ?? 'India'),
      shippingPhone: JsonParser.string(json['shipping_phone'] ?? ''),
      orderNote: JsonParser.string(json['order_note']),

      items: JsonParser.list<OrderItemDetail>(
        json['items'],
            (v) => OrderItemDetail.fromJson(v as Map<String, dynamic>),
      ),

      createdAt: JsonParser.string(json['created_at'] ?? ''),
      isRushedOrder: JsonParser.requireInt(json['is_rush_order'], model: modelName, field: 'isRushOrder'),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['uuid'] = uuid;
    data['email'] = email;
    data['status'] = status;
    data['payment_method'] = paymentMethod;
    data['payment_status'] = paymentStatus;
    data['total_price'] = totalPrice;
    data['billing_name'] = billingName;
    data['billing_phone'] = billingPhone;
    data['shipping_name'] = shippingName;
    data['shipping_address_1'] = shippingAddress1;
    data['shipping_address_2'] = shippingAddress2;
    data['shipping_landmark'] = shippingLandmark;
    data['shipping_city'] = shippingCity;
    data['shipping_state'] = shippingState;
    data['shipping_zip'] = shippingZip;
    data['shipping_country'] = shippingCountry;
    data['shipping_phone'] = shippingPhone;
    data['order_note'] = orderNote;
    if (items != null) {
      data['items'] = items!.map((v) => v.toJson()).toList();
    }
    data['created_at'] = createdAt;
    data['is_rush_order'] = isRushedOrder;
    return data;
  }
}

class OrderItemDetail {
  int id;
  List<dynamic>? attachments;
  OrderItemStatus? orderItem;
  ProductDetail? product;
  VariantDetail? variant;
  dynamic store;
  String price;
  int quantity;
  int subtotal;

  OrderItemDetail({
    required this.id,
    this.attachments,
    this.orderItem,
    this.product,
    this.variant,
    this.store,
    required this.price,
    required this.quantity,
    required this.subtotal,
  });

  factory OrderItemDetail.fromJson(Map<String, dynamic> json) {
    return OrderItemDetail(
      id: JsonParser.requireInt(json['id'], model: modelName, field: 'items[].id'),
      attachments: JsonParser.list<dynamic>(
        json['attachments'],
            (v) => v, // can be refined later if structure is known
      ),
      orderItem: json['orderItem'] != null
          ? OrderItemStatus.fromJson(json['orderItem'] as Map<String, dynamic>)
          : null,
      product: json['product'] != null
          ? ProductDetail.fromJson(json['product'] as Map<String, dynamic>)
          : null,
      variant: json['variant'] != null
          ? VariantDetail.fromJson(json['variant'] as Map<String, dynamic>)
          : null,
      store: json['store'], // null or object — kept dynamic
      price: JsonParser.string(json['price'] ?? '0.00'),
      quantity: JsonParser.intValue(json['quantity'] ?? 1),
      subtotal: JsonParser.intValue(json['subtotal'] ?? 0),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['attachments'] = attachments;
    if (orderItem != null) data['orderItem'] = orderItem!.toJson();
    if (product != null) data['product'] = product!.toJson();
    if (variant != null) data['variant'] = variant!.toJson();
    data['store'] = store;
    data['price'] = price;
    data['quantity'] = quantity;
    data['subtotal'] = subtotal;
    return data;
  }
}

class OrderItemStatus {
  int id;
  String status;
  String statusFormatted;

  OrderItemStatus({
    required this.id,
    required this.status,
    required this.statusFormatted,
  });

  factory OrderItemStatus.fromJson(Map<String, dynamic> json) {
    return OrderItemStatus(
      id: JsonParser.intValue(json['id'] ?? 0),
      status: JsonParser.string(json['status'] ?? ''),
      statusFormatted: JsonParser.string(json['status_formatted'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['status'] = status;
    data['status_formatted'] = statusFormatted;
    return data;
  }
}

class ProductDetail {
  int id;
  String title;

  ProductDetail({
    required this.id,
    required this.title,
  });

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    return ProductDetail(
      id: JsonParser.intValue(json['id'] ?? 0),
      title: JsonParser.string(json['title'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    return data;
  }
}

class VariantDetail {
  int id;
  String title;

  VariantDetail({
    required this.id,
    required this.title,
  });

  factory VariantDetail.fromJson(Map<String, dynamic> json) {
    return VariantDetail(
      id: JsonParser.intValue(json['id'] ?? 0),
      title: JsonParser.string(json['title'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    return data;
  }
}