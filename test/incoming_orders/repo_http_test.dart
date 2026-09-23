import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_local_seller/config/api_routes.dart';
import 'package:hyper_local_seller/screen/order_page/incoming_orders/model/pending_order_model.dart';
import 'package:hyper_local_seller/screen/order_page/incoming_orders/repo/pending_orders_repo.dart';

import 'helpers.dart';

/// Runs the real repo + ApiBaseHelper (Dio, auth interceptor, response
/// checks) against a local HTTP server standing in for the backend.
void main() {
  late HttpServer server;
  late List<HttpRequest> requests;
  late Map<String, dynamic> Function(HttpRequest) respond;
  late int Function(HttpRequest) statusFor;

  setUpAll(() async {
    await initTestHive(token: 'seller-token-123');
  });

  setUp(() async {
    requests = [];
    statusFor = (_) => 200;
    respond = (_) => listResponse([]);
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      requests.add(request);
      await request.drain<void>();
      request.response
        ..statusCode = statusFor(request)
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(respond(request)));
      await request.response.close();
    });
    final base = 'http://${server.address.host}:${server.port}/api/seller';
    ApiRoutes.ordersApi = '$base/orders';
    ApiRoutes.pendingRegularOrdersApi = '$base/orders/pending-regular';
  });

  tearDown(() => server.close(force: true));

  group('GET pending orders', () {
    test('regular: correct path, query, and auth headers', () async {
      respond = (_) => listResponse([orderJson(1)]);
      final orders = await PendingOrdersRepo().getPendingOrders(
        OrderMode.regular,
      );

      final req = requests.single;
      expect(req.method, 'GET');
      expect(req.uri.path, '/api/seller/orders/pending-regular');
      expect(req.uri.queryParameters, {'order_mode': 'regular'});
      expect(req.headers.value('authorization'), 'Bearer seller-token-123');
      expect(req.headers.value('accept'), 'application/json');
      expect(orders.single.sellerOrderId, 1);
      expect(orders.single.mode, OrderMode.regular);
    });

    test('wholesale: sends popup=1', () async {
      respond = (_) =>
          listResponse([orderJson(2, mode: 'wholesale')], mode: 'wholesale');
      final orders = await PendingOrdersRepo().getPendingOrders(
        OrderMode.wholesale,
      );

      expect(requests.single.uri.queryParameters, {
        'order_mode': 'wholesale',
        'popup': '1',
      });
      expect(
        requests.single.headers.value('authorization'),
        'Bearer seller-token-123',
      );
      expect(requests.single.headers.value('accept'), 'application/json');
      expect(orders.single.isWholesale, isTrue);
    });

    test(
      'wholesale eligibility comes only from the popup API response',
      () async {
        final repo = PendingOrdersRepo();
        respond = (_) => listResponse([], mode: 'wholesale');
        expect(await repo.getPendingOrders(OrderMode.wholesale), isEmpty);

        // Old placement time and opaque delivery text must not be time-filtered
        // by Flutter: inclusion in popup=1 is the backend's eligibility decision.
        respond = (_) => listResponse([
          orderJson(
            123,
            mode: 'wholesale',
            createdAt: '2026-09-22T15:47:00.000000Z',
            itemIds: [789, 790],
            delivery: '22 Sep 21:00 - 22:00',
          ),
        ], mode: 'wholesale');
        final order = (await repo.getPendingOrders(OrderMode.wholesale)).single;
        expect(order.sellerOrderId, 123);
        expect(order.orderNumber, 'NM-20260922-123');
        expect(order.customerName, 'TUSHAR');
        expect(order.customerPhone, '8595857925');
        expect(order.customerAddress, isNotEmpty);
        expect(order.paymentMethod, 'cod');
        expect(order.total, '3798.00');
        expect(order.itemCount, 6);
        expect(order.delivery, '22 Sep 21:00 - 22:00');
        expect(order.items.map((item) => item.orderItemId), [789, 790]);
        expect(order.items.first.image, 'https://example.com/product.jpg');
        expect(order.items.first.subtotal, '1266.00');
        for (final request in requests) {
          expect(request.uri.queryParameters, {
            'order_mode': 'wholesale',
            'popup': '1',
          });
        }
      },
    );

    test('response without a "success" key is accepted', () async {
      respond = (_) => {
        'data': [orderJson(1), orderJson(2)],
        'count': 2,
        'order_mode': 'regular',
      };
      final orders = await PendingOrdersRepo().getPendingOrders(
        OrderMode.regular,
      );
      expect(orders.map((o) => o.sellerOrderId), [1, 2]);
    });

    test('older { success, data: { orders } } shape still works', () async {
      respond = (_) => {
        'success': true,
        'message': 'ok',
        'data': {
          'orders': [orderJson(7)],
        },
      };
      final orders = await PendingOrdersRepo().getPendingOrders(
        OrderMode.regular,
      );
      expect(orders.single.sellerOrderId, 7);
    });

    test('response-level order_mode tags orders that lack their own', () async {
      respond = (_) =>
          listResponse([orderJson(3)..remove('order_mode')], mode: 'wholesale');
      final orders = await PendingOrdersRepo().getPendingOrders(
        OrderMode.regular,
      );
      expect(orders.single.mode, OrderMode.wholesale);
    });

    test('empty list returns no orders', () async {
      final orders = await PendingOrdersRepo().getPendingOrders(
        OrderMode.regular,
      );
      expect(orders, isEmpty);
    });

    test('orders without a seller_order_id are dropped', () async {
      respond = (_) => listResponse([
        orderJson(1),
        orderJson(0),
        orderJson(2)..remove('seller_order_id'),
      ]);
      final orders = await PendingOrdersRepo().getPendingOrders(
        OrderMode.regular,
      );
      expect(orders.map((o) => o.sellerOrderId), [1]);
    });

    test('"success": false is still an error', () async {
      respond = (_) => {'success': false, 'message': 'Store is closed'};
      await expectLater(
        PendingOrdersRepo().getPendingOrders(OrderMode.regular),
        throwsA(predicate((e) => e.toString().contains('Store is closed'))),
      );
    });

    test('server error throws (the cubit keeps the last list)', () async {
      statusFor = (_) => 500;
      respond = (_) => {'message': 'Server Error'};
      await expectLater(
        PendingOrdersRepo().getPendingOrders(OrderMode.regular),
        throwsA(anything),
      );
    });

    test('unreachable server throws a network error', () async {
      await server.close(force: true);
      await expectLater(
        PendingOrdersRepo().getPendingOrders(OrderMode.regular),
        throwsA(anything),
      );
    });
  });

  group('image fallback', () {
    test('no extra request when the pending response has images', () async {
      respond = (_) => listResponse([orderJson(1)]);
      await PendingOrdersRepo().getPendingOrders(OrderMode.regular);
      expect(requests.length, 1);
    });

    test('missing images are looked up once from the orders list', () async {
      respond = (req) {
        if (req.uri.path.endsWith('pending-regular')) {
          return listResponse([
            orderJson(1, itemIds: [789], image: null),
          ]);
        }
        return {
          'success': true,
          'data': {
            'current_page': 1,
            'last_page': 1,
            'per_page': 50,
            'total': 1,
            'data': [
              {
                'order_item_id': 789,
                'seller_order_id': 1,
                'image': 'https://cdn.test/789.jpg',
                'order': {'id': 10, 'image': 'https://cdn.test/789.jpg'},
                'product': {'id': 5, 'title': 'Product 789'},
              },
            ],
          },
        };
      };

      final repo = PendingOrdersRepo();
      final first = await repo.getPendingOrders(OrderMode.regular);
      final lookups = requests
          .where((r) => r.uri.path == '/api/seller/orders')
          .toList();
      expect(lookups.length, 1);
      expect(lookups.single.uri.queryParameters['per_page'], '50');

      final image = first.single.items.single.image;
      // ignore: avoid_print
      print('fallback image resolved to: $image');

      // Second poll: served from cache, no new lookup.
      await repo.getPendingOrders(OrderMode.regular);
      expect(
        requests.where((r) => r.uri.path == '/api/seller/orders').length,
        1,
      );
    });

    test('failed lookup does not break the pending list', () async {
      statusFor = (req) => req.uri.path.endsWith('pending-regular') ? 200 : 500;
      respond = (req) => req.uri.path.endsWith('pending-regular')
          ? listResponse([orderJson(1, image: null)])
          : {'message': 'boom'};
      final orders = await PendingOrdersRepo().getPendingOrders(
        OrderMode.regular,
      );
      expect(orders.single.items.single.image, isNull);
    });
  });

  group('accept + preparing', () {
    test('POST to the documented paths with auth', () async {
      respond = (_) => {'success': true, 'message': 'ok'};
      final repo = PendingOrdersRepo();
      await repo.acceptItem(789);
      await repo.markItemPreparing(789);

      expect(requests.map((r) => '${r.method} ${r.uri.path}'), [
        'POST /api/seller/orders/789/accept',
        'POST /api/seller/orders/789/preparing',
      ]);
      for (final r in requests) {
        expect(r.headers.value('authorization'), 'Bearer seller-token-123');
        expect(r.headers.value('accept'), 'application/json');
      }
    });

    test('backend refusal surfaces its message', () async {
      statusFor = (_) => 422;
      respond = (_) => {'message': 'Order already cancelled'};
      await expectLater(
        PendingOrdersRepo().acceptItem(789),
        throwsA(
          predicate((e) => e.toString().contains('Order already cancelled')),
        ),
      );
    });
  });
}
