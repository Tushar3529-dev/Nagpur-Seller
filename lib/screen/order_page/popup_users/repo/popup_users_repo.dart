import 'package:hyper_local_seller/config/api_routes.dart';
import 'package:hyper_local_seller/screen/order_page/popup_users/model/popup_users_model.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';

class PopupUsersRepo {
  final ApiBaseHelper _helper = ApiBaseHelper();

  /// Owner only; other users get a 403.
  Future<PopupUsersAvailability> getAvailability() async =>
      PopupUsersAvailability.fromJson(
        Map<String, dynamic>.from(await _helper.get(ApiRoutes.popupUsersApi)),
      );
}
