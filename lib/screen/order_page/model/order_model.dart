import 'package:hyper_local_seller/screen/order_page/incoming_orders/model/pending_order_model.dart';
import 'package:hyper_local_seller/service/json_parser.dart';

export 'package:hyper_local_seller/screen/order_page/incoming_orders/model/pending_order_model.dart'
    show OrderMode;

class OrdersResponse {
  bool? success;
  String? message;
  OrdersPageData? data;

  OrdersResponse({this.success, this.message, this.data});

  factory OrdersResponse.fromJson(Map<String, dynamic> json) {
    return OrdersResponse(
      success: JsonParser.boolValue(json['success'] ?? false),
      message: JsonParser.string(json['message'] ?? ''),
      data: json['data'] is Map<String, dynamic>
          ? OrdersPageData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}

class OrdersPageData {
  int? currentPage;
  int? lastPage;
  int? perPage;
  int? total;
  List<SellerOrder>? items;

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
      items: _maps(json['data']).map(SellerOrder.fromJson).toList(),
    );
  }
}

/// One row of `GET /seller/orders` — a whole order with its items.
class SellerOrder {
  final int id;

  /// Id used for `GET /orders/{id}`. The list sends `seller_order_id` on
  /// older responses; newer ones only send `id`.
  final int sellerOrderId;
  final String orderNumber;
  final String uuid;

  /// Null when the row doesn't say — the server already filtered by mode.
  final OrderMode? orderMode;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final bool isRushOrder;
  final String fulfillmentType;
  final String currencyCode;
  final String subtotal;
  final String finalTotal;
  final String? formattedTotal;
  final String? deliveryDate;
  final String? deliverySlotLabel;
  final String shippingName;
  final String shippingPhone;
  final String createdAt;
  final List<SellerOrderLine> items;

  const SellerOrder({
    required this.id,
    required this.sellerOrderId,
    required this.orderNumber,
    required this.uuid,
    required this.orderMode,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.isRushOrder,
    required this.fulfillmentType,
    required this.currencyCode,
    required this.subtotal,
    required this.finalTotal,
    this.formattedTotal,
    required this.deliveryDate,
    required this.deliverySlotLabel,
    required this.shippingName,
    required this.shippingPhone,
    required this.createdAt,
    required this.items,
  });

  factory SellerOrder.fromJson(Map<String, dynamic> json) {
    // The live endpoint still returns one row per order item; the
    // order-level shape (with `items`) is what the backend is moving to.
    if (json.containsKey('order_item_id') && !json.containsKey('items')) {
      return SellerOrder._fromItemRow(json);
    }

    final id = JsonParser.intValue(json['id']);
    final slot = json['delivery_time_slot'];

    return SellerOrder(
      id: id,
      sellerOrderId: JsonParser.intValue(json['seller_order_id'], fallback: id),
      orderNumber: JsonParser.string(json['order_number']),
      uuid: JsonParser.string(json['uuid']),
      orderMode: OrderMode.tryParse(json['order_mode']),
      status: JsonParser.string(json['status'], fallback: 'pending'),
      paymentMethod: JsonParser.string(json['payment_method'], fallback: 'cod'),
      paymentStatus: JsonParser.string(json['payment_status']),
      isRushOrder: JsonParser.boolValue(json['is_rush_order']),
      fulfillmentType: JsonParser.string(json['fulfillment_type']),
      currencyCode: JsonParser.string(json['currency_code']),
      subtotal: JsonParser.string(json['subtotal'], fallback: '0'),
      finalTotal: JsonParser.string(
        json['final_total'] ?? json['total_payable'],
        fallback: '0',
      ),
      deliveryDate: _nonEmpty(json['delivery_date']),
      deliverySlotLabel: slot is Map ? _nonEmpty(slot['label']) : null,
      shippingName: JsonParser.string(json['shipping_name']),
      shippingPhone: JsonParser.string(json['shipping_phone']),
      createdAt: JsonParser.string(json['created_at']),
      items: _maps(json['items']).map(SellerOrderLine.fromJson).toList(),
    );
  }

  /// Item-level row: `{order_item_id, seller_order_id, order{...},
  /// product{...}, store{...}, quantity, subtotal{raw, formatted}, status}`.
  factory SellerOrder._fromItemRow(Map<String, dynamic> json) {
    final order = json['order'] is Map ? json['order'] as Map : const {};
    final product = json['product'] is Map ? json['product'] as Map : const {};
    final store = json['store'] is Map ? json['store'] as Map : const {};
    final subtotal = json['subtotal'] is Map
        ? json['subtotal'] as Map
        : const {};
    final status = JsonParser.string(json['status'], fallback: 'pending');
    final orderId = JsonParser.intValue(order['id']);

    return SellerOrder(
      id: orderId,
      sellerOrderId: JsonParser.intValue(json['seller_order_id']),
      orderNumber: JsonParser.string(order['order_number']),
      uuid: JsonParser.string(order['uuid']),
      orderMode: OrderMode.tryParse(json['order_mode'] ?? order['order_mode']),
      status: status,
      paymentMethod: JsonParser.string(
        order['payment_method'],
        fallback: 'cod',
      ),
      paymentStatus: JsonParser.string(order['payment_status']),
      isRushOrder: JsonParser.boolValue(order['is_rush_order']),
      fulfillmentType: JsonParser.string(order['fulfillment_type']),
      currencyCode: JsonParser.string(order['currency_code']),
      subtotal: JsonParser.string(subtotal['raw'], fallback: '0'),
      finalTotal: JsonParser.string(subtotal['raw'], fallback: '0'),
      formattedTotal: _nonEmpty(subtotal['formatted']),
      deliveryDate: null,
      deliverySlotLabel: null,
      shippingName: JsonParser.string(order['buyer_name']),
      shippingPhone: '',
      createdAt: JsonParser.string(json['created_at']),
      items: [
        SellerOrderLine(
          id: JsonParser.intValue(json['order_item_id']),
          productTitle: JsonParser.string(product['title']),
          variantTitle: JsonParser.string(product['variant']),
          image: _firstUrl([order['image'], product['image']]),
          storeName: JsonParser.string(store['name']),
          quantity: JsonParser.intValue(json['quantity'], fallback: 1),
          price: JsonParser.string(subtotal['raw'], fallback: '0'),
          subtotal: JsonParser.string(subtotal['raw'], fallback: '0'),
          status: status,
        ),
      ],
    );
  }

  bool get isWholesale => orderMode == OrderMode.wholesale;

  /// Total ready for display — the backend's own formatting when it sends one.
  String displayTotal(String currencySymbol) =>
      formattedTotal ?? '$currencySymbol$finalTotal';

  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  /// First item's title, with "+N more" when the order has several items.
  String get title {
    if (items.isEmpty) return orderNumber;
    final first = items.first.productTitle.isNotEmpty
        ? items.first.productTitle
        : orderNumber;
    return items.length > 1 ? '$first +${items.length - 1} more' : first;
  }

  String get image => items
      .map((i) => i.image)
      .firstWhere((i) => i.isNotEmpty, orElse: () => '');

  /// Items the seller can still act on with [action]
  /// (`accept` / `reject` / `preparing`).
  List<SellerOrderLine> itemsFor(String action) {
    return items.where((item) {
      final s = item.status.toLowerCase();
      if (action == 'preparing') return s == 'accepted';
      return s == 'pending' ||
          s == 'awaiting_store_response' ||
          s == 'partially_accepted';
    }).toList();
  }
}

class SellerOrderLine {
  /// order_item_id — what the accept/reject/preparing endpoints take.
  final int id;
  final String productTitle;
  final String variantTitle;
  final String image;
  final String storeName;
  final int quantity;
  final String price;
  final String subtotal;
  final String status;

  const SellerOrderLine({
    required this.id,
    required this.productTitle,
    required this.variantTitle,
    required this.image,
    required this.storeName,
    required this.quantity,
    required this.price,
    required this.subtotal,
    required this.status,
  });

  factory SellerOrderLine.fromJson(Map<String, dynamic> json) {
    final product = json['product'] is Map ? json['product'] as Map : const {};
    final variant = json['variant'] is Map ? json['variant'] as Map : const {};
    final store = json['store'] is Map ? json['store'] as Map : const {};

    return SellerOrderLine(
      id: JsonParser.intValue(json['id'] ?? json['order_item_id']),
      productTitle: JsonParser.string(
        product['title'] ?? product['name'] ?? json['title'],
      ),
      variantTitle: JsonParser.string(variant['title'] ?? variant['name']),
      image: _firstUrl([
        json['image'],
        variant['image'],
        product['image'],
        product['main_image'],
        product['image_url'],
        product['thumbnail'],
      ]),
      storeName: JsonParser.string(store['name']),
      quantity: JsonParser.intValue(json['quantity'], fallback: 1),
      price: JsonParser.string(json['price'], fallback: '0'),
      subtotal: JsonParser.string(json['subtotal'], fallback: '0'),
      status: JsonParser.string(json['status'], fallback: 'pending'),
    );
  }
}

Iterable<Map<String, dynamic>> _maps(dynamic value) =>
    value is List ? value.whereType<Map<String, dynamic>>() : const [];

String _firstUrl(List<dynamic> candidates) {
  for (final candidate in candidates) {
    final url = _nonEmpty(candidate);
    if (url != null && url.startsWith('http')) return url;
  }
  return '';
}

String? _nonEmpty(dynamic value) {
  final text = value?.toString().trim();
  return (text == null || text.isEmpty || text == 'null') ? null : text;
}
