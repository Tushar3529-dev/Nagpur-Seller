import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_local_seller/config/api_routes.dart';
import 'package:hyper_local_seller/screen/products_page/products/repo/products_repo.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';
import '../incoming_orders/helpers.dart';

void main() {
  late HttpServer server;
  late String originalRoute;
  final bodies = <Map<String, dynamic>>[];
  final paths = <String>[];
  setUpAll(() => initTestHive(token: 'inventory-test-token'));
  setUp(() async {
    originalRoute = ApiRoutes.productInventoryBaseUrl;
    bodies.clear();
    paths.clear();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    ApiRoutes.productInventoryBaseUrl =
        'http://${server.address.host}:${server.port}/api/seller/products';
    server.listen((request) async {
      paths.add(request.uri.path);
      final body =
          jsonDecode(await utf8.decoder.bind(request).join())
              as Map<String, dynamic>;
      bodies.add(body);
      expect(request.method, 'POST');
      expect(request.headers.contentType?.mimeType, 'application/json');
      expect(request.headers.value('accept'), 'application/json');
      expect(
        request.headers.value('authorization'),
        'Bearer inventory-test-token',
      );
      request.response
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode({
            'success': true,
            'message': 'Stock updated successfully',
            'data': {'new_stock': body['stock']},
          }),
        );
      await request.response.close();
    });
  });
  tearDown(() async {
    ApiRoutes.productInventoryBaseUrl = originalRoute;
    await server.close(force: true);
  });
  for (final stock in [0, 5, 25]) {
    test('posts exact inventory ID and integer total stock $stock', () async {
      expect(
        await ProductsRepo().updateInventory(
          productId: 123,
          storeProductVariantId: 789,
          stock: stock,
        ),
        stock,
      );
      expect(paths, ['/api/seller/products/123/inventory']);
      expect(bodies, [
        {'store_product_variant_id': 789, 'stock': stock},
      ]);
    });
  }
  test(
    'negative stock and missing inventory ID are rejected before HTTP',
    () async {
      await expectLater(
        ProductsRepo().updateInventory(
          productId: 123,
          storeProductVariantId: 789,
          stock: -1,
        ),
        throwsA(isA<ApiException>()),
      );
      await expectLater(
        ProductsRepo().updateInventory(
          productId: 123,
          storeProductVariantId: 0,
          stock: 5,
        ),
        throwsA(isA<ApiException>()),
      );
      expect(paths, isEmpty);
    },
  );
}
