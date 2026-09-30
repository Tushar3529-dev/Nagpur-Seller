import 'package:hyper_local_seller/config/api_routes.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';
import '../model/earnings_model.dart';

class EarningRepository {
  Future<EarningsHistoryModel?> fetchSettledEarnings({
    int page = 1,
    int perPage = 15,
    String? search,
  }) async {
    try {
      final Map<String, dynamic> queryParameters = {
        'page': page,
        'per_page': perPage,
      };
      if (search != null && search.isNotEmpty) {
        queryParameters['search'] = search;
      }

      final response = await ApiBaseHelper().get(
        ApiRoutes.settledEarningsApi,
        queryParameters: queryParameters,
      );

      if (response['success'] == true || response.containsKey('data')) {
        return EarningsHistoryModel.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<EarningsHistoryModel?> fetchUnsettledEarnings({
    int page = 1,
    int perPage = 15,
    String? search,
  }) async {
    try {
      final Map<String, dynamic> queryParameters = {
        'page': page,
        'per_page': perPage,
      };
      if (search != null && search.isNotEmpty) {
        queryParameters['search'] = search;
      }

      final response = await ApiBaseHelper().get(
        ApiRoutes.unsettledCreditApi,
        queryParameters: queryParameters,
      );

      if (response['success'] == true || response.containsKey('data')) {
        return EarningsHistoryModel.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<EarningsHistoryModel?> fetchUnsettledDebitEarnings({
    int page = 1,
    int perPage = 15,
    String? search,
  }) async {
    try {
      final Map<String, dynamic> queryParameters = {
        'page': page,
        'per_page': perPage,
      };
      if (search != null && search.isNotEmpty) {
        queryParameters['search'] = search;
      }

      final response = await ApiBaseHelper().get(
        ApiRoutes.unsettledDebitApi,
        queryParameters: queryParameters,
      );

      if (response['success'] == true || response.containsKey('data')) {
        return EarningsHistoryModel.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
