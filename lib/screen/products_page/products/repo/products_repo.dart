import 'package:dio/dio.dart';
import 'package:hyper_local_seller/config/api_routes.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';

class ProductsRepo {
  final ApiBaseHelper _helper = ApiBaseHelper();

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
      throw Exception(e.toString());
    }
  }

  Future<dynamic> getProductFilters() async {
    try {
      final response = await _helper.get(ApiRoutes.productsEnumsApi);
      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<dynamic> deleteProduct(int id) async {
    try {
      final response = await _helper.delete("${ApiRoutes.productsApi}/$id");
      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<dynamic> getProductById(int id) async {
    try {
      final response = await _helper.get("${ApiRoutes.productsApi}/$id");
      return response;
    } catch (e) {
      throw Exception(e.toString());
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
      throw Exception(e.toString());
    }
  }
}
