import 'package:hyper_local_seller/config/api_routes.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';

class NotificationListRepo {
  final ApiBaseHelper _helper = ApiBaseHelper();

  Future<dynamic> getAllNotifications({int? page, int? perPage}) async {
    try {
      final queryParameters = {
        if (page != null) 'page': page.toString(),
        if (perPage != null) 'per_page': perPage.toString(),
      };

      final response = await _helper.get(
        ApiRoutes.notificationsApi,
        queryParameters: queryParameters,
      );

      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<dynamic> getUnreadCount() async {
    try {
      final response = await _helper.get(
        '${ApiRoutes.notificationsApi}/unread-count',
      );

      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<dynamic> markAsRead(String id) async {
    try {
      final response = await _helper.post(
        '${ApiRoutes.notificationsApi}/$id/read',
        {},
      );

      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<dynamic> markAsUnRead(String id) async {
    try {
      final response = await _helper.post(
        '${ApiRoutes.notificationsApi}/$id/unread',
        {},
      );

      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<dynamic> markAllRead() async {
    try {
      final response = await _helper.post(
        '${ApiRoutes.notificationsApi}/mark-all-read',
        {},
      );

      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
