import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_local_seller/config/api_routes.dart';
import 'package:hyper_local_seller/screen/more_page/view/delivery_boys/repo/delivery_boy_repo.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';
import '../incoming_orders/helpers.dart';

void main() {
  late HttpServer server;
  late String original;
  late DeliveryBoyRepo repo;
  final requests = <({String method, Uri uri, Map<String, dynamic> body})>[];
  int status = 200;
  Map<String, dynamic> response = {};
  setUpAll(() => initTestHive(token: 'delivery-test'));
  setUp(() async {
    original = ApiRoutes.deliveryBoysApi;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    ApiRoutes.deliveryBoysApi =
        'http://${server.address.host}:${server.port}/api/seller/delivery-boys';
    requests.clear();
    status = 200;
    response = {
      'success': true,
      'message': 'Server message',
      'data': {
        'rider': {'id': 17},
      },
    };
    repo = DeliveryBoyRepo();
    server.listen((request) async {
      final body = await utf8.decoder.bind(request).join();
      expect(request.headers.value('authorization'), 'Bearer delivery-test');
      requests.add((
        method: request.method,
        uri: request.uri,
        body: body.isEmpty
            ? <String, dynamic>{}
            : Map<String, dynamic>.from(jsonDecode(body)),
      ));
      request.response
        ..statusCode = status
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(response));
      await request.response.close();
    });
  });
  tearDown(() async {
    ApiRoutes.deliveryBoysApi = original;
    await server.close(force: true);
  });

  test(
    'list query uses independent paginator parameters and omits empty search',
    () async {
      response['data'] = {
        'assigned_riders': {'current_page': 2, 'last_page': 3},
        'available_riders': {'current_page': 4, 'last_page': 5},
      };
      final page = await repo.getRiders(
        page: 2,
        availablePage: 4,
        search: '  ',
      );
      expect(requests.single.uri.queryParameters, {
        'page': '2',
        'available_page': '4',
        'per_page': '15',
      });
      expect(page.assigned.hasMore, isTrue);
      expect(page.available.currentPage, 4);
      await repo.getRiders(search: 'rider@example.com');
      expect(requests.last.uri.queryParameters['search'], 'rider@example.com');
    },
  );
  test(
    'create and update send only the contract fields, omitting empty optionals',
    () async {
      status = 201;
      final result = await repo.createRider(
        fullName: 'Name',
        email: 'r@example.com',
        password: 'password',
        deliveryZoneId: 3,
      );
      expect(requests.last.method, 'POST');
      expect(requests.last.body, {
        'full_name': 'Name',
        'email': 'r@example.com',
        'password': 'password',
        'delivery_zone_id': 3,
      });
      expect(result.message, 'Server message');
      status = 200;
      await repo.updateRider(
        17,
        fullName: 'Name',
        email: 'r@example.com',
        mobile: '',
        password: '',
        deliveryZoneId: 3,
      );
      expect(requests.last.uri.path, '/api/seller/delivery-boys/17');
      expect(requests.last.body, {
        'full_name': 'Name',
        'email': 'r@example.com',
        'delivery_zone_id': 3,
      });
      await repo.updateRider(
        17,
        fullName: 'Name',
        email: 'r@example.com',
        mobile: '9876543210',
        password: 'new-password',
        deliveryZoneId: 3,
      );
      expect(requests.last.body['mobile'], '9876543210');
      expect(requests.last.body['password'], 'new-password');
    },
  );
  test(
    'claim, delete, approve and reject use exact methods, paths and bodies',
    () async {
      await repo.claimRider(17);
      expect(requests.last.uri.path, '/api/seller/delivery-boys/17/claim');
      expect(requests.last.body, isEmpty);
      response['data'] = {'rider_id': 17, 'status': 'inactive'};
      await repo.approveLogin(17);
      expect(
        requests.last.uri.path,
        '/api/seller/delivery-boys/17/approve-login',
      );
      expect(requests.last.body, isEmpty);
      await repo.approveLogin(17, durationHours: 720);
      expect(requests.last.body, {'duration_hours': 720});
      await repo.rejectLogin(17);
      expect(
        requests.last.uri.path,
        '/api/seller/delivery-boys/17/reject-login',
      );
      expect(requests.last.body, isEmpty);
      response['data'] = [];
      await repo.deleteRider(17);
      expect(requests.last.method, 'DELETE');
      expect(requests.last.uri.path, '/api/seller/delivery-boys/17');
    },
  );
  test(
    'QR uses the exact payload, does not expose it in diagnostics and requires rotation duration',
    () async {
      response['data'] = {
        'rider_id': 17,
        'qr_token': 'unused-token',
        'qr_payload': ' exact payload ',
        'expires_at': '2099-10-25T08:00:00Z',
      };
      final credential = await repo.getLoginQr(17);
      expect(requests.last.method, 'GET');
      expect(requests.last.uri.path, '/api/seller/delivery-boys/17/login-qr');
      expect(credential.qrPayload, ' exact payload ');
      expect(credential.toString(), isNot(contains('exact payload')));
      await repo.rotateLoginQr(17, durationHours: 6);
      expect(requests.last.method, 'POST');
      expect(
        requests.last.uri.path,
        '/api/seller/delivery-boys/17/rotate-login-qr',
      );
      expect(requests.last.body, {'duration_hours': 6});
    },
  );
  test('409 and 422 preserve API messages and structured error data', () async {
    status = 409;
    response = {
      'success': false,
      'message': 'Claimed by someone else',
      'data': {'code': 'rider_already_assigned'},
    };
    await expectLater(
      repo.claimRider(17),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'status', 409)
            .having((e) => e.message, 'message', 'Claimed by someone else')
            .having(
              (e) => e.responseData?['data']['code'],
              'code',
              'rider_already_assigned',
            ),
      ),
    );
    status = 422;
    response = {
      'success': false,
      'message': 'Email is taken',
      'errors': {
        'email': ['Email is taken'],
      },
    };
    await expectLater(
      repo.createRider(
        fullName: 'Name',
        email: 'r@example.com',
        password: 'password',
        deliveryZoneId: 3,
      ),
      throwsA(
        isA<ApiException>().having(
          (e) => e.responseData?['errors']['email'],
          'field errors',
          ['Email is taken'],
        ),
      ),
    );
  });
}
