import 'package:dio/dio.dart';
import 'package:hyper_local_seller/config/api_routes.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';

class ProductsRepo {
  final ApiBaseHelper _helper = ApiBaseHelper();

  Future<int> updateInventory({
    required int productId,
    required int storeProductVariantId,
    required int stock,
  }) async {
    if (productId < 1 || storeProductVariantId < 1 || stock < 0) {
      throw ApiException('Enter a valid inventory record and stock quantity.');
    }
    final response = await _helper.post(
      '${ApiRoutes.productInventoryBaseUrl}/$productId/inventory',
      {'store_product_variant_id': storeProductVariantId, 'stock': stock},
      debugInventory: true,
    );
    final data = response is Map ? response['data'] : null;
    final value = data is Map ? data['new_stock'] : null;
    final updated = value is int ? value : int.tryParse('$value');
    if (updated == null || updated < 0) {
      throw ApiException(
        'Stock was submitted, but the updated quantity was not returned. Refresh the product to check its stock.',
      );
    }
    return updated;
  }

  Future<dynamic> getProducts({
    int? page,
    int? perPage,
    String? search,
    String? type,
    String? status,
    String? verificationStatus,
    String? productFilter,
  }) async {
    try {
      final queryParameters = {
        if (page != null) 'page': page.toString(),
        if (perPage != null) 'per_page': perPage.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
        if (type != null) 'type': type,
        if (status != null) 'status': status,
        if (verificationStatus != null)
          'verification_status': verificationStatus,
        if (productFilter != null) 'product_filter': productFilter,
      };

      final response = await _helper.get(
        ApiRoutes.productsApi,
        queryParameters: queryParameters,
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getProductFilters() async {
    try {
      final response = await _helper.get(ApiRoutes.productsEnumsApi);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> deleteProduct(int id) async {
    try {
      final response = await _helper.delete("${ApiRoutes.productsApi}/$id");
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getProductById(int id) async {
    try {
      final response = await _helper.get("${ApiRoutes.productsApi}/$id");
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Looks up the product whose variant has [barcode]. Throws an
  /// [ApiException] with status 404 when no active product has it.
  Future<dynamic> getProductByBarcode(String barcode) async {
    try {
      final response = await _helper.get(
        "${ApiRoutes.productByBarcodeApi}/${Uri.encodeComponent(barcode)}",
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> updateProductStatus(int id, String status) async {
    try {
      final Map<String, dynamic> fields = {"product_id": id, "status": status};

      final formData = FormData.fromMap(fields);

      final response = await _helper.postMultipart(
        "${ApiRoutes.productsApi}/$id/update-status",
        formData,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
