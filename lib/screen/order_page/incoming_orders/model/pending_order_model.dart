import 'package:equatable/equatable.dart';

/// One regular order that the seller hasn't accepted yet, as returned by
/// `GET /seller/orders/pending-regular`.
class PendingOrder extends Equatable {
  final int sellerOrderId;
  final int orderId;
  final String orderNumber;
  final DateTime? createdAt;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final String paymentMethod;
  final String total;
  final String? deliverySlot;
  final List<PendingOrderItem> items;

  const PendingOrder({
    required this.sellerOrderId,
    required this.orderId,
    required this.orderNumber,
    required this.createdAt,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.paymentMethod,
    required this.total,
    required this.deliverySlot,
    required this.items,
  });

  factory PendingOrder.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] is Map<String, dynamic>
        ? json['customer'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final rawItems = json['items'] is List ? json['items'] as List : const [];

    return PendingOrder(
      sellerOrderId: _toInt(json['seller_order_id']),
      orderId: _toInt(json['order_id']),
      orderNumber: json['order_number']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      customerName: customer['name']?.toString() ?? '',
      customerPhone: customer['phone']?.toString() ?? '',
      customerAddress: customer['address']?.toString() ?? '',
      paymentMethod: json['payment_method']?.toString() ?? '',
      total: json['total']?.toString() ?? '0',
      deliverySlot: _nonEmpty(json['delivery_slot']),
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(PendingOrderItem.fromJson)
          .toList(),
    );
  }

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  PendingOrder copyWith({List<PendingOrderItem>? items}) {
    return PendingOrder(
      sellerOrderId: sellerOrderId,
      orderId: orderId,
      orderNumber: orderNumber,
      createdAt: createdAt,
      customerName: customerName,
      customerPhone: customerPhone,
      customerAddress: customerAddress,
      paymentMethod: paymentMethod,
      total: total,
      deliverySlot: deliverySlot,
      items: items ?? this.items,
    );
  }

  @override
  List<Object?> get props => [
    sellerOrderId,
    orderNumber,
    createdAt,
    total,
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
