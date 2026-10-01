import 'package:hyper_local_seller/config/api_routes.dart';
import 'package:hyper_local_seller/screen/more_page/view/bag_inventory/model/bag_model.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';

class BagsRepo {
  final ApiBaseHelper _helper = ApiBaseHelper();

  /// Largest number of barcodes `POST /bags/bulk` accepts at once.
  static const int maxBulkBarcodes = 1000;

  /// [status] is [Bag.available], [Bag.assigned] or null for every bag.
  Future<BagsPage> getBags({
    int page = 1,
    int perPage = 25,
    String? status,
    String? search,
  }) async {
    final response = await _helper.get(
      ApiRoutes.bagsApi,
      queryParameters: {
        'page': page.toString(),
        'per_page': perPage.toString(),
        if (status != null) 'status': status,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return BagsPage.fromJson(response as Map<String, dynamic>);
  }

  Future<BulkAddBagsResult> addBags(List<String> barcodes) async {
    final response = await _helper.post('${ApiRoutes.bagsApi}/bulk', {
      'barcodes': barcodes,
    });
    return BulkAddBagsResult.fromJson(response as Map<String, dynamic>);
  }

  /// Throws an [ApiException] with status 409 when the bag has been assigned.
  Future<Bag> updateBag(int id, String barcode) async {
    final response = await _helper.put('${ApiRoutes.bagsApi}/$id', {
      'barcode': barcode,
    });
    return Bag.fromJson(
      (response as Map<String, dynamic>)['data'] as Map<String, dynamic>,
    );
  }

  /// Throws an [ApiException] with status 409 when the bag has been assigned.
  Future<void> deleteBag(int id) async {
    await _helper.delete('${ApiRoutes.bagsApi}/$id');
  }
}
