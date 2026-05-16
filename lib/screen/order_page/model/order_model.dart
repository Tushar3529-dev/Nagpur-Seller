import 'package:hyper_local_seller/service/json_parser.dart';

const String modelName = 'order_model';

class OrdersResponse {
  bool? success;
  String? message;
  OrdersPageData? data;

  OrdersResponse({this.success, this.message, this.data});

  factory OrdersResponse.fromJson(Map<String, dynamic> json) {
    return OrdersResponse(
      success: JsonParser.boolValue(json['success'] ?? false),
      message: JsonParser.string(json['message'] ?? ''),
      data: json['data'] != null
          ? OrdersPageData.fromJson(json['data'] as Map<String, dynamic>)
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

class OrdersPageData {
  int? currentPage;
  int? lastPage;
  int? perPage;
  int? total;
  List<SellerOrderItem>? items;

  OrdersPageData({
    this.currentPage,
    this.lastPage,
    this.perPage,
    this.total,
    this.items,
  });

  factory OrdersPageData.fromJson(Map<String, dynamic> json) {
    return OrdersPageData(
      currentPage: JsonParser.intValue(json['current_page'] ?? 1),
      lastPage: JsonParser.intValue(json['last_page'] ?? 1),
      perPage: JsonParser.intValue(json['per_page'] ?? 15),
      total: JsonParser.intValue(json['total'] ?? 0),

      items: JsonParser.list<SellerOrderItem>(
        json['data'],
            (v) => SellerOrderItem.fromJson(v as Map<String, dynamic>),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['current_page'] = currentPage;
    data['last_page'] = lastPage;
    data['per_page'] = perPage;
    data['total'] = total;
    if (items != null) {
      data['data'] = items!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class SellerOrderItem {
  int orderItemId;
  int sellerOrderId;
  String createdAt;
  OrderInfo order;
  ProductInfo product;
  StoreInfo store;
  String sku;
  int quantity;
  SubtotalInfo subtotal;
  String status;

  SellerOrderItem({
    required this.orderItemId,
    required this.sellerOrderId,
    required this.createdAt,
    required this.order,
    required this.product,
    required this.store,
    required this.sku,
    required this.quantity,
    required this.subtotal,
    required this.status,
  });

  factory SellerOrderItem.fromJson(Map<String, dynamic> json) {
    return SellerOrderItem(
      orderItemId: JsonParser.requireInt(
        json['order_item_id'],
        model: modelName,
        field: 'order_item_id',
      ),
      sellerOrderId: JsonParser.requireInt(
        json['seller_order_id'],
        model: modelName,
        field: 'seller_order_id',
      ),
      createdAt: JsonParser.string(json['created_at'] ?? ''),

      order: json['order'] != null
          ? OrderInfo.fromJson(json['order'] as Map<String, dynamic>)
          : OrderInfo(), // fallback empty

      product: json['product'] != null
          ? ProductInfo.fromJson(json['product'] as Map<String, dynamic>)
          : ProductInfo(),

      store: json['store'] != null
          ? StoreInfo.fromJson(json['store'] as Map<String, dynamic>)
          : StoreInfo(),

      sku: JsonParser.requireString(
        json['sku'],
        model: modelName,
        field: 'sku',
      ),

      quantity: JsonParser.intValue(json['quantity'] ?? 1),

      subtotal: json['subtotal'] != null
          ? SubtotalInfo.fromJson(json['subtotal'] as Map<String, dynamic>)
          : SubtotalInfo(),

      status: JsonParser.string(json['status'] ?? 'pending'),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['order_item_id'] = orderItemId;
    data['seller_order_id'] = sellerOrderId;
    data['created_at'] = createdAt;
    data['order'] = order.toJson();
    data['product'] = product.toJson();
    data['store'] = store.toJson();
    data['sku'] = sku;
    data['quantity'] = quantity;
    data['subtotal'] = subtotal.toJson();
    data['status'] = status;
    return data;
  }
}

class OrderInfo {
  int id;
  String uuid;
  String buyerName;
  String paymentMethod;
  bool isRushOrder;
  String status;
  String image;

  OrderInfo({
    this.id = 0,
    this.uuid = '',
    this.buyerName = '',
    this.paymentMethod = '',
    this.isRushOrder = false,
    this.status = '',
    this.image = ''
  });

  factory OrderInfo.fromJson(Map<String, dynamic> json) {
    return OrderInfo(
      id: JsonParser.intValue(json['id'] ?? 0),
      uuid: JsonParser.string(json['uuid'] ?? ''),
      buyerName: JsonParser.string(json['buyer_name'] ?? 'Guest'),
      paymentMethod: JsonParser.string(json['payment_method'] ?? 'cod'),
      isRushOrder: JsonParser.boolValue(json['is_rush_order'] ?? false),
      status: JsonParser.string(json['status'] ?? ''),
      image:  JsonParser.string(json['image'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['uuid'] = uuid;
    data['buyer_name'] = buyerName;
    data['payment_method'] = paymentMethod;
    data['is_rush_order'] = isRushOrder;
    data['status'] = status;
    data['image'] = image;
    return data;
  }
}

class ProductInfo {
  int id;
  String title;
  String variant;

  ProductInfo({
    this.id = 0,
    this.title = '',
    this.variant = '',
  });

  factory ProductInfo.fromJson(Map<String, dynamic> json) {
    return ProductInfo(
      id: JsonParser.intValue(json['id'] ?? 0),
      title: JsonParser.string(json['title'] ?? ''),
      variant: JsonParser.string(json['variant'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['variant'] = variant;
    return data;
  }
}

class StoreInfo {
  String name;

  StoreInfo({this.name = ''});

  factory StoreInfo.fromJson(Map<String, dynamic> json) {
    return StoreInfo(
      name: JsonParser.string(json['name'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    return data;
  }
}

class SubtotalInfo {
  int raw;
  String formatted;

  SubtotalInfo({
    this.raw = 0,
    this.formatted = '\$0.00',
  });

  factory SubtotalInfo.fromJson(Map<String, dynamic> json) {
    return SubtotalInfo(
      raw: JsonParser.intValue(json['raw'] ?? 0),
      formatted: JsonParser.string(json['formatted'] ?? '\$0.00'),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['raw'] = raw;
    data['formatted'] = formatted;
    return data;
  }
}