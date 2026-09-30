import 'package:hyper_local_seller/config/api_routes.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';

class CategoriesRepo {
  final ApiBaseHelper _helper = ApiBaseHelper();

  Future<dynamic> getCategories({int? page, int? perPage, String? slug, String? search}) async {
    try {
      final queryParameters = {
        if (page != null) 'page': page.toString(),
        if (perPage != null) 'per_page': perPage.toString(),
        if (slug != null) 'slug': slug,
        if (search != null) 'search': search,
        'include_no_product': true,
      };

      final response = await _helper.get(ApiRoutes.categoriesApi, queryParameters: queryParameters);

      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
