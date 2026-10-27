import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_local_seller/screen/order_page/dispatch/repo/dispatch_repo.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';
import '../incoming_orders/helpers.dart';
import 'helpers.dart';

void main() {
  late DispatchTestServer server;
  late DispatchRepo repo;
  setUpAll(() => initTestHive(token: 'dispatch-test'));
  setUp(() async {
    server = DispatchTestServer();
    await server.start();
    repo = DispatchRepo();
  });
  tearDown(() => server.close());
  test('dashboard uses exact GET path with no query or body', () async {
    server.response = dashboardJson();
    final data = await repo.getDashboard();
    expect(data.orders.length, 2);
    final request = server.requests.single;
    expect(request.method, 'GET');
    expect(request.uri.path, '/api/seller/orders/dispatch-dashboard');
    expect(request.uri.query, isEmpty);
    expect(request.body, isEmpty);
  });
  test(
    'self-delivery uses contract order id, empty JSON body and server message',
    () async {
      server.response = {
        'success': true,
        'message': 'Order marked for seller self-delivery.',
        'data': {'order_id': 183},
      };
      expect(await repo.markSelfDelivery(183), 183);
      final request = server.requests.single;
      expect(request.method, 'POST');
      expect(request.uri.path, '/api/seller/orders/183/self-deliver');
      expect(request.uri.query, isEmpty);
      expect(jsonDecode(request.body), <String, dynamic>{});
      expect(repo.lastMessage, 'Order marked for seller self-delivery.');
      server.response['data'] = {};
      expect(await repo.markSelfDelivery(183), 183);
    },
  );
  for (final (status, message) in [
    (
      409,
      'The rider has already accepted this order. Contact dispatch to reassign it.',
    ),
    (404, 'Order not found for this seller.'),
  ]) {
    test('$status preserves server message and status', () async {
      server.status = status;
      server.response = {'success': false, 'message': message, 'data': {}};
      await expectLater(
        repo.markSelfDelivery(183),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'status', status)
              .having((e) => e.message, 'message', message),
        ),
      );
    });
  }
}
