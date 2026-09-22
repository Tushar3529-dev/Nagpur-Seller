import 'package:flutter/foundation.dart';
import 'package:hyper_local_seller/config/api_routes.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/screen/order_page/incoming_orders/model/pending_order_model.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';

class PendingOrdersRepo {
  final ApiBaseHelper _helper = ApiBaseHelper();

  /// Product image per order_item_id, filled from the orders list when the
  /// pending endpoint doesn't send one.
  final Map<int, String> _imageCache = {};

  /// Items already looked up without finding an image — not retried on
  /// every poll.
  final Set<int> _imageLookupMisses = {};

  /// Pending (not yet accepted) regular orders across all of the seller's stores.
  Future<List<PendingOrder>> getPendingRegularOrders() async {
    final response = await _helper.get(
      ApiRoutes.pendingRegularOrdersApi,
      queryParameters: {'order_mode': 'regular'},
    );

    final data = response is Map<String, dynamic> ? response['data'] : null;
    final orders = data is Map<String, dynamic> ? data['orders'] : null;
    if (orders is! List) return [];

    final parsed = orders
        .whereType<Map<String, dynamic>>()
        .map(PendingOrder.fromJson)
        .where((order) => order.sellerOrderId != 0)
        .toList();
    return _withImages(parsed);
  }

  Future<dynamic> acceptItem(int orderItemId) {
    return _helper.post('${ApiRoutes.ordersApi}/$orderItemId/accept', {});
  }

  Future<dynamic> markItemPreparing(int orderItemId) {
    return _helper.post('${ApiRoutes.ordersApi}/$orderItemId/preparing', {});
  }

  Future<List<PendingOrder>> _withImages(List<PendingOrder> orders) async {
    final missing = {
      for (final order in orders)
        for (final item in order.items)
          if (item.image == null &&
              !_imageCache.containsKey(item.orderItemId) &&
              !_imageLookupMisses.contains(item.orderItemId))
            item.orderItemId,
    };
    if (missing.isNotEmpty) await _lookUpImages(missing);

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
  Future<void> _lookUpImages(Set<int> orderItemIds) async {
    try {
      final response = await _helper.get(
        ApiRoutes.ordersApi,
        queryParameters: {
          'page': '1',
          'per_page': '50',
          if (HiveStorage.selectedStoreId != null)
            'store_id': HiveStorage.selectedStoreId,
        },
      );
      final data = response is Map<String, dynamic> ? response['data'] : null;
      final rows = data is Map<String, dynamic> ? data['data'] : null;
      if (rows is List) {
        for (final row in rows.whereType<Map<String, dynamic>>()) {
          final id = int.tryParse(row['order_item_id']?.toString() ?? '');
          final order = row['order'];
          final image = order is Map ? order['image']?.toString() : null;
          if (id != null && image != null && image.startsWith('http')) {
            _imageCache[id] = image;
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
