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

  /// Bag assigned to this order before dispatch, or null when none yet.
  final AssignedBag? bag;
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
    this.bag,
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
      bag: json['bag'] is Map<String, dynamic>
          ? AssignedBag.fromJson(json['bag'] as Map<String, dynamic>)
          : null,
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(PendingOrderItem.fromJson)
          .toList(),
    );
  }

  bool get isWholesale => mode == OrderMode.wholesale;

  bool get needsAcceptance =>
      items.any((item) => item.status == 'awaiting_store_response');

  bool get isAcceptedOnServer =>
      items.isNotEmpty &&
      !needsAcceptance &&
      items.any((item) => item.status == 'accepted');

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  Map<String, dynamic> toJson() => {
    'seller_order_id': sellerOrderId,
    'order_id': orderId,
    'order_number': orderNumber,
    'order_mode': mode.name,
    'created_at': createdAt?.toIso8601String(),
    'customer': {
      'name': customerName,
      'phone': customerPhone,
      'address': customerAddress,
    },
    'payment_method': paymentMethod,
    'total': total,
    'delivery': delivery,
    'bag': bag?.toJson(),
    'items': [for (final item in items) item.toJson()],
  };

  /// [clearBag] drops the bag; otherwise a null [bag] keeps the current one.
  PendingOrder copyWith({
    List<PendingOrderItem>? items,
    AssignedBag? bag,
    bool clearBag = false,
  }) {
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
      bag: clearBag ? null : (bag ?? this.bag),
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
    bag,
    items,
  ];
}

/// A bag from the seller's inventory, assigned to one seller order.
class AssignedBag extends Equatable {
  final int id;
  final String barcode;
  final DateTime? assignedAt;

  const AssignedBag({required this.id, required this.barcode, this.assignedAt});

  factory AssignedBag.fromJson(Map<String, dynamic> json) => AssignedBag(
    id: _toInt(json['id']),
    barcode: json['barcode']?.toString() ?? '',
    assignedAt: DateTime.tryParse(json['assigned_at']?.toString() ?? ''),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'barcode': barcode,
    'assigned_at': assignedAt?.toIso8601String(),
  };

  @override
  List<Object?> get props => [id, barcode, assignedAt];
}

class PendingOrderItem extends Equatable {
  final int orderItemId;
  final String product;
  final String? variant;
  final String? image;
  final int quantity;
  final String subtotal;

  /// Code the seller must scan to verify this item before preparing.
  final String? barcode;
  final String status;
  final String? sku;
  final String? variantWeight;
  final String? variantDimensions;

  bool get hasBarcode => barcode?.trim().isNotEmpty ?? false;

  const PendingOrderItem({
    required this.orderItemId,
    required this.product,
    required this.variant,
    required this.image,
    required this.quantity,
    required this.subtotal,
    this.barcode,
    this.status = 'awaiting_store_response',
    this.sku,
    this.variantWeight,
    this.variantDimensions,
  });

  factory PendingOrderItem.fromJson(Map<String, dynamic> json) {
    return PendingOrderItem(
      orderItemId: _toInt(json['order_item_id']),
      product: json['product']?.toString() ?? '',
      variant: _nonEmpty(json['variant']),
      image: _imageFrom(json),
      quantity: _toInt(json['quantity'], fallback: 1),
      subtotal: json['subtotal']?.toString() ?? '0',
      barcode: _nonEmpty(json['barcode']),
      status: (_nonEmpty(json['status']) ?? 'awaiting_store_response')
          .toLowerCase(),
      sku: _nonEmpty(json['sku']),
      variantWeight: _nonEmpty(json['variant_weight']),
      variantDimensions: _nonEmpty(json['variant_dimensions']),
    );
  }

  Map<String, dynamic> toJson() => {
    'order_item_id': orderItemId,
    'product': product,
    'variant': variant,
    'image': image,
    'quantity': quantity,
    'subtotal': subtotal,
    'barcode': barcode,
    'status': status,
    'sku': sku,
    'variant_weight': variantWeight,
    'variant_dimensions': variantDimensions,
  };

  PendingOrderItem copyWith({String? image, String? barcode, String? status}) {
    return PendingOrderItem(
      orderItemId: orderItemId,
      product: product,
      variant: variant,
      image: image ?? this.image,
      quantity: quantity,
      subtotal: subtotal,
      barcode: barcode ?? this.barcode,
      status: status ?? this.status,
      sku: sku,
      variantWeight: variantWeight,
      variantDimensions: variantDimensions,
    );
  }

  /// Exact, case-sensitive comparison, matching the backend contract.
  bool matchesCode(String code) {
    final expected = barcode?.trim();
    return expected != null && expected.isNotEmpty && expected == code.trim();
  }

  @override
  List<Object?> get props => [
    orderItemId,
    product,
    variant,
    image,
    quantity,
    subtotal,
    barcode,
    status,
    sku,
    variantWeight,
    variantDimensions,
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
