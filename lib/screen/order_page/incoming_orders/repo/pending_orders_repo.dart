import 'package:flutter/foundation.dart';
import 'package:hyper_local_seller/config/api_routes.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/screen/order_page/incoming_orders/model/pending_order_model.dart';
import 'package:hyper_local_seller/screen/order_page/model/order_model.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';

class PendingOrdersRepo {
  final ApiBaseHelper _helper = ApiBaseHelper();

  /// Product image per order_item_id, filled from the orders list when the
  /// pending endpoint doesn't send one.
  final Map<int, String> _imageCache = {};

  /// Items already looked up without finding an image — not retried on
  /// every poll.
  final Set<int> _imageLookupMisses = {};

  /// Orders awaiting acceptance or scanning, across all seller stores.
  ///
  /// - regular: every order awaiting a response or still accepted
  /// - wholesale: `popup=1` makes the backend return only orders whose
  ///   delivery slot ends within 30 minutes, so no time filtering here.
  Future<List<PendingOrder>> getPendingOrders(OrderMode mode) async {
    final response = await _helper.get(
      ApiRoutes.pendingRegularOrdersApi,
      queryParameters: {
        'order_mode': mode.name,
        if (mode == OrderMode.wholesale) 'popup': '1',
      },
      allowMissingSuccessFlag: true,
    );
    if (response is! Map<String, dynamic>) return [];

    // Current shape: { data: [...], count, order_mode }.
    // Older shape:   { success, data: { orders: [...] } }.
    final data = response['data'];
    final orders = data is List
        ? data
        : (data is Map<String, dynamic> ? data['orders'] : null);
    if (kDebugMode) {
      debugPrint(
        '[PendingOrdersRepo] ${mode.name}: '
        '${orders is List ? orders.length : "unreadable"} pending',
      );
    }
    if (orders is! List) return [];

    final responseMode = OrderMode.tryParse(response['order_mode']) ?? mode;
    final parsed = orders
        .whereType<Map<String, dynamic>>()
        .map((json) => PendingOrder.fromJson(json, fallbackMode: responseMode))
        .where((order) => order.sellerOrderId != 0)
        .toList();
    return _withImages(parsed, mode);
  }

  /// The pending response already supplies packing details and barcodes.
  /// Acceptance is idempotent and applies to the complete seller order.
  Future<PendingOrder> acceptOrder(
    PendingOrder order, {
    Set<int> skipItemIds = const {},
    void Function(int orderItemId)? onItemAccepted,
  }) async {
    await _helper.post(
      '${ApiRoutes.ordersApi}/${order.sellerOrderId}/accept-items',
      {},
    );
    for (final item in order.items) {
      onItemAccepted?.call(item.orderItemId);
    }
    return order.copyWith(
      items: [
        for (final item in order.items) item.copyWith(status: 'accepted'),
      ],
    );
  }

  /// Submit every locally verified value; the server checks the entire set
  /// atomically before preparing. Never fall back to per-item status calls.
  /// TODO(backend): confirm retry behavior after a successful response is lost.
  Future<void> markOrderPreparing(
    PendingOrder order, {
    Map<int, String> verifiedBarcodes = const {},
    Set<int> skipItemIds = const {},
    void Function(int orderItemId)? onItemDone,
  }) async {
    for (final item in order.items) {
      if (!item.hasBarcode) {
        throw ApiException(
          'Barcode missing for ${item.product}. Contact support.',
        );
      }
      if (!item.matchesCode(verifiedBarcodes[item.orderItemId] ?? '')) {
        throw ApiException('Scan and verify ${item.product} before preparing.');
      }
    }
    await _helper.post(
      '${ApiRoutes.ordersApi}/${order.sellerOrderId}/verify-and-prepare',
      {
        'items': [
          for (final item in order.items)
            {
              'order_item_id': item.orderItemId,
              'barcode': verifiedBarcodes[item.orderItemId],
              'quantity': item.quantity,
            },
        ],
      },
    );
    for (final item in order.items) {
      onItemDone?.call(item.orderItemId);
    }
  }

  /// Assigns an available bag from the seller's inventory to [order]. The
  /// server rejects unknown bags and bags assigned elsewhere with a 422.
  Future<AssignedBag> assignBag(PendingOrder order, String barcode) async {
    final response = await _helper.post(
      '${ApiRoutes.ordersApi}/${order.sellerOrderId}/assign-bag',
      {'barcode': barcode.trim()},
    );
    final bag = (response as Map<String, dynamic>)['data']?['bag'];
    if (bag is! Map<String, dynamic>) {
      throw ApiException('The bag was not assigned. Try again.');
    }
    return AssignedBag.fromJson(bag);
  }

  /// Number of bags in the seller's inventory not yet assigned to an order.
  Future<int> availableBagCount() async {
    final response = await _helper.get(
      ApiRoutes.bagsApi,
      queryParameters: {'status': 'available', 'per_page': '1'},
    );
    final total = (response as Map<String, dynamic>)['data']?['total'];
    return total is num ? total.toInt() : int.tryParse('$total') ?? 0;
  }

  Future<dynamic> acceptItem(int orderItemId) {
    return _helper.post('${ApiRoutes.ordersApi}/$orderItemId/accept', {});
  }

  Future<dynamic> markItemPreparing(
    int orderItemId, {
    String? barcode,
    int? quantity,
  }) {
    if (barcode == null ||
        barcode.trim().isEmpty ||
        quantity == null ||
        quantity < 1) {
      throw ApiException(
        'Scan the barcode and confirm the quantity before preparing.',
      );
    }
    return _helper.post('${ApiRoutes.ordersApi}/$orderItemId/preparing', {
      'barcode': barcode,
      'quantity': quantity,
    });
  }

  /// Current status of each item of a seller order, keyed by order_item_id,
  /// used to check an order restored from the device is still waiting to be
  /// prepared.
  Future<Map<int, String>> itemStatuses(int sellerOrderId) async {
    final response = await _helper.get('${ApiRoutes.ordersApi}/$sellerOrderId');
    final data = response is Map ? response['data'] : null;
    final items = data is Map ? data['items'] : null;
    if (items is! List) return {};
    return {
      for (final item in items.whereType<Map>())
        if (int.tryParse('${(item['orderItem'] as Map?)?['id'] ?? item['id']}')
            case final id?)
          id: '${(item['orderItem'] as Map?)?['status'] ?? item['status'] ?? ''}'
              .toLowerCase(),
    };
  }

  Future<List<PendingOrder>> _withImages(
    List<PendingOrder> orders,
    OrderMode mode,
  ) async {
    final missing = {
      for (final order in orders)
        for (final item in order.items)
          if (item.image == null &&
              !_imageCache.containsKey(item.orderItemId) &&
              !_imageLookupMisses.contains(item.orderItemId))
            item.orderItemId,
    };
    if (missing.isNotEmpty) await _lookUpImages(missing, mode);

    return [
      for (final order in orders)
        order.copyWith(
          items: [
            for (final item in order.items)
              item.image != null
                  ? item
                  : item.copyWith(image: _imageCache[item.orderItemId]),
          ],
        ),
    ];
  }

  /// The orders list (`GET /seller/orders`) carries an image per order item.
  /// It's scoped to the selected store, so orders from other stores keep the
  /// placeholder until the pending endpoint sends images itself.
  Future<void> _lookUpImages(Set<int> orderItemIds, OrderMode mode) async {
    try {
      final response = await _helper.get(
        ApiRoutes.ordersApi,
        queryParameters: {
          'page': '1',
          'per_page': '50',
          'order_mode': mode.name,
          if (HiveStorage.selectedStoreId != null)
            'store_id': HiveStorage.selectedStoreId,
        },
      );
      if (response is Map<String, dynamic>) {
        final orders = OrdersResponse.fromJson(response).data?.items ?? [];
        for (final item in orders.expand((order) => order.items)) {
          if (item.id != 0 && item.image.isNotEmpty) {
            _imageCache[item.id] = item.image;
          }
        }
      }
    } catch (e) {
      debugPrint('[PendingOrdersRepo] image lookup failed: $e');
      return; // Network error — try again on the next poll.
    }
    _imageLookupMisses.addAll(
      orderItemIds.where((id) => !_imageCache.containsKey(id)),
    );
  }
}
