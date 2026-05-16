import 'package:dio/dio.dart';
import 'package:hyper_local_seller/config/api_routes.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';

class ProductFaqRepo {
  final ApiBaseHelper _helper = ApiBaseHelper();

  Future<dynamic> getProductFaqs({
    int? page,
    int? perPage,
    String? search,
    int? productId,
  }) async {
    try {
      final queryParameters = {
        if (page != null) 'page': page.toString(),
        if (perPage != null) 'per_page': perPage.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
        if (productId != null) 'product_id': productId,
      };

      final response = await _helper.get(
        ApiRoutes.productFaqsApi,
        queryParameters: queryParameters,
      );
      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<dynamic> getProductFaq(int id) async {
    try {
      final response = await _helper.get("${ApiRoutes.productFaqsApi}/$id");
      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<dynamic> saveProductFaq({
    int? id,
    int? productId,
    String? answer,
    String? question,
    String? status,
  }) async {
    try {
      final Map<String, dynamic> fields = {
        if (productId != null) "product_id": productId,
        "answer": answer,
        "question": question,
        "status": status,
      };
      
      final formData = FormData.fromMap(fields);
      String url = ApiRoutes.productFaqsApi;
      if (id != null) {
        url = "$url/$id";
      }

      final response = await _helper.postMultipart(url, formData);

      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<dynamic> deleteProductFaq(int id) async {
    try {
      final response = await _helper.delete("${ApiRoutes.productFaqsApi}/$id");
      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
