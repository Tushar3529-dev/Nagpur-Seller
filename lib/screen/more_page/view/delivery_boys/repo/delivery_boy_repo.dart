import 'package:hyper_local_seller/config/api_routes.dart';
import 'package:hyper_local_seller/screen/more_page/view/delivery_boys/model/delivery_boy_model.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';
import 'package:hyper_local_seller/service/json_parser.dart';

typedef DeliveryBoyResult = ({DeliveryBoy rider, String message});
typedef RiderQrResult = ({RiderQrCredential credential, String message});

class DeliveryBoyRepo {
  final ApiBaseHelper _helper = ApiBaseHelper();

  Future<DeliveryBoysListResponse> getRiders({
    int page = 1,
    int availablePage = 1,
    int perPage = 15,
    String? search,
  }) async {
    final response = await _helper.get(
      ApiRoutes.deliveryBoysApi,
      queryParameters: {
        'page': page.toString(),
        'available_page': availablePage.toString(),
        'per_page': perPage.toString(),
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    return DeliveryBoysListResponse.fromJson(
      Map<String, dynamic>.from(response),
    );
  }

  DeliveryBoyResult _rider(dynamic response) => (
    rider: DeliveryBoy.fromJson(
      Map<String, dynamic>.from(response['data']['rider']),
    ),
    message: JsonParser.string(response['message']),
  );

  Future<DeliveryBoyResult> claimRider(int riderId) async =>
      _rider(await _helper.post(ApiRoutes.claimDeliveryBoyApi(riderId), null));

  Map<String, dynamic> _body({
    required String fullName,
    required String email,
    String? mobile,
    String? password,
    required int deliveryZoneId,
  }) => {
    'full_name': fullName,
    'email': email,
    'delivery_zone_id': deliveryZoneId,
    if (mobile != null && mobile.trim().isNotEmpty) 'mobile': mobile.trim(),
    if (password != null && password.isNotEmpty) 'password': password,
  };

  Future<DeliveryBoyResult> createRider({
    required String fullName,
    required String email,
    String? mobile,
    required String password,
    required int deliveryZoneId,
  }) async => _rider(
    await _helper.post(
      ApiRoutes.deliveryBoysApi,
      _body(
        fullName: fullName,
        email: email,
        mobile: mobile,
        password: password,
        deliveryZoneId: deliveryZoneId,
      ),
    ),
  );

  Future<DeliveryBoyResult> updateRider(
    int riderId, {
    required String fullName,
    required String email,
    String? mobile,
    String? password,
    required int deliveryZoneId,
  }) async => _rider(
    await _helper.post(
      ApiRoutes.deliveryBoyApi(riderId),
      _body(
        fullName: fullName,
        email: email,
        mobile: mobile,
        password: password,
        deliveryZoneId: deliveryZoneId,
      ),
    ),
  );

  Future<String> deleteRider(int riderId) async {
    final response = await _helper.delete(ApiRoutes.deliveryBoyApi(riderId));
    return JsonParser.string(response['message']);
  }

  Future<Map<String, dynamic>> approveLogin(
    int riderId, {
    int? durationHours,
  }) async {
    final response = await _helper.post(
      ApiRoutes.approveDeliveryBoyLoginApi(riderId),
      {if (durationHours != null) 'duration_hours': durationHours},
    );
    return Map<String, dynamic>.from(response);
  }

  Future<Map<String, dynamic>> rejectLogin(int riderId) async {
    final response = await _helper.post(
      ApiRoutes.rejectDeliveryBoyLoginApi(riderId),
      null,
    );
    return Map<String, dynamic>.from(response);
  }

  Future<RiderQrCredential> getLoginQr(int riderId) async {
    final response = await _helper.get(
      ApiRoutes.deliveryBoyLoginQrApi(riderId),
    );
    return RiderQrCredential.fromJson(
      Map<String, dynamic>.from(response['data']),
    );
  }

  Future<RiderQrResult> rotateLoginQr(
    int riderId, {
    required int durationHours,
  }) async {
    final response = await _helper.post(
      ApiRoutes.rotateDeliveryBoyLoginQrApi(riderId),
      {'duration_hours': durationHours},
    );
    return (
      credential: RiderQrCredential.fromJson(
        Map<String, dynamic>.from(response['data']),
      ),
      message: JsonParser.string(response['message']),
    );
  }
}
