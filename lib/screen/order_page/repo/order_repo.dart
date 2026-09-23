import 'package:hyper_local_seller/config/api_routes.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/screen/order_page/model/order_model.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';

class OrdersRepo {
  final ApiBaseHelper _helper = ApiBaseHelper();

  Future<dynamic> getOrders({
    int? page,
    int? perPage,
    String? search,
    String? paymentType,
    String? range,
    String? sortBy,
    String? sortDir,
    String? status,
    int? storeId,
    OrderMode? orderMode,
  }) async {
    try {
      final queryParameters = {
        if (orderMode != null) 'order_mode': orderMode.name,
        if (page != null) 'page': page.toString(),
        if (perPage != null) 'per_page': perPage.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
        if (paymentType != null && paymentType.isNotEmpty)
          'payment_type': paymentType,
        if (range != null && range.isNotEmpty) 'range': range,
        if (sortBy != null && sortBy.isNotEmpty) 'sort_by': sortBy,
        if (sortDir != null && sortDir.isNotEmpty) 'sort_dir': sortDir,
        if (status != null && status.isNotEmpty) 'status': status,
        'store_id': storeId ?? HiveStorage.selectedStoreId,
      };

      final response = await _helper.get(
        ApiRoutes.ordersApi,
        queryParameters: queryParameters,
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getOrderDetails(int sellerOrderId) async {
    try {
      final response = await _helper.get(
        '${ApiRoutes.ordersApi}/$sellerOrderId',
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> updateOrderStatus(int sellerOrderId, String status) async {
    try {
      final response = await _helper.post(
        '${ApiRoutes.ordersApi}/$sellerOrderId/$status',
        {},
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// The status endpoints work per order item, so an order-level action
  /// is sent once for each of its items.
  Future<void> updateOrderItemsStatus(
    Iterable<int> orderItemIds,
    String status,
  ) async {
    for (final id in orderItemIds) {
      await updateOrderStatus(id, status);
    }
  }

  Future<dynamic> getOrderFilters() async {
    try {
      final response = await _helper.get(ApiRoutes.ordersEnumsApi);
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
