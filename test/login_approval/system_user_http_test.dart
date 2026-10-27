import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hyper_local_seller/config/api_routes.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/screen/auth/repo/auth_repo.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/repo/system_users_repo.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';
import 'system_user_helpers.dart';

void main() {
  late HttpServer server;
  late List<String> original;
  final requests = <({String method, Uri uri, String body, String? token})>[];
  int status = 200;
  Map<String, dynamic> response = {};
  setUpAll(initSystemUserHive);
  setUp(() async {
    original = [
      ApiRoutes.systemUsersApi,
      ApiRoutes.loginApprovalsApi,
      ApiRoutes.loginApi,
      ApiRoutes.logoutApi,
    ];
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final root = 'http://${server.address.host}:${server.port}/api/seller';
    ApiRoutes.systemUsersApi = '$root/system-users';
    ApiRoutes.loginApprovalsApi = '$root/system-users/login-approvals';
    ApiRoutes.loginApi = '$root/login';
    ApiRoutes.logoutApi = '$root/logout';
    requests.clear();
    status = 200;
    response = {
      'success': true,
      'message': 'Updated',
      'data': {
        'user_id': 196,
        'login_approval_status': 'approved',
        'login_approved_until': '2026-10-25T14:00:00Z',
        'system_user_status': 'inactive',
      },
    };
    await HiveStorage.setAccessToken('test-session');
    server.listen((request) async {
      final body = await utf8.decoder.bind(request).join();
      expect(request.headers.value('accept'), 'application/json');
      if (body.isNotEmpty) {
        expect(request.headers.contentType?.mimeType, 'application/json');
      }
      requests.add((
        method: request.method,
        uri: request.uri,
        body: body,
        token: request.headers.value('authorization'),
      ));
      request.response
        ..statusCode = status
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(response));
      await request.response.close();
    });
  });
  tearDown(() async {
    ApiRoutes.systemUsersApi = original[0];
    ApiRoutes.loginApprovalsApi = original[1];
    ApiRoutes.loginApi = original[2];
    ApiRoutes.logoutApi = original[3];
    await server.close(force: true);
  });
  test(
    'approve sends empty default body or exact duration; revoke sends no body',
    () async {
      final repo = SystemUsersRepo();
      final result = await repo.approveLogin(196);
      expect(requests.last.method, 'POST');
      expect(
        requests.last.uri.path,
        '/api/seller/system-users/196/approve-login',
      );
      // The server sets the approval length; no body is sent.
      expect(requests.last.body, isEmpty);
      expect(result.systemUserStatus, 'inactive');
      expect(result.loginApprovedUntil!.isUtc, isFalse);
      response['data'] = {
        'user_id': 196,
        'login_approval_status': 'disapproved',
        'system_user_status': 'inactive',
        'login_approved_until': null,
      };
      final revoked = await repo.disapproveLogin(196);
      expect(
        requests.last.uri.path,
        '/api/seller/system-users/196/reject-login',
      );
      expect(requests.last.body, isEmpty);
      expect(revoked.loginApprovedUntil, isNull);
      expect(revoked.loginApprovalStatus, 'disapproved');
    },
  );
  test(
    'detail merges sibling statuses, list preserves search/page and pending uses user_id',
    () async {
      final repo = SystemUsersRepo();
      response['data'] = {
        'user': userJson(approval: 'pending', activity: 'active'),
        'login_approval_status': 'approved',
        'system_user_status': 'inactive',
      };
      final detail = await repo.getSystemUserDetail(196);
      expect(requests.last.uri.path, '/api/seller/system-users/196');
      expect(detail.isApproved, isTrue);
      expect(detail.isActive, isFalse);
      response['data'] = {
        'current_page': 2,
        'last_page': 3,
        'total': 1,
        'data': [userJson()],
      };
      await repo.getSystemUsers(page: 2, perPage: 15, search: 'packer');
      expect(requests.last.uri.queryParameters, {
        'page': '2',
        'per_page': '15',
        'search': 'packer',
      });
      response['data']['data'] = [
        {...userJson(), 'id': 999, 'user_id': 196},
      ];
      final pending = await repo.getPendingLoginApprovals();
      expect(pending.items.single.userId, 196);
      expect(
        requests.last.uri.path,
        '/api/seller/system-users/login-approvals',
      );
    },
  );
  for (final code in [403, 404, 422]) {
    test('$code preserves server message and status', () async {
      status = code;
      response = {'success': false, 'message': 'Server says no', 'data': null};
      await expectLater(
        SystemUsersRepo().approveLogin(196),
        throwsA(
          isA<ApiException>()
              .having((e) => e.message, 'message', 'Server says no')
              .having((e) => e.statusCode, 'status', code),
        ),
      );
    });
  }
  test(
    'existing create, edit, delete and role detail requests retain their contract',
    () async {
      final repo = SystemUsersRepo();
      response['data'] = {'user': userJson()};
      final detail = await repo.getSystemUserById(196);
      expect(detail['data']['user']['roles'], [
        {'name': 'packer'},
      ]);
      final create = {
        'name': 'Staff User',
        'email': 'staff@example.com',
        'mobile': '9876543210',
        'password': 'in-memory-only',
        'roles': ['packer'],
      };
      await repo.manageSystemUser(create);
      expect(requests.last.method, 'POST');
      expect(requests.last.uri.path, '/api/seller/system-users');
      expect(jsonDecode(requests.last.body), create);
      final edit = {...create, 'id': 196}..remove('password');
      await repo.manageSystemUser(edit);
      expect(requests.last.uri.path, '/api/seller/system-users/196');
      expect(jsonDecode(requests.last.body), edit);
      await repo.deleteSystemUser(196);
      expect(requests.last.method, 'DELETE');
      expect(requests.last.uri.path, '/api/seller/system-users/196');
    },
  );

  test(
    'HTTP 200 success:false never saves a token, even if a token is present',
    () async {
      await HiveStorage.setAccessToken(null);
      response = {
        'success': false,
        'message': 'Invalid credentials',
        'access_token': 'must-not-save',
        'data': [],
      };
      await expectLater(
        AuthRepository().login(
          email: 'staff@example.com',
          password: 'memory-only',
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Invalid credentials',
          ),
        ),
      );
      expect(HiveStorage.userToken, isNull);
      final preferences = await Hive.openBox('AppPrefs');
      expect(preferences.values.toString(), isNot(contains('memory-only')));
    },
  );
  test(
    'pending only on 403 + pending; non-pending 403 stays normal error',
    () async {
      await HiveStorage.setAccessToken(null);
      status = 403;
      response = {
        'success': false,
        'message': 'Waiting for seller',
        'data': {
          'login_approval_status': 'pending',
          'approval_requested_at': '2026-10-25T08:00:00Z',
        },
      };
      await expectLater(
        AuthRepository().login(
          email: 'staff@example.com',
          password: 'memory-only',
        ),
        throwsA(isA<LoginApprovalPendingException>()),
      );
      expect(HiveStorage.userToken, isNull);
      response['data'] = {'login_approval_status': 'disapproved'};
      await expectLater(
        AuthRepository().login(
          email: 'staff@example.com',
          password: 'memory-only',
        ),
        throwsA(isA<ApiException>()),
      );
      status = 200;
      response['data'] = {'login_approval_status': 'pending'};
      await expectLater(
        AuthRepository().login(
          email: 'staff@example.com',
          password: 'memory-only',
        ),
        throwsA(isA<ApiException>()),
      );
    },
  );
  test(
    'approved login sends the documented body and saves the token, user and '
    'permissions',
    () async {
      await HiveStorage.setAccessToken(null);
      await HiveStorage.setFcmToken(null);
      response = {
        'success': true,
        'message': 'Login successful.',
        'access_token': '1|sanctum-personal-access-token',
        'token_type': 'Bearer',
        'data': {'id': 196, 'name': 'Staff User', 'email': 'staff@example.com'},
        'assigned_permissions': ['product.view', 'order.view'],
      };

      await AuthRepository().login(
        email: 'staff@example.com',
        password: 'memory-only',
      );

      expect(requests.last.uri.path, '/api/seller/login');
      final body = jsonDecode(requests.last.body) as Map;
      // Email or mobile, not both; no push token is left out, not "null".
      expect(body['email'], 'staff@example.com');
      expect(body['password'], 'memory-only');
      expect(body.containsKey('mobile'), isFalse);
      expect(body.containsKey('fcm_token'), isFalse);
      expect(body['device_type'], isIn(['android', 'ios']));
      expect(HiveStorage.userToken, '1|sanctum-personal-access-token');
      expect(HiveStorage.userData?['id'], 196);
      expect(HiveStorage.userData?['assigned_permissions'], [
        'product.view',
        'order.view',
      ]);

      await HiveStorage.setFcmToken('device-token');
      await AuthRepository().login(
        email: 'staff@example.com',
        password: 'memory-only',
      );
      expect(
        (jsonDecode(requests.last.body) as Map)['fcm_token'],
        'device-token',
      );
      await HiveStorage.setFcmToken(null);
      await HiveStorage.setAccessToken('test-session');
    },
  );
  test(
    'logout reaches server with current token before local clearing',
    () async {
      await AuthRepository().logout();
      expect(requests.last.uri.path, '/api/seller/logout');
      expect(requests.last.body, isEmpty);
      expect(requests.last.token, 'Bearer test-session');
      expect(HiveStorage.userToken, isNull);
      expect(HiveStorage.userData, isNull);
    },
  );
}
