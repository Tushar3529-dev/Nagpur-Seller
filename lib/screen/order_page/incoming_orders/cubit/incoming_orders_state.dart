part of 'incoming_orders_cubit.dart';

/// Result of checking a scanned or typed code against an order's items.
enum ScanMatch { matched, alreadyVerified, notInOrder }

class IncomingOrdersState extends Equatable {
  final List<PendingOrder> orders;

  /// When each queued order (by seller_order_id) first appeared in the popup.
  final Map<int, DateTime> shownAt;

  /// Accepted orders (by seller_order_id) the seller is scanning. They stay
  /// in the popup until every item is verified and marked as preparing.
  final Set<int> acceptedOrderIds;

  /// Items (by order_item_id) whose barcode and quantity are verified.
  final Set<int> verifiedItemIds;
  final int? acceptingOrderId;
  final int? preparingOrderId;
  final int? failedOrderId;
  final String? errorMessage;

  const IncomingOrdersState({
    this.orders = const [],
    this.shownAt = const {},
    this.acceptedOrderIds = const {},
    this.verifiedItemIds = const {},
    this.acceptingOrderId,
    this.preparingOrderId,
    this.failedOrderId,
    this.errorMessage,
  });

  bool get hasPending => orders.isNotEmpty;

  /// Orders the seller hasn't accepted yet — the phone rings while any exist.
  bool get hasUnaccepted => orders.any((order) => !isAccepted(order));

  bool get isBusy => acceptingOrderId != null || preparingOrderId != null;

  bool isAccepted(PendingOrder order) =>
      acceptedOrderIds.contains(order.sellerOrderId);

  bool isVerified(PendingOrderItem item) =>
      verifiedItemIds.contains(item.orderItemId);

  int verifiedCount(PendingOrder order) => order.items.where(isVerified).length;

  bool isFullyVerified(PendingOrder order) => order.items.every(isVerified);

  /// Start of the waiting timer: order time for regular orders, popup time
  /// for wholesale orders (placed long before their popup window opens).
  DateTime? waitingSince(PendingOrder order) => order.isWholesale
      ? shownAt[order.sellerOrderId]
      : (order.createdAt ?? shownAt[order.sellerOrderId]);

  IncomingOrdersState copyWith({
    List<PendingOrder>? orders,
    Map<int, DateTime>? shownAt,
    Set<int>? acceptedOrderIds,
    Set<int>? verifiedItemIds,
    int? acceptingOrderId,
    int? preparingOrderId,
    int? failedOrderId,
    String? errorMessage,
    bool clearAccepting = false,
    bool clearPreparing = false,
    bool clearError = false,
  }) {
    return IncomingOrdersState(
      orders: orders ?? this.orders,
      shownAt: shownAt ?? this.shownAt,
      acceptedOrderIds: acceptedOrderIds ?? this.acceptedOrderIds,
      verifiedItemIds: verifiedItemIds ?? this.verifiedItemIds,
      acceptingOrderId: clearAccepting
          ? null
          : (acceptingOrderId ?? this.acceptingOrderId),
      preparingOrderId: clearPreparing
          ? null
          : (preparingOrderId ?? this.preparingOrderId),
      failedOrderId: clearError ? null : (failedOrderId ?? this.failedOrderId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    orders,
    shownAt,
    acceptedOrderIds,
    verifiedItemIds,
    acceptingOrderId,
    preparingOrderId,
    failedOrderId,
    errorMessage,
  ];
}
