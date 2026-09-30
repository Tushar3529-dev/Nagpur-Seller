import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/screen/order_page/incoming_orders/cubit/incoming_orders_cubit.dart';
import 'package:hyper_local_seller/screen/order_page/incoming_orders/model/pending_order_model.dart';

import 'helpers.dart';

void main() {
  late FakePendingOrdersRepo repo;
  late IncomingOrdersCubit cubit;
  bool confirmScannedQuantity(PendingOrderItem item, int quantity) {
    final order = cubit.state.orders.firstWhere(
      (order) =>
          order.items.any((line) => line.orderItemId == item.orderItemId),
    );
    final current = order.items.firstWhere(
      (line) => line.orderItemId == item.orderItemId,
    );
    cubit.matchCode(order, current.barcode ?? '');
    return cubit.confirmQuantity(item, quantity);
  }

  late FakeScanSessionStore store;

  setUpAll(() => initTestHive());

  setUp(() async {
    await HiveStorage.setAccessToken('test-token');
    repo = FakePendingOrdersRepo();
    store = FakeScanSessionStore();
    cubit = IncomingOrdersCubit(repo, store: store);
  });

  tearDown(() => cubit.close());

  List<int> queueIds() =>
      cubit.state.orders.map((o) => o.sellerOrderId).toList();

  PendingOrder queued(int id) =>
      cubit.state.orders.firstWhere((o) => o.sellerOrderId == id);

  String ago(int seconds) => DateTime.now()
      .toUtc()
      .subtract(Duration(seconds: seconds))
      .toIso8601String();

  group('fetch', () {
    test('polls both modes and merges them into one queue', () async {
      repo.server[OrderMode.regular] = [orderJson(1), orderJson(2)];
      repo.server[OrderMode.wholesale] = [orderJson(3, mode: 'wholesale')];

      await cubit.fetch();

      expect(repo.fetchCount, {OrderMode.regular: 1, OrderMode.wholesale: 1});
      expect(queueIds().toSet(), {1, 2, 3});
      expect(cubit.state.hasPending, isTrue);
    });

    test('same seller_order_id from both lists shows once', () async {
      repo.server[OrderMode.regular] = [orderJson(1)];
      repo.server[OrderMode.wholesale] = [orderJson(1), orderJson(1)];

      await cubit.fetch();
      expect(queueIds(), [1]);
    });

    test('repeated polls do not duplicate orders', () async {
      repo.server[OrderMode.regular] = [orderJson(1)];
      for (var i = 0; i < 5; i++) {
        await cubit.fetch();
      }
      expect(queueIds(), [1]);
    });

    test('regular orders: oldest created_at on top', () async {
      repo.server[OrderMode.regular] = [
        orderJson(1, createdAt: ago(300)),
        orderJson(2, createdAt: ago(10)),
        orderJson(3, createdAt: ago(120)),
      ];
      await cubit.fetch();
      expect(queueIds(), [1, 3, 2]);
    });

    test('five orders are shown in the order they came in', () async {
      repo.server[OrderMode.regular] = [
        for (var i = 5; i >= 1; i--) orderJson(i, createdAt: ago(600 - i * 60)),
      ];
      await cubit.fetch();

      final shown = <int>[];
      while (cubit.state.hasPending) {
        final top = cubit.state.orders.first;
        shown.add(top.sellerOrderId);
        expect(await cubit.accept(top), isTrue);
        for (final item in top.items) {
          confirmScannedQuantity(item, item.quantity);
        }
        expect(await cubit.markPreparing(top), isTrue);
      }
      expect(shown, [1, 2, 3, 4, 5]);
    });

    test('a newer order queues behind the card on screen', () async {
      repo.server[OrderMode.regular] = [orderJson(1, createdAt: ago(60))];
      await cubit.fetch();
      repo.server[OrderMode.regular] = [
        orderJson(1, createdAt: ago(65)),
        orderJson(2, createdAt: ago(1)),
      ];
      await cubit.fetch();
      expect(queueIds(), [1, 2]);
    });

    test('wholesale timer starts when the popup first shows it', () async {
      repo.server[OrderMode.wholesale] = [
        orderJson(5, mode: 'wholesale', createdAt: '2026-09-18T08:00:00Z'),
      ];
      await cubit.fetch();
      final since = cubit.state.waitingSince(queued(5))!;
      expect(DateTime.now().difference(since).inSeconds, lessThan(2));

      // Later polls keep the original start instead of resetting it.
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      await cubit.fetch();
      expect(cubit.state.waitingSince(queued(5)), since);
    });

    test('regular timer starts at created_at', () async {
      final created = ago(90);
      repo.server[OrderMode.regular] = [orderJson(1, createdAt: created)];
      await cubit.fetch();
      expect(cubit.state.waitingSince(queued(1)), DateTime.parse(created));
    });

    test('orders removed by the backend leave the queue', () async {
      repo.server[OrderMode.regular] = [orderJson(1), orderJson(2)];
      await cubit.fetch();
      repo.server[OrderMode.regular] = [orderJson(2)];
      await cubit.fetch();
      expect(queueIds(), [2]);
    });

    test(
      'a wholesale order appears when the backend starts returning it',
      () async {
        await cubit.fetch();
        expect(cubit.state.hasPending, isFalse);

        // Its slot now ends within 30 min, so popup=1 includes it.
        repo.server[OrderMode.wholesale] = [orderJson(8, mode: 'wholesale')];
        await cubit.fetch();
        expect(queueIds(), [8]);
      },
    );

    test(
      'one endpoint failing keeps its last list and updates the other',
      () async {
        repo.server[OrderMode.regular] = [orderJson(1)];
        repo.server[OrderMode.wholesale] = [orderJson(2, mode: 'wholesale')];
        await cubit.fetch();

        repo.failing.add(OrderMode.wholesale);
        repo.server[OrderMode.regular] = [orderJson(1), orderJson(3)];
        await cubit.fetch();

        expect(queueIds().toSet(), {1, 2, 3});
      },
    );

    test('both endpoints failing (offline) keeps the popup up', () async {
      repo.server[OrderMode.regular] = [orderJson(1)];
      await cubit.fetch();

      repo.failing.addAll(OrderMode.values);
      await cubit.fetch();
      expect(queueIds(), [1]);
    });

    test('logged out: no requests', () async {
      await HiveStorage.setAccessToken(null);
      await cubit.fetch();
      expect(repo.totalFetches, 0);
    });

    test('overlapping fetch calls are coalesced', () async {
      repo.server[OrderMode.regular] = [orderJson(1)];
      await Future.wait([cubit.fetch(), cubit.fetch(), cubit.fetch()]);
      await Future<void>.delayed(Duration.zero);
      // First run + at most one queued re-run, per mode.
      expect(repo.fetchCount[OrderMode.regular], lessThanOrEqualTo(2));
    });
  });

  group('accept', () {
    test('accept only for every item, in order', () async {
      repo.server[OrderMode.regular] = [
        orderJson(1, itemIds: [11, 12, 13]),
      ];
      await cubit.fetch();

      expect(await cubit.accept(queued(1)), isTrue);
      expect(repo.calls, ['accept 11', 'accept 12', 'accept 13']);
    });

    test(
      'accepted order stays until preparing then never comes back',
      () async {
        repo.server[OrderMode.regular] = [orderJson(1), orderJson(2)];
        await cubit.fetch();

        await cubit.accept(queued(1));
        expect(queueIds(), [1, 2]);
        final order = queued(1);
        for (final item in order.items) {
          confirmScannedQuantity(item, item.quantity);
        }
        await cubit.markPreparing(order);
        expect(queueIds(), [2]);

        // Backend still lists it for a while (or in the wholesale list).
        repo.server[OrderMode.wholesale] = [orderJson(1, mode: 'wholesale')];
        for (var i = 0; i < 3; i++) {
          await cubit.fetch();
        }
        expect(queueIds(), [2]);
      },
    );

    test('accepting the same order twice sends no extra calls', () async {
      repo.server[OrderMode.regular] = [orderJson(1)];
      await cubit.fetch();
      final order = queued(1);

      await cubit.accept(order);
      final callsAfterFirst = List.of(repo.calls);
      expect(await cubit.accept(order), isTrue);
      expect(repo.calls, callsAfterFirst);
    });

    test('double tap while accepting is ignored', () async {
      repo.server[OrderMode.regular] = [orderJson(1)];
      await cubit.fetch();
      repo.acceptGate = Completer();

      final first = cubit.accept(queued(1));
      expect(await cubit.accept(queued(1)), isFalse);
      repo.acceptGate!.complete();
      expect(await first, isTrue);
      expect(repo.calls, ['accept 1']);
    });

    test('shows loading state while accepting', () async {
      repo.server[OrderMode.regular] = [orderJson(1)];
      await cubit.fetch();
      repo.acceptGate = Completer();

      final pending = cubit.accept(queued(1));
      expect(cubit.state.acceptingOrderId, 1);
      repo.acceptGate!.complete();
      await pending;
      expect(cubit.state.acceptingOrderId, isNull);
    });

    test('failure shows an error; retry skips calls that succeeded', () async {
      repo.server[OrderMode.regular] = [
        orderJson(1, itemIds: [11, 12]),
      ];
      await cubit.fetch();
      repo.failAcceptOnce.add(12);

      expect(await cubit.accept(queued(1)), isFalse);
      expect(cubit.state.failedOrderId, 1);
      expect(cubit.state.errorMessage, contains('accept failed'));
      expect(queueIds(), [1], reason: 'order stays until it goes through');
      expect(repo.calls, ['accept 11']);

      expect(await cubit.accept(queued(1)), isTrue);
      expect(cubit.state.errorMessage, isNull);
      expect(repo.calls, ['accept 11', 'accept 12']);
      expect(queueIds(), [1]);
    });

    test(
      'wholesale retry retains items omitted after partial acceptance',
      () async {
        repo.server[OrderMode.wholesale] = [
          orderJson(9, mode: 'wholesale', itemIds: [91, 92]),
        ];
        await cubit.fetch();
        repo.failAcceptOnce.add(92);
        expect(await cubit.accept(queued(9)), isFalse);
        await Future<void>.delayed(Duration.zero);

        // Accepted items may leave the pending response before preparing succeeds.
        repo.server[OrderMode.wholesale] = [
          orderJson(9, mode: 'wholesale', itemIds: [92]),
        ];
        await cubit.fetch();
        expect(queued(9).items.map((item) => item.orderItemId), [91, 92]);

        repo.server[OrderMode.wholesale] = [];
        await cubit.fetch();
        expect(queueIds(), [9]);
        expect(cubit.state.failedOrderId, 9);
        expect(await cubit.accept(queued(9)), isTrue);
        expect(repo.calls, ['accept 91', 'accept 92']);
        expect(queueIds(), [9]);
      },
    );

    test(
      'unaccepted wholesale order still leaves when backend removes it',
      () async {
        repo.server[OrderMode.wholesale] = [orderJson(9, mode: 'wholesale')];
        await cubit.fetch();
        repo.failAcceptOnce.add(1);
        expect(await cubit.accept(queued(9)), isFalse);
        await Future<void>.delayed(Duration.zero);
        repo.server[OrderMode.wholesale] = [];
        await cubit.fetch();
        expect(queueIds(), isEmpty);
      },
    );

    test('polling pauses during accept and resumes after', () async {
      repo.server[OrderMode.regular] = [orderJson(1)];
      await cubit.fetch();
      final before = repo.totalFetches;
      repo.acceptGate = Completer();

      final pending = cubit.accept(queued(1));
      await cubit.fetch();
      await cubit.fetch();
      expect(repo.totalFetches, before, reason: 'no fetch while accepting');

      repo.acceptGate!.complete();
      await pending;
      await Future<void>.delayed(Duration.zero);
      expect(repo.totalFetches, greaterThan(before));
    });

    test('polling resumes after a failed accept too', () async {
      repo.server[OrderMode.regular] = [orderJson(1)];
      await cubit.fetch();
      final before = repo.totalFetches;
      repo.failAcceptOnce.add(1);

      await cubit.accept(queued(1));
      await Future<void>.delayed(Duration.zero);
      expect(repo.totalFetches, greaterThan(before));
    });

    test(
      'new order arriving during accept keeps the current card on top',
      () async {
        repo.server[OrderMode.regular] = [
          orderJson(1, createdAt: ago(120)),
          orderJson(2, createdAt: ago(60)),
        ];
        await cubit.fetch();
        expect(queueIds().first, 1);

        // Accept the one at the back of the queue (e.g. list reordered).
        repo.acceptGate = Completer();
        final pending = cubit.accept(queued(2));
        repo.acceptGate!.complete();
        await pending;
        expect(queueIds(), [1, 2]);
      },
    );

    test('works through a queue of six orders one at a time', () async {
      repo.server[OrderMode.regular] = [
        for (var i = 1; i <= 4; i++) orderJson(i, createdAt: ago(i * 10)),
      ];
      repo.server[OrderMode.wholesale] = [
        orderJson(5, mode: 'wholesale'),
        orderJson(6, mode: 'wholesale'),
      ];
      await cubit.fetch();
      expect(cubit.state.orders.length, 6);

      while (cubit.state.hasPending) {
        final top = cubit.state.orders.first;
        expect(await cubit.accept(top), isTrue);
        for (final item in top.items) {
          confirmScannedQuantity(item, item.quantity);
        }
        expect(await cubit.markPreparing(top), isTrue);
      }
      expect(repo.calls.where((c) => c.startsWith('accept')).length, 6);
    });
  });

  test('logout clears the queue and accepted history', () async {
    repo.server[OrderMode.regular] = [orderJson(1), orderJson(2)];
    await cubit.fetch();
    await cubit.accept(queued(1));

    cubit.clear();
    expect(cubit.state.hasPending, isFalse);
    expect(cubit.state.acceptedOrderIds, isEmpty);
    expect(cubit.state.verifiedItemIds, isEmpty);
    expect(store.clearCount, 1);
    expect(store.sessions, isEmpty);

    // A different seller logs in; order 1 is no longer suppressed.
    await cubit.fetch();
    await Future<void>.delayed(Duration.zero);
    await cubit.fetch();
    expect(queueIds().toSet(), {1, 2});
  });
}
