import 'package:dio/dio.dart';
import 'package:hyper_local_seller/config/api_routes.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';

class AttributesRepo {
  final ApiBaseHelper _helper = ApiBaseHelper();

  Future<dynamic> getAttributes({int? page, int? perPage, String? search}) async {
    try {
      final queryParameters = {
        if (page != null) 'page': page.toString(),
        if (perPage != null) 'per_page': perPage.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final response = await _helper.get(
        ApiRoutes.attributesApi,
        queryParameters: queryParameters,
      );

      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<dynamic> addAttribute(Map<String, dynamic> data) async {
    try {
      final response = await _helper.post(ApiRoutes.attributesApi, data);
      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<dynamic> updateAttribute(int id, Map<String, dynamic> data) async {
    try {
      final response = await _helper.post('${ApiRoutes.attributesApi}/$id', data);
      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<dynamic> deleteAttribute(int id) async {
    try {
      final response = await _helper.delete('${ApiRoutes.attributesApi}/$id');
      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<dynamic> getAttributeValues(int attributeId) async {
    try {
      final response = await _helper.get(
        '${ApiRoutes.attributesApi}/$attributeId',
      );
      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<dynamic> addAttributeValue(Map<String, dynamic> data) async {
    try {
      // Check if any swatch is an image (local file path)
      // Check if swatche_type is 'image'
      bool hasImage = data['swatche_type'] == 'image';

      if (hasImage) {
        final Map<String, dynamic> fields = {
          "attribute_id": data['attribute_id'],
        };

        final List<String> values = data['values'] is List ? List<String>.from(data['values']) : [data['title']];
        for (int i = 0; i < values.length; i++) {
          fields['values[$i]'] = values[i];
        }

        final List<dynamic> swatches = data['swatche_value'] is List ? data['swatche_value'] : [data['swatche_value']];
        for (int i = 0; i < swatches.length; i++) {
          final swatch = swatches[i].toString();
          if (swatch.isNotEmpty && !swatch.startsWith('http')) {
            fields['swatche_value[$i]'] = await MultipartFile.fromFile(swatch);
          } else {
            fields['swatche_value[$i]'] = swatch;
          }
        }

        final formData = FormData.fromMap(fields);
        return await _helper.postMultipart(ApiRoutes.attributeValueApi, formData);
      }

      final response = await _helper.post(ApiRoutes.attributeValueApi, data);
      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<dynamic> updateAttributeValue(int id, Map<String, dynamic> data) async {
    try {
      final List swatches = data['swatche_value'] is List ? data['swatche_value'] : [data['swatche_value']];
      final List values = data['values'] is List ? data['values'] : [data['title'] ?? ""];
      
      final swatch = swatches.isNotEmpty ? swatches[0].toString() : "";
      final bool isImage = data['swatche_type'] == 'image' && swatch.isNotEmpty && !swatch.startsWith('http');

      if (isImage) {
        final Map<String, dynamic> fields = {
          "attribute_id": data['attribute_id'],
          "values[0]": values.isNotEmpty ? values[0] : "",
          "swatche_value[0]": await MultipartFile.fromFile(swatch),
        };
        
        final formData = FormData.fromMap(fields);
        return await _helper.postMultipart('${ApiRoutes.attributeValueApi}/$id', formData);
      }

      final response = await _helper.post('${ApiRoutes.attributeValueApi}/$id', data);
      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<dynamic> deleteAttributeValue(int id) async {
    try {
      final response = await _helper.delete('${ApiRoutes.attributeValueApi}/$id');
      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
