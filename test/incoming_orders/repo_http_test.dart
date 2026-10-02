import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_local_seller/config/api_routes.dart';
import 'package:hyper_local_seller/screen/order_page/incoming_orders/model/pending_order_model.dart';
import 'package:hyper_local_seller/screen/order_page/incoming_orders/repo/pending_orders_repo.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';

import 'helpers.dart';

/// Runs the real repo + ApiBaseHelper (Dio, auth interceptor, response
/// checks) against a local HTTP server standing in for the backend.
void main() {
  late HttpServer server;
  late List<HttpRequest> requests;
  late List<String> requestBodies;
  late Map<String, dynamic> Function(HttpRequest) respond;
  late int Function(HttpRequest) statusFor;

  setUpAll(() async {
    await initTestHive(token: 'seller-token-123');
  });

  setUp(() async {
    requests = [];
    requestBodies = [];
    statusFor = (_) => 200;
    respond = (_) => listResponse([]);
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      requests.add(request);
      requestBodies.add(await utf8.decoder.bind(request).join());
      request.response
        ..statusCode = statusFor(request)
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(respond(request)));
      await request.response.close();
    });
    final base = 'http://${server.address.host}:${server.port}/api/seller';
    ApiRoutes.ordersApi = '$base/orders';
    ApiRoutes.pendingRegularOrdersApi = '$base/orders/pending-regular';
    ApiRoutes.bagsApi = '$base/bags';
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

  test(
    'acceptOrder posts one idempotent order request and preserves supplied codes',
    () async {
      respond = (_) => {'success': true};
      final order = PendingOrder.fromJson(
        orderJson(1, itemIds: [11, 12, 13], barcodes: {12: 'REAL'}),
      );
      final completed = <int>[];
      final accepted = await PendingOrdersRepo().acceptOrder(
        order,
        skipItemIds: {11},
        onItemAccepted: completed.add,
      );
      expect(requests.map((r) => '${r.method} ${r.uri.path}'), [
        'POST /api/seller/orders/1/accept-items',
      ]);
      expect(completed, [11, 12, 13]);
      expect(accepted.items.map((i) => i.barcode), ['A1', 'REAL', 'A3']);
    },
  );
  test('markOrderPreparing sends the full verified order atomically', () async {
    respond = (_) => {'success': true};
    final order = PendingOrder.fromJson(orderJson(1, itemIds: [11, 12, 13]));
    final completed = <int>[];
    await PendingOrdersRepo().markOrderPreparing(
      order,
      skipItemIds: {12},
      verifiedBarcodes: {11: 'A1', 12: 'A2', 13: 'A3'},
      onItemDone: completed.add,
    );
    expect(requests.map((r) => '${r.method} ${r.uri.path}'), [
      'POST /api/seller/orders/1/verify-and-prepare',
    ]);
    expect(completed, [11, 12, 13]);
    expect(jsonDecode(requestBodies.single), {
      'items': [
        {'order_item_id': 11, 'barcode': 'A1', 'quantity': 3},
        {'order_item_id': 12, 'barcode': 'A2', 'quantity': 3},
        {'order_item_id': 13, 'barcode': 'A3', 'quantity': 3},
      ],
    });
  });
  test('itemStatuses reads nested ids and lowercases statuses', () async {
    respond = (_) => {
      'success': true,
      'data': {
        'items': [
          {
            'id': 91,
            'orderItem': {'id': 11, 'status': 'ACCEPTED'},
          },
          {
            'id': 12,
            'orderItem': {'status': 'Preparing'},
          },
        ],
      },
    };
    expect(await PendingOrdersRepo().itemStatuses(1), {
      11: 'accepted',
      12: 'preparing',
    });
    expect(requests.single.uri.path, '/api/seller/orders/1');
  });

  test('missing pending barcode is not replaced with a dummy code', () async {
    final json = orderJson(1);
    (json['items'] as List).first.remove('barcode');
    respond = (_) => listResponse([json]);
    final order = (await PendingOrdersRepo().getPendingOrders(
      OrderMode.regular,
    )).single;
    expect(order.items.single.barcode, isNull);
    final count = requests.length;
    await expectLater(
      PendingOrdersRepo().markOrderPreparing(
        order,
        verifiedBarcodes: {1: 'A1'},
      ),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('Barcode missing'),
        ),
      ),
    );
    expect(requests.length, count, reason: 'missing data must block preparing');
  });

  test(
    'verify-and-prepare retains structured 422 errors and is atomic',
    () async {
      statusFor = (_) => 422;
      final errors = [
        {
          'order_item_id': 11,
          'field': 'barcode',
          'message': 'Incorrect barcode.',
        },
      ];
      respond = (_) => {
        'success': false,
        'message': 'Verification failed.',
        'data': {'errors': errors},
      };
      final order = PendingOrder.fromJson(
        orderJson(1, itemIds: [11], barcodes: {11: '8901234500021'}),
      );
      final completed = <int>[];
      await expectLater(
        PendingOrdersRepo().markOrderPreparing(
          order,
          verifiedBarcodes: {11: '8901234500021'},
          onItemDone: completed.add,
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'status', 422)
              .having(
                (e) => e.responseData?['data']['errors'],
                'errors',
                errors,
              ),
        ),
      );
      expect(completed, isEmpty);
      expect(requests, hasLength(1));
      expect(
        requests.single.uri.path,
        '/api/seller/orders/1/verify-and-prepare',
      );
    },
  );

  test('itemStatuses also reads direct status fields', () async {
    respond = (_) => {
      'success': true,
      'data': {
        'items': [
          {'id': 11, 'status': 'Preparing'},
        ],
      },
    };
    expect(await PendingOrdersRepo().itemStatuses(1), {11: 'preparing'});
  });

  group('accept + preparing', () {
    test('POST to the documented paths with auth', () async {
      respond = (_) => {'success': true, 'message': 'ok'};
      final repo = PendingOrdersRepo();
      await repo.acceptItem(789);
      await repo.markItemPreparing(789, barcode: '8901234500021', quantity: 2);

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

  group('bags', () {
    test('pending orders read an assigned bag for resuming', () async {
      respond = (_) => listResponse([
        {
          ...orderJson(1),
          'bag': {
            'id': 33,
            'barcode': 'BAG-000033',
            'assigned_at': '2026-10-01T10:15:00.000000Z',
          },
        },
        {...orderJson(2), 'bag': null},
      ]);
      final orders = await PendingOrdersRepo().getPendingOrders(
        OrderMode.regular,
      );
      expect(orders.first.bag?.barcode, 'BAG-000033');
      expect(orders.first.bag?.id, 33);
      expect(orders.last.bag, isNull);
      expect(PendingOrder.fromJson(orders.first.toJson()).bag?.id, 33);
    });

    test('assignBag posts the trimmed barcode to the order', () async {
      respond = (_) => {
        'success': true,
        'message': 'Bag assigned to order successfully.',
        'data': {
          'seller_order_id': 701,
          'bag': {
            'id': 33,
            'barcode': 'BAG-000033',
            'assigned_at': '2026-10-01T10:15:00.000000Z',
          },
        },
      };
      final order = PendingOrder.fromJson(orderJson(701));
      final bag = await PendingOrdersRepo().assignBag(order, ' BAG-000033 ');

      final req = requests.single;
      expect(req.method, 'POST');
      expect(req.uri.path, '/api/seller/orders/701/assign-bag');
      expect(req.headers.value('authorization'), 'Bearer seller-token-123');
      expect(jsonDecode(requestBodies.single), {'barcode': 'BAG-000033'});
      expect(bag.barcode, 'BAG-000033');
    });

    test('an unavailable bag surfaces the server message', () async {
      statusFor = (_) => 422;
      respond = (_) => {
        'success': false,
        'message': 'The bag is not available in your bag pool.',
      };
      await expectLater(
        PendingOrdersRepo().assignBag(
          PendingOrder.fromJson(orderJson(701)),
          'BAG-X',
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'The bag is not available in your bag pool.',
          ),
        ),
      );
    });

    test('a missing bag on dispatch keeps bag_required in the error', () async {
      statusFor = (_) => 422;
      respond = (_) => {
        'success': false,
        'message': 'Assign a bag before dispatch.',
        'bag_required': true,
      };
      final order = PendingOrder.fromJson(orderJson(1));
      await expectLater(
        PendingOrdersRepo().markOrderPreparing(
          order,
          verifiedBarcodes: {1: 'A1'},
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.responseData?['bag_required'],
            'bag_required',
            isTrue,
          ),
        ),
      );
    });

    test('availableBagCount asks for available bags only', () async {
      respond = (_) => {
        'success': true,
        'message': 'Bags fetched successfully.',
        'data': {'current_page': 1, 'last_page': 4, 'total': 4, 'items': []},
      };
      expect(await PendingOrdersRepo().availableBagCount(), 4);
      expect(requests.single.uri.path, '/api/seller/bags');
      expect(requests.single.uri.queryParameters, {
        'status': 'available',
        'per_page': '1',
      });
    });
  });
}
