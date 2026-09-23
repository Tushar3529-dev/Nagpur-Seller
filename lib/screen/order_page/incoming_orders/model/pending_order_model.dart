import 'package:equatable/equatable.dart';

/// Which pending list an order came from. The backend only returns wholesale
/// orders (`popup=1`) once their delivery slot ends within 30 minutes.
enum OrderMode {
  regular,
  wholesale;

  static OrderMode? tryParse(dynamic value) {
    switch (value?.toString().toLowerCase()) {
      case 'regular':
        return OrderMode.regular;
      case 'wholesale':
        return OrderMode.wholesale;
      default:
        return null;
    }
  }
}

/// One order that the seller hasn't accepted yet, as returned by
/// `GET /seller/orders/pending-regular?order_mode=...`.
class PendingOrder extends Equatable {
  final int sellerOrderId;
  final int orderId;
  final String orderNumber;
  final OrderMode mode;
  final DateTime? createdAt;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final String paymentMethod;
  final String total;

  /// Delivery date and slot as the backend formats it, e.g. "22 Sep 21:00 - 22:00".
  final String? delivery;
  final List<PendingOrderItem> items;

  const PendingOrder({
    required this.sellerOrderId,
    required this.orderId,
    required this.orderNumber,
    required this.mode,
    required this.createdAt,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.paymentMethod,
    required this.total,
    required this.delivery,
    required this.items,
  });

  /// [fallbackMode] is the mode that was requested, used when neither the
  /// order nor the response says which list it belongs to.
  factory PendingOrder.fromJson(
    Map<String, dynamic> json, {
    OrderMode fallbackMode = OrderMode.regular,
  }) {
    final customer = json['customer'] is Map<String, dynamic>
        ? json['customer'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final rawItems = json['items'] is List ? json['items'] as List : const [];

    return PendingOrder(
      sellerOrderId: _toInt(json['seller_order_id']),
      orderId: _toInt(json['order_id']),
      orderNumber: json['order_number']?.toString() ?? '',
      mode: OrderMode.tryParse(json['order_mode']) ?? fallbackMode,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      customerName: customer['name']?.toString() ?? '',
      customerPhone: customer['phone']?.toString() ?? '',
      customerAddress: customer['address']?.toString() ?? '',
      paymentMethod: json['payment_method']?.toString() ?? '',
      total: json['total']?.toString() ?? '0',
      delivery: _nonEmpty(json['delivery'] ?? json['delivery_slot']),
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(PendingOrderItem.fromJson)
          .toList(),
    );
  }

  bool get isWholesale => mode == OrderMode.wholesale;

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  PendingOrder copyWith({List<PendingOrderItem>? items}) {
    return PendingOrder(
      sellerOrderId: sellerOrderId,
      orderId: orderId,
      orderNumber: orderNumber,
      mode: mode,
      createdAt: createdAt,
      customerName: customerName,
      customerPhone: customerPhone,
      customerAddress: customerAddress,
      paymentMethod: paymentMethod,
      total: total,
      delivery: delivery,
      items: items ?? this.items,
    );
  }

  @override
  List<Object?> get props => [
    sellerOrderId,
    orderNumber,
    mode,
    createdAt,
    total,
    delivery,
    items,
  ];
}

class PendingOrderItem extends Equatable {
  final int orderItemId;
  final String product;
  final String? variant;
  final String? image;
  final int quantity;
  final String subtotal;

  const PendingOrderItem({
    required this.orderItemId,
    required this.product,
    required this.variant,
    required this.image,
    required this.quantity,
    required this.subtotal,
  });

  factory PendingOrderItem.fromJson(Map<String, dynamic> json) {
    return PendingOrderItem(
      orderItemId: _toInt(json['order_item_id']),
      product: json['product']?.toString() ?? '',
      variant: _nonEmpty(json['variant']),
      image: _imageFrom(json),
      quantity: _toInt(json['quantity'], fallback: 1),
      subtotal: json['subtotal']?.toString() ?? '0',
    );
  }

  PendingOrderItem copyWith({String? image}) {
    return PendingOrderItem(
      orderItemId: orderItemId,
      product: product,
      variant: variant,
      image: image ?? this.image,
      quantity: quantity,
      subtotal: subtotal,
    );
  }

  @override
  List<Object?> get props => [
    orderItemId,
    product,
    variant,
    image,
    quantity,
    subtotal,
  ];
}

/// The pending endpoint doesn't document an image field yet, so accept the
/// names the backend uses elsewhere.
String? _imageFrom(Map<String, dynamic> json) {
  final product = json['product'];
  final candidates = [
    json['image'],
    json['product_image'],
    json['image_url'],
    json['main_image'],
    json['thumbnail'],
    if (product is Map) ...[product['image'], product['main_image']],
  ];
  for (final candidate in candidates) {
    final url = _nonEmpty(candidate);
    if (url != null && url.startsWith('http')) return url;
  }
  return null;
}

int _toInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

String? _nonEmpty(dynamic value) {
  final text = value?.toString().trim();
  return (text == null || text.isEmpty || text == 'null') ? null : text;
}
