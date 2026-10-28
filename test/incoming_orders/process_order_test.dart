import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/screen/order_page/incoming_orders/cubit/incoming_orders_cubit.dart';
import 'package:hyper_local_seller/screen/order_page/incoming_orders/model/pending_order_model.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';

import 'helpers.dart';

ApiException takeoverConflict(String code, {String message = ''}) =>
    ApiException(
      message,
      statusCode: 409,
      responseData: {
        'success': false,
        'message': message,
        'data': {'code': code},
      },
    );

void main() {
  late FakePendingOrdersRepo repo;
  late IncomingOrdersCubit cubit;

  setUpAll(() => initTestHive());

  setUp(() async {
    await HiveStorage.setAccessToken('test-token');
    repo = FakePendingOrdersRepo();
    cubit = IncomingOrdersCubit(repo, store: FakeScanSessionStore());
  });

  tearDown(() => cubit.close());

  List<int> queueIds() =>
      cubit.state.orders.map((o) => o.sellerOrderId).toList();

  PendingOrder queued(int id) =>
      cubit.state.orders.firstWhere((o) => o.sellerOrderId == id);

  group('processOrder as the main seller', () {
    test('takes the offer over, then opens it in the accept step', () async {
      repo.takeoverOffers[7] = orderJson(7);

      expect(await cubit.processOrder(7, asOwner: true), isNull);

      expect(repo.takeoverCalls, [7]);
      expect(queueIds(), [7]);
      expect(cubit.state.isAccepted(queued(7)), isFalse);
      expect(repo.calls, isEmpty, reason: 'takeover never accepts');
    });

    test('an owner already holding an order is told to finish it', () async {
      repo.takeoverError = takeoverConflict(
        IncomingOrdersCubit.ownerHasActiveOrderCode,
      );
      repo.server[OrderMode.regular] = [orderJson(7)];
      final fetches = repo.totalFetches;

      final error = await cubit.processOrder(7, asOwner: true);

      expect(error, contains('Finish the order currently assigned to you'));
      expect(queueIds(), isNot(contains(7)), reason: 'not opened directly');
      await pumpEventQueue();
      expect(repo.totalFetches, greaterThan(fetches), reason: 'refreshes');
    });

    test('an order accepted by another user does not open', () async {
      repo.takeoverError = takeoverConflict(
        IncomingOrdersCubit.offerAlreadyAcceptedCode,
        message: 'This order has already been accepted by another user.',
      );

      final error = await cubit.processOrder(7, asOwner: true);

      expect(error, 'This order has already been accepted by another user.');
      expect(cubit.state.hasPending, isFalse);
    });

    test('an offer that is already the owner\'s own still opens', () async {
      repo.takeoverError = takeoverConflict(
        IncomingOrdersCubit.offerNotPendingCode,
      );
      repo.server[OrderMode.regular] = [
        orderJson(7)..['items'][0]['status'] = 'accepted',
      ];

      expect(await cubit.processOrder(7, asOwner: true), isNull);
      expect(queueIds(), [7]);
      expect(cubit.state.isAccepted(queued(7)), isTrue);
    });

    test('a non-owner 403 is reported without a lookup', () async {
      repo.takeoverError = ApiException('', statusCode: 403);

      final error = await cubit.processOrder(7, asOwner: true);

      expect(error, 'Only the main seller can take over orders.');
    });
  });

  group('processOrder as a system user', () {
    test('never takes over, and opens its own offer', () async {
      repo.server[OrderMode.wholesale] = [orderJson(8, mode: 'wholesale')];

      expect(
        await cubit.processOrder(8, mode: OrderMode.wholesale, asOwner: false),
        isNull,
      );
      expect(repo.takeoverCalls, isEmpty);
      expect(queueIds(), [8]);
    });

    test('an order offered to someone else is refused', () async {
      final error = await cubit.processOrder(9, asOwner: false);

      expect(repo.takeoverCalls, isEmpty);
      expect(error, contains('not assigned to you'));
      expect(cubit.state.hasPending, isFalse);
    });
  });

  test('an order already in the popup is brought to the top', () async {
    repo.server[OrderMode.regular] = [
      orderJson(1, createdAt: '2026-10-27T05:00:00Z'),
      orderJson(2, createdAt: '2026-10-27T05:01:00Z'),
    ];
    await cubit.fetch();
    expect(queueIds(), [1, 2]);

    expect(await cubit.processOrder(2, asOwner: true), isNull);

    expect(repo.takeoverCalls, isEmpty);
    expect(cubit.state.visibleOrders.first.sellerOrderId, 2);
  });

  group('minimize', () {
    setUp(() async {
      repo.server[OrderMode.regular] = [orderJson(1)];
      await cubit.fetch();
    });

    test('hides the order and stops it ringing, without losing it', () async {
      expect(cubit.state.hasUnaccepted, isTrue);

      cubit.minimize(1);

      expect(cubit.state.hasVisible, isFalse);
      expect(cubit.state.hasUnaccepted, isFalse);
      expect(cubit.state.minimizedOrders.single.sellerOrderId, 1);
      await cubit.fetch();
      expect(cubit.state.isMinimized(queued(1)), isTrue, reason: 'kept');
    });

    test('reopen brings it back on top', () async {
      cubit.minimize(1);
      cubit.reopen(1);

      expect(cubit.state.hasVisible, isTrue);
      expect(cubit.state.hasUnaccepted, isTrue);
      expect(cubit.state.minimizedOrders, isEmpty);
    });

    test('is forgotten once the server drops the order', () async {
      cubit.minimize(1);
      repo.server[OrderMode.regular] = [];
      await cubit.fetch();

      expect(cubit.state.minimizedOrderIds, isEmpty);
    });
  });

  test('dropReassigned closes the order and explains why', () async {
    repo.server[OrderMode.regular] = [orderJson(3)];
    await cubit.fetch();
    // The server no longer lists it for this user either.
    repo.server[OrderMode.regular] = [];

    cubit.dropReassigned(3);

    expect(cubit.state.hasPending, isFalse);
    expect(cubit.state.notice, contains('taken over by the store owner'));
  });
}
