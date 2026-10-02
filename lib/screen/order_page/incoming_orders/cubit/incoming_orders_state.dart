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
  final Map<int, String> verifiedBarcodes;
  final Map<int, Map<String, String>> itemErrors;

  /// Bags assigned in this session, by seller_order_id. They win over the
  /// order's own `bag`; a null value means the server reported none.
  final Map<int, AssignedBag?> bags;
  final int? acceptingOrderId;
  final int? assigningBagOrderId;
  final int? preparingOrderId;

  /// True while the seller is away in Bag inventory adding bags. The popup is
  /// hidden meanwhile so that page can be used.
  final bool isManagingBags;
  final int? failedOrderId;
  final String? errorMessage;

  const IncomingOrdersState({
    this.orders = const [],
    this.shownAt = const {},
    this.acceptedOrderIds = const {},
    this.verifiedItemIds = const {},
    this.verifiedBarcodes = const {},
    this.itemErrors = const {},
    this.bags = const {},
    this.acceptingOrderId,
    this.assigningBagOrderId,
    this.preparingOrderId,
    this.isManagingBags = false,
    this.failedOrderId,
    this.errorMessage,
  });

  bool get hasPending => orders.isNotEmpty;

  /// Orders the seller hasn't accepted yet — the phone rings while any exist.
  bool get hasUnaccepted => orders.any((order) => !isAccepted(order));

  bool get isBusy =>
      acceptingOrderId != null ||
      assigningBagOrderId != null ||
      preparingOrderId != null;

  bool isAccepted(PendingOrder order) =>
      acceptedOrderIds.contains(order.sellerOrderId);

  bool isVerified(PendingOrderItem item) =>
      verifiedItemIds.contains(item.orderItemId);

  int verifiedCount(PendingOrder order) => order.items.where(isVerified).length;

  bool isFullyVerified(PendingOrder order) =>
      order.items.isNotEmpty &&
      isAccepted(order) &&
      order.items.every(
        (item) =>
            isVerified(item) &&
            item.hasBarcode &&
            item.matchesCode(verifiedBarcodes[item.orderItemId] ?? ''),
      );

  AssignedBag? bagFor(PendingOrder order) =>
      bags.containsKey(order.sellerOrderId)
      ? bags[order.sellerOrderId]
      : order.bag;

  /// Every item checked and a bag assigned: the order can be dispatched.
  bool isReadyToDispatch(PendingOrder order) =>
      isFullyVerified(order) && bagFor(order) != null;

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
    Map<int, String>? verifiedBarcodes,
    Map<int, Map<String, String>>? itemErrors,
    Map<int, AssignedBag?>? bags,
    int? acceptingOrderId,
    int? assigningBagOrderId,
    int? preparingOrderId,
    bool? isManagingBags,
    int? failedOrderId,
    String? errorMessage,
    bool clearAccepting = false,
    bool clearAssigningBag = false,
    bool clearPreparing = false,
    bool clearError = false,
  }) {
    return IncomingOrdersState(
      orders: orders ?? this.orders,
      shownAt: shownAt ?? this.shownAt,
      acceptedOrderIds: acceptedOrderIds ?? this.acceptedOrderIds,
      verifiedItemIds: verifiedItemIds ?? this.verifiedItemIds,
      verifiedBarcodes: verifiedBarcodes ?? this.verifiedBarcodes,
      itemErrors: clearError ? const {} : (itemErrors ?? this.itemErrors),
      bags: bags ?? this.bags,
      acceptingOrderId: clearAccepting
          ? null
          : (acceptingOrderId ?? this.acceptingOrderId),
      assigningBagOrderId: clearAssigningBag
          ? null
          : (assigningBagOrderId ?? this.assigningBagOrderId),
      preparingOrderId: clearPreparing
          ? null
          : (preparingOrderId ?? this.preparingOrderId),
      isManagingBags: isManagingBags ?? this.isManagingBags,
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
    verifiedBarcodes,
    itemErrors,
    bags,
    acceptingOrderId,
    assigningBagOrderId,
    preparingOrderId,
    isManagingBags,
    failedOrderId,
    errorMessage,
  ];
}
