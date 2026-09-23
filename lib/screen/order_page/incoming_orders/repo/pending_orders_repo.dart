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

  /// Orders waiting for the seller to accept, across all of their stores.
  ///
  /// - regular: every order awaiting a response
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

  Future<dynamic> acceptItem(int orderItemId) {
    return _helper.post('${ApiRoutes.ordersApi}/$orderItemId/accept', {});
  }

  Future<dynamic> markItemPreparing(int orderItemId) {
    return _helper.post('${ApiRoutes.ordersApi}/$orderItemId/preparing', {});
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
