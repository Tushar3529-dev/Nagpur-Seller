import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_local_seller/config/api_routes.dart';
import 'package:hyper_local_seller/screen/more_page/view/bag_inventory/model/bag_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/bag_inventory/repo/bags_repo.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';

import '../incoming_orders/helpers.dart';

void main() {
  late HttpServer server;
  late String originalRoute;
  late Future<void> Function(HttpRequest request, String body) handler;
  final requests = <HttpRequest>[];
  final bodies = <String>[];

  setUpAll(() => initTestHive(token: 'bags-test-token'));
  setUp(() async {
    originalRoute = ApiRoutes.bagsApi;
    requests.clear();
    bodies.clear();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    ApiRoutes.bagsApi =
        'http://${server.address.host}:${server.port}/api/seller/bags';
    server.listen((request) async {
      final body = await utf8.decoder.bind(request).join();
      requests.add(request);
      bodies.add(body);
      expect(request.headers.value('accept'), 'application/json');
      expect(request.headers.value('authorization'), 'Bearer bags-test-token');
      await handler(request, body);
    });
  });
  tearDown(() async {
    ApiRoutes.bagsApi = originalRoute;
    await server.close(force: true);
  });

  Future<void> reply(HttpRequest request, int status, Object json) async {
    request.response
      ..statusCode = status
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(json));
    await request.response.close();
  }

  test('lists bags with the status filter, search and paging', () async {
    handler = (request, _) => reply(request, 200, {
      'success': true,
      'message': 'Bags fetched successfully.',
      'data': {
        'current_page': 1,
        'last_page': 2,
        'per_page': 25,
        'total': 30,
        'items': [
          {
            'id': 34,
            'barcode': 'BAG-000034',
            'status': 'assigned',
            'seller_order_id': 701,
            'order_number': 'NM-20261001-AB3XK9ZM',
            'assigned_at': '2026-10-01T10:15:00.000000Z',
            'created_at': '2026-10-01T09:01:00.000000Z',
          },
        ],
      },
    });

    final page = await BagsRepo().getBags(status: Bag.assigned, search: 'BAG-');

    final request = requests.single;
    expect(request.method, 'GET');
    expect(request.uri.path, '/api/seller/bags');
    expect(request.uri.queryParameters, {
      'page': '1',
      'per_page': '25',
      'status': 'assigned',
      'search': 'BAG-',
    });
    expect(page.total, 30);
    expect(page.lastPage, 2);
    final bag = page.items.single;
    expect(bag.id, 34);
    expect(bag.isAssigned, isTrue);
    expect(bag.orderNumber, 'NM-20261001-AB3XK9ZM');
    expect(bag.createdAt, DateTime.utc(2026, 10, 1, 9, 1));
  });

  test('adds barcodes as a JSON array and reads skipped duplicates', () async {
    handler = (request, _) => reply(request, 201, {
      'success': true,
      'message': 'Bag barcode import completed.',
      'data': {
        'created_count': 2,
        'duplicate_count': 1,
        'created_barcodes': ['BAG-000034', 'BAG-000035'],
        'duplicate_barcodes': ['BAG-000033'],
      },
    });

    final result = await BagsRepo().addBags([
      'BAG-000033',
      'BAG-000034',
      'BAG-000035',
    ]);

    expect(requests.single.method, 'POST');
    expect(requests.single.uri.path, '/api/seller/bags/bulk');
    expect(jsonDecode(bodies.single), {
      'barcodes': ['BAG-000033', 'BAG-000034', 'BAG-000035'],
    });
    expect(result.createdCount, 2);
    expect(result.duplicateBarcodes, ['BAG-000033']);
  });

  test('updates a barcode with PUT', () async {
    handler = (request, _) => reply(request, 200, {
      'success': true,
      'message': 'Bag updated successfully.',
      'data': {
        'id': 33,
        'barcode': 'BAG-REPLACEMENT-033',
        'status': 'available',
        'created_at': '2026-10-01T09:00:00.000000Z',
      },
    });

    final bag = await BagsRepo().updateBag(33, 'BAG-REPLACEMENT-033');

    expect(requests.single.method, 'PUT');
    expect(requests.single.uri.path, '/api/seller/bags/33');
    expect(jsonDecode(bodies.single), {'barcode': 'BAG-REPLACEMENT-033'});
    expect(bag.barcode, 'BAG-REPLACEMENT-033');
  });

  test('editing an assigned bag surfaces the 409 status', () async {
    handler = (request, _) =>
        reply(request, 409, {'success': false, 'message': 'Bag is assigned.'});

    await expectLater(
      BagsRepo().updateBag(34, 'BAG-NEW'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 409)
            .having((e) => e.message, 'message', 'Bag is assigned.'),
      ),
    );
  });

  test('deletes a bag with DELETE', () async {
    handler = (request, _) => reply(request, 200, {
      'success': true,
      'message': 'Bag deleted successfully.',
      'data': {'id': 33},
    });

    await BagsRepo().deleteBag(33);

    expect(requests.single.method, 'DELETE');
    expect(requests.single.uri.path, '/api/seller/bags/33');
  });
}
