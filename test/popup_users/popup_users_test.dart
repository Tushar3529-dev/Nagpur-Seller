import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_local_seller/screen/order_page/popup_users/cubit/popup_users_cubit.dart';
import 'package:hyper_local_seller/screen/order_page/popup_users/model/popup_users_model.dart';
import 'package:hyper_local_seller/screen/order_page/popup_users/repo/popup_users_repo.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';

/// The documented `GET /seller/orders/popup-users` response.
Map<String, dynamic> popupUsersJson() =>
    jsonDecode(r'''{
  "success": true,
  "message": "Seller order popup user availability fetched successfully.",
  "data": {
    "summary": {
      "total_system_users": 3,
      "active_users": 1,
      "eligible_users": 1,
      "inactive_users": 2,
      "busy_users": 0
    },
    "users": [
      {
        "user_id": 24,
        "name": "Store Operator",
        "email": "operator@example.com",
        "mobile": "+911234567890",
        "roles": ["Order Manager"],
        "system_user_status": "active",
        "login_approval_status": "approved",
        "login_approved_until": "2026-10-27T10:00:00+00:00",
        "has_order_popup_permission": true,
        "popup_presence_active": true,
        "location_fresh": true,
        "last_seen_at": "2026-10-26T05:00:00+00:00",
        "nearest_store": {"id": 10, "name": "Store One", "distance_m": 82},
        "has_fcm_token": true,
        "is_active": true,
        "is_eligible": true,
        "ineligible_reason": null,
        "current_offer": null
      },
      {
        "user_id": 25,
        "name": "Packer",
        "roles": [],
        "system_user_status": "active",
        "login_approval_status": "pending",
        "has_order_popup_permission": true,
        "popup_presence_active": false,
        "location_fresh": false,
        "last_seen_at": null,
        "nearest_store": null,
        "has_fcm_token": false,
        "is_active": false,
        "is_eligible": false,
        "ineligible_reason": "login_not_approved_or_expired",
        "current_offer": {"seller_order_id": 701, "order_number": "NM-1"}
      },
      {
        "user_id": 26,
        "name": "Adam",
        "is_eligible": false,
        "ineligible_reason": "some_new_reason"
      }
    ],
    "location_freshness_minutes": 2,
    "pickup_radius_meters": 200
  }
}''')
        as Map<String, dynamic>;

class _FakeRepo extends PopupUsersRepo {
  Object? error;
  int calls = 0;

  @override
  Future<PopupUsersAvailability> getAvailability() async {
    calls++;
    if (error case final e?) throw e;
    return PopupUsersAvailability.fromJson(popupUsersJson());
  }
}

void main() {
  test('parses the documented response', () {
    final data = PopupUsersAvailability.fromJson(popupUsersJson());
    expect(
      data.summary,
      const PopupUsersSummary(
        totalSystemUsers: 3,
        activeUsers: 1,
        eligibleUsers: 1,
        inactiveUsers: 2,
      ),
    );
    expect(data.pickupRadiusMeters, 200);
    expect(data.locationFreshnessMinutes, 2);

    final operator = data.users.first;
    expect(operator.userId, 24);
    expect(operator.roles, ['Order Manager']);
    expect(operator.isEligible, isTrue);
    expect(operator.ineligibleReason, isNull);
    expect(operator.nearestStore, const PopupNearestStore(
      id: 10,
      name: 'Store One',
      distanceM: 82,
    ));
    expect(
      operator.loginApprovedUntil,
      DateTime.parse('2026-10-27T10:00:00+00:00').toLocal(),
    );
    expect(operator.currentOffer, isNull);

    final packer = data.users[1];
    expect(packer.ineligibleReason, PopupIneligibleReason.loginNotApproved);
    expect(packer.lastSeenAt, isNull);
    expect(packer.email, isNull);
    expect(packer.currentOffer?.label, 'NM-1');

    final unknown = data.users[2];
    expect(unknown.ineligibleReason, isNull);
    expect(unknown.rawIneligibleReason, 'some_new_reason');
  });

  test('every documented ineligible_reason is recognised', () {
    for (final raw in [
      'account_inactive',
      'system_user_inactive',
      'login_not_approved_or_expired',
      'order_popup_permission_missing',
      'popup_presence_inactive',
      'location_stale',
      'location_or_store_unavailable',
      'outside_200m_radius',
      'order_in_progress',
    ]) {
      expect(PopupIneligibleReason.tryParse(raw), isNotNull, reason: raw);
    }
  });

  test('eligible users are listed first', () {
    final state = PopupUsersState(
      data: PopupUsersAvailability.fromJson(popupUsersJson()),
    );
    expect(state.sortedUsers.map((u) => u.userId), [24, 25, 26]);
  });

  group('access', () {
    test('the owner gets the dashboard', () async {
      final repo = _FakeRepo();
      final cubit = PopupUsersCubit(repo);
      addTearDown(cubit.close);

      await cubit.checkAccess();
      expect(cubit.state.hasAccess, isTrue);

      await cubit.checkAccess();
      expect(repo.calls, 1, reason: 'access is only checked once');
    });

    test('a 403 hides the dashboard and stops asking', () async {
      final repo = _FakeRepo()
        ..error = ApiException('Forbidden', statusCode: 403);
      final cubit = PopupUsersCubit(repo);
      addTearDown(cubit.close);

      await cubit.checkAccess();
      expect(cubit.state.isForbidden, isTrue);
      expect(cubit.state.hasAccess, isFalse);

      await cubit.refresh();
      cubit.startPolling();
      expect(repo.calls, 1);
    });

    test('a network error keeps access unknown and can be retried', () async {
      final repo = _FakeRepo()..error = ApiException('No Internet Connection');
      final cubit = PopupUsersCubit(repo);
      addTearDown(cubit.close);

      await cubit.checkAccess();
      expect(cubit.state.hasAccess, isFalse);
      expect(cubit.state.isForbidden, isFalse);
      expect(cubit.state.error, 'No Internet Connection');

      repo.error = null;
      await cubit.checkAccess();
      expect(cubit.state.hasAccess, isTrue);
    });

    test('reset forgets access for the next user', () async {
      final repo = _FakeRepo()
        ..error = ApiException('Forbidden', statusCode: 403);
      final cubit = PopupUsersCubit(repo);
      addTearDown(cubit.close);
      await cubit.checkAccess();

      cubit.reset();
      repo.error = null;
      await cubit.checkAccess();
      expect(cubit.state.hasAccess, isTrue);
    });
  });
}
