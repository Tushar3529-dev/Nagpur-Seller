import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_local_seller/screen/order_page/dispatch/model/dispatch_model.dart';
import 'package:hyper_local_seller/screen/order_page/dispatch/repo/dispatch_repo.dart';
import 'package:hyper_local_seller/screen/order_page/dispatch/cubit/rider_availability_cubit.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';
import '../incoming_orders/helpers.dart';
import 'helpers.dart';

void main() {
  test(
    'exact availability sample preserves summary, fields and nullable values',
    () {
      final data = RiderAvailability.fromJson(availabilityJson());
      expect(
        data.summary,
        const RiderAvailabilitySummary(
          activeRiders: 4,
          availableRidersInRadius: 2,
          inactiveRiders: 3,
        ),
      );
      expect(data.riders.length, 2);
      final rider = data.riders.first;
      expect(rider.id, 5);
      expect(rider.name, 'Rider Name');
      expect(rider.status, 'active');
      expect(rider.verificationStatus, 'verified');
      expect(rider.deliveryZone, 'Dharampeth');
      expect(rider.isAvailableInRadius, isTrue);
      expect(rider.nearestPickupDistanceM, 84);
      expect(
        rider.locationReportedAt,
        DateTime.parse('2026-10-25T10:00:00+00:00').toLocal(),
      );
      expect(rider.locationReportedAt!.isUtc, isFalse);
      expect(rider.locationAgeSeconds, 18);
      expect(rider.unavailableReason, isNull);
      expect(rider.rawUnavailableReason, isNull);
      final stale = data.riders.last;
      expect(stale.id, 6);
      expect(stale.name, 'Another Rider');
      expect(stale.isAvailableInRadius, isFalse);
      expect(stale.nearestPickupDistanceM, isNull);
      expect(stale.locationAgeSeconds, 378);
      expect(stale.unavailableReason, RiderUnavailableReason.locationStale);
      final empty = AvailableRider.fromJson({});
      expect(empty.deliveryZone, isNull);
      expect(empty.locationReportedAt, isNull);
      expect(empty.locationAgeSeconds, isNull);
      expect(empty.nearestPickupDistanceM, isNull);
      expect(empty.unavailableReason, isNull);
      expect(
        RiderAvailability.fromJson({}).summary,
        const RiderAvailabilitySummary(),
      );
      expect(RiderAvailability.fromJson({'data': {}}).riders, isEmpty);
    },
  );
  test(
    'live payload: float location_age_seconds, IST offset, epoch seconds and numeric strings',
    () {
      // Shape captured from production on 2026-10-26 (Rider #5).
      final live = AvailableRider.fromJson({
        'id': 5,
        'name': 'Nagpurmart Rider',
        'status': 'active',
        'verification_status': 'verified',
        'delivery_zone': 'Sohna',
        'is_available_in_radius': true,
        'nearest_pickup_distance_m': 38,
        'location_reported_at': '2026-10-26T19:31:42+05:30',
        'location_age_seconds': 41.439322999999995,
        'unavailable_reason': null,
      });
      expect(live.locationAgeSeconds, 41);
      expect(
        live.locationReportedAt!.toUtc(),
        DateTime.utc(2026, 10, 26, 14, 1, 42),
      );
      expect(live.locationReportedAt!.isUtc, isFalse);
      expect(live.nearestPickupDistanceM, 38);

      final epoch = AvailableRider.fromJson({
        'location_reported_at': 1793021677,
        'location_age_seconds': '41.44',
        'nearest_pickup_distance_m': '38.0',
      });
      expect(
        epoch.locationReportedAt!.toUtc(),
        DateTime.utc(2026, 10, 26, 13, 34, 37),
      );
      expect(epoch.locationReportedAt!.isUtc, isFalse);
      expect(epoch.locationAgeSeconds, 41);
      expect(epoch.nearestPickupDistanceM, 38);
      expect(
        AvailableRider.fromJson({
          'location_reported_at': '1793021677',
        }).locationReportedAt!.toUtc(),
        DateTime.utc(2026, 10, 26, 13, 34, 37),
      );

      final order = DispatchOrder.fromJson({
        'pickup_latitude': '21.16110000',
        'pickup_longitude': '79.05610000',
      });
      expect(order.pickupLatitude, 21.1611);
      expect(order.pickupLongitude, 79.0561);
    },
  );
  test(
    'all eight reasons parse, including no_pickup_store, and unknown keeps raw',
    () {
      const reasons = {
        'inactive': RiderUnavailableReason.inactive,
        'not_verified': RiderUnavailableReason.notVerified,
        'no_fcm_token': RiderUnavailableReason.noFcmToken,
        'location_stale': RiderUnavailableReason.locationStale,
        'no_pickup_store': RiderUnavailableReason.noPickupStore,
        'outside_pickup_radius': RiderUnavailableReason.outsidePickupRadius,
        'pending_offer': RiderUnavailableReason.pendingOffer,
        'active_delivery': RiderUnavailableReason.activeDelivery,
        'future_reason': RiderUnavailableReason.unknown,
      };
      for (final entry in reasons.entries) {
        final rider = AvailableRider.fromJson({
          'unavailable_reason': entry.key,
        });
        expect(rider.unavailableReason, entry.value);
        expect(rider.rawUnavailableReason, entry.key);
      }
    },
  );
  group('repo', () {
    late DispatchTestServer server;
    setUpAll(() => initTestHive(token: 'dispatch-test'));
    setUp(() async {
      server = DispatchTestServer();
      await server.start();
    });
    tearDown(() => server.close());
    test('availability uses only exact GET without query parameters', () async {
      server.response = availabilityJson();
      final result = await DispatchRepo().getRiderAvailability();
      expect(result.riders.length, 2);
      final request = server.requests.single;
      expect(request.method, 'GET');
      expect(request.uri.path, '/api/seller/orders/rider-availability');
      expect(request.uri.query, isEmpty);
      expect(request.body, isEmpty);
    });
  });
  group('cubit', () {
    late FakeDispatchRepo repo;
    late RiderAvailabilityCubit cubit;
    setUp(() {
      repo = FakeDispatchRepo();
      cubit = RiderAvailabilityCubit(repo);
    });
    tearDown(() => cubit.close());
    test(
      'default poll interval is 30 seconds; load and expand preserve data',
      () async {
        expect(cubit.pollInterval, const Duration(seconds: 30));
        await cubit.load();
        expect(cubit.state.data, repo.availability);
        expect(cubit.state.lastUpdated, isNotNull);
        expect(cubit.state.expanded, isFalse);
        cubit.toggleExpanded();
        expect(cubit.state.expanded, isTrue);
        expect(cubit.state.data, repo.availability);
      },
    );
    test(
      'available riders sort by distance null-last, then active, inactive and name',
      () async {
        AvailableRider rider(
          int id,
          String name, {
          bool available = false,
          String status = 'active',
          int? distance,
        }) => AvailableRider(
          id: id,
          name: name,
          status: status,
          isAvailableInRadius: available,
          nearestPickupDistanceM: distance,
        );
        repo.availability = RiderAvailability(
          riders: [
            rider(1, 'Offline', status: 'inactive'),
            rider(2, 'Z'),
            rider(3, 'A'),
            rider(4, 'Unknown distance', available: true),
            rider(5, 'B', available: true, distance: 84),
            rider(6, 'A', available: true, distance: 84),
            rider(7, 'Near', available: true, distance: 10),
          ],
        );
        await cubit.load();
        expect(cubit.state.sortedRiders.map((r) => r.id), [
          7,
          6,
          5,
          4,
          3,
          2,
          1,
        ]);
      },
    );
    test(
      '403 hides even old data, stops polling and prevents restart until reset',
      () async {
        await cubit.close();
        cubit = RiderAvailabilityCubit(
          repo,
          pollInterval: const Duration(milliseconds: 10),
        );
        await cubit.load();
        repo.availabilityError = ApiException('Not approved', statusCode: 403);
        cubit.startPolling();
        await Future<void>.delayed(const Duration(milliseconds: 25));
        expect(cubit.state.isForbidden, isTrue);
        expect(cubit.state.error, isNull);
        final count = repo.availabilityCalls;
        cubit.startPolling();
        await Future<void>.delayed(const Duration(milliseconds: 35));
        expect(repo.availabilityCalls, count);
        cubit.reset();
        expect(cubit.state, const RiderAvailabilityState());
      },
    );
    test(
      'first-load error is inline; silent refresh errors retain old data',
      () async {
        repo.availabilityError = ApiException('Availability error');
        await cubit.load();
        expect(cubit.state.error, 'Availability error');
        repo.availabilityError = null;
        await cubit.load();
        repo.availabilityError = ApiException('Offline');
        await cubit.refresh();
        expect(cubit.state.data, repo.availability);
        expect(cubit.state.error, isNull);
      },
    );
    test(
      'duplicate reads ignored and reset discards stale responses',
      () async {
        repo.availabilityGate = Completer<RiderAvailability>();
        final read = cubit.load();
        final duplicate = cubit.refresh();
        expect(repo.availabilityCalls, 1);
        cubit.reset();
        repo.availabilityGate!.complete(repo.availability);
        await Future.wait([read, duplicate]);
        expect(cubit.state, const RiderAvailabilityState());
      },
    );
    test('Orders and Dispatch share the timer: it stops only when both '
        'release it, and reset forgets owners', () async {
      await cubit.close();
      cubit = RiderAvailabilityCubit(
        repo,
        pollInterval: const Duration(milliseconds: 10),
      );
      final orders = Object(), dispatch = Object();
      Future<bool> ticking() async {
        final before = repo.availabilityCalls;
        await Future<void>.delayed(const Duration(milliseconds: 35));
        return repo.availabilityCalls > before;
      }

      cubit.setPollingOwner(orders, visible: true);
      cubit.setPollingOwner(dispatch, visible: true);
      expect(repo.availabilityCalls, 1, reason: 'one timer, one first read');
      // Orders hides after Dispatch opened on top of it.
      cubit.setPollingOwner(orders, visible: false);
      expect(await ticking(), isTrue);
      cubit.setPollingOwner(dispatch, visible: false);
      expect(await ticking(), isFalse);

      cubit.setPollingOwner(orders, visible: true);
      cubit.reset();
      expect(await ticking(), isFalse);
      // A stale owner from before reset can't keep a new timer alive.
      cubit.setPollingOwner(dispatch, visible: true);
      cubit.setPollingOwner(dispatch, visible: false);
      expect(await ticking(), isFalse);
    });
    for (final action in ['stop', 'close', 'reset']) {
      test('$action stops availability timer', () async {
        await cubit.close();
        cubit = RiderAvailabilityCubit(
          repo,
          pollInterval: const Duration(milliseconds: 10),
        );
        cubit.startPolling();
        cubit.startPolling();
        expect(repo.availabilityCalls, 1);
        await Future<void>.delayed(const Duration(milliseconds: 35));
        expect(repo.availabilityCalls, greaterThan(1));
        switch (action) {
          case 'stop':
            cubit.stopPolling();
          case 'close':
            await cubit.close();
          case 'reset':
            cubit.reset();
        }
        final count = repo.availabilityCalls;
        await Future<void>.delayed(const Duration(milliseconds: 25));
        expect(repo.availabilityCalls, count);
      });
    }
  });
}
