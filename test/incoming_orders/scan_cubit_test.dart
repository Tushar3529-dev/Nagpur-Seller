import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_local_seller/screen/order_page/incoming_orders/cubit/incoming_orders_cubit.dart';
import 'package:hyper_local_seller/screen/order_page/incoming_orders/model/pending_order_model.dart';
import 'package:hyper_local_seller/screen/order_page/incoming_orders/repo/scan_session_store.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';
import 'helpers.dart';

void main() {
  late FakePendingOrdersRepo repo;
  late FakeScanSessionStore store;
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

  setUpAll(initTestHive);
  setUp(() {
    repo = FakePendingOrdersRepo();
    store = FakeScanSessionStore();
    cubit = IncomingOrdersCubit(repo, store: store);
  });
  tearDown(() => cubit.close());
  Future<PendingOrder> accept({Map<int, String> codes = const {}}) async {
    repo.server[OrderMode.regular] = [
      orderJson(1, itemIds: [11, 12], barcodes: codes),
    ];
    await cubit.fetch();
    final original = cubit.state.orders.single;
    await cubit.accept(original);
    return original;
  }

  void verify(PendingOrder order) {
    for (final item in order.items) {
      expect(confirmScannedQuantity(item, item.quantity), isTrue);
    }
  }

  test(
    'matching uses held barcodes; wrong, case, spaces and verified codes',
    () async {
      final original = await accept();
      expect(cubit.matchCode(original, 'ZZ9').$1, ScanMatch.notInOrder);
      final (match, item) = cubit.matchCode(original, ' A1 ');
      expect(match, ScanMatch.matched);
      expect(item!.orderItemId, 11);
      expect(confirmScannedQuantity(item, 2), isFalse);
      expect(confirmScannedQuantity(item, 4), isFalse);
      expect(cubit.state.verifiedItemIds, isEmpty);
      expect(confirmScannedQuantity(item, 3), isTrue);
      expect(cubit.matchCode(original, 'A1').$1, ScanMatch.alreadyVerified);
      expect(cubit.matchCode(original, 'A2').$1, ScanMatch.matched);
    },
  );
  test('duplicate barcodes verify each line separately', () async {
    final order = await accept(codes: {11: 'SAME', 12: 'SAME'});
    final first = cubit.matchCode(order, 'SAME').$2!;
    expect(first.orderItemId, 11);
    confirmScannedQuantity(first, 3);
    final second = cubit.matchCode(order, 'SAME').$2!;
    expect(second.orderItemId, 12);
    confirmScannedQuantity(second, 3);
    expect(cubit.matchCode(order, 'SAME').$1, ScanMatch.alreadyVerified);
  });
  test(
    'preparing requires every tick; busy prevents double call and defers fetch',
    () async {
      final order = await accept();
      expect(await cubit.markPreparing(order), isFalse);
      confirmScannedQuantity(order.items.first, 3);
      expect(await cubit.markPreparing(order), isFalse);
      verify(order);
      // Every item verified, but no bag yet.
      expect(await cubit.markPreparing(order), isFalse);
      expect(await cubit.assignBag(order, 'BAG-1'), isNull);
      await Future<void>.delayed(Duration.zero);
      repo.preparingGate = Completer<void>();
      final before = repo.totalFetches;
      final pending = cubit.markPreparing(order);
      expect(cubit.state.preparingOrderId, 1);
      expect(await cubit.markPreparing(order), isFalse);
      await cubit.fetch();
      expect(repo.totalFetches, before);
      repo.preparingGate!.complete();
      expect(await pending, isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(repo.totalFetches, greaterThan(before));
      expect(repo.calls, [
        'accept 11',
        'accept 12',
        'preparing 11',
        'preparing 12',
      ]);
      expect(cubit.state.hasPending, isFalse);
    },
  );
  test(
    'preparing partial failure preserves ticks and retries only missing item',
    () async {
      final order = await accept();
      verify(order);
      await cubit.assignBag(order, 'BAG-1');
      repo.failPreparingOnce.add(12);
      expect(await cubit.markPreparing(order), isFalse);
      expect(cubit.state.isFullyVerified(order), isTrue);
      expect(cubit.state.errorMessage, contains('preparing failed'));
      expect(await cubit.markPreparing(order), isTrue);
      expect(repo.calls, [
        'accept 11',
        'accept 12',
        'preparing 11',
        'preparing 12',
      ]);
      expect(cubit.state.acceptedOrderIds, isEmpty);
      expect(cubit.state.verifiedItemIds, isEmpty);
    },
  );
  test(
    'new older unaccepted order rings but stays behind the scanning order',
    () async {
      repo.server[OrderMode.regular] = [
        orderJson(1, itemIds: [11]),
      ];
      await cubit.fetch();
      expect(cubit.state.hasUnaccepted, isTrue);
      await cubit.accept(cubit.state.orders.first);
      expect(cubit.state.hasPending, isTrue);
      expect(cubit.state.hasUnaccepted, isFalse);
      repo.server[OrderMode.regular] = [
        cubit.state.orders.first.toJson(),
        orderJson(2, itemIds: [22], createdAt: '2000-01-01T00:00:00Z'),
      ];
      await Future<void>.delayed(Duration.zero);
      await cubit.fetch();
      expect(cubit.state.orders.map((o) => o.sellerOrderId), [1, 2]);
      expect(cubit.state.hasUnaccepted, isTrue);
    },
  );
  test(
    'saves after accept, each verification and preparing; logout clears',
    () async {
      final order = await accept();
      final initialSaves = store.saves.length;
      expect(initialSaves, greaterThanOrEqualTo(1));
      expect(store.sessions.single.order.items.first.barcode, 'A1');
      confirmScannedQuantity(order.items.first, 3);
      expect(store.saves.length, initialSaves + 1);
      expect(store.sessions.single.verifiedItemIds, {11});
      confirmScannedQuantity(order.items.last, 3);
      expect(store.saves.length, initialSaves + 2);
      await cubit.assignBag(order, 'BAG-1');
      expect(store.saves.length, initialSaves + 3);
      expect(store.sessions.single.order.bag?.barcode, 'BAG-1');
      await cubit.markPreparing(order);
      expect(store.saves.length, initialSaves + 4);
      expect(store.sessions, isEmpty);
      cubit.clear();
      expect(store.clearCount, 1);
      expect(cubit.state, const IncomingOrdersState());
    },
  );
  for (final status in ['accepted', 'preparing', 'cancelled', 'offline']) {
    test('restore $status sessions', () async {
      final order = PendingOrder.fromJson(
        orderJson(1, itemIds: [11, 12], barcodes: {11: 'A1', 12: 'A2'}),
      );
      store.sessions = [
        ScanSession(order, {11}, verifiedBarcodes: {11: 'A1'}),
      ];
      repo.statuses[1] = {11: status, 12: status};
      if (status == 'accepted') {
        repo.server[OrderMode.regular] = [
          order
              .copyWith(
                items: [
                  for (final item in order.items)
                    item.copyWith(status: 'accepted'),
                ],
              )
              .toJson(),
        ];
      }
      if (status == 'offline') {
        repo.failStatusFor.add(1);
        repo.failing.add(OrderMode.regular);
      }
      await cubit.fetch();
      final keep = status == 'accepted' || status == 'offline';
      expect(cubit.state.hasPending, keep);
      expect(store.sessions.isNotEmpty, keep);
      if (keep) {
        expect(cubit.state.acceptedOrderIds, {1});
        expect(cubit.state.verifiedItemIds, {11});
        expect(cubit.state.hasUnaccepted, isFalse);
      }
    });
  }
  test(
    'restore remembers already preparing items and accepted orders go first',
    () async {
      final order = PendingOrder.fromJson(
        orderJson(1, itemIds: [11, 12], barcodes: {11: 'A1', 12: 'A2'}),
      );
      store.sessions = [
        ScanSession(order, {11, 12}, verifiedBarcodes: {11: 'A1', 12: 'A2'}),
      ];
      repo.statuses[1] = {11: 'preparing', 12: 'accepted'};
      repo.server[OrderMode.regular] = [
        order
            .copyWith(items: [order.items.last.copyWith(status: 'accepted')])
            .toJson(),
        orderJson(2, itemIds: [22], createdAt: '2000-01-01T00:00:00Z'),
      ];
      await cubit.fetch();
      expect(cubit.state.orders.map((o) => o.sellerOrderId), [1, 2]);
      await cubit.assignBag(order, 'BAG-1');
      await cubit.markPreparing(order);
      expect(repo.calls, ['preparing 12']);
    },
  );
  for (final action in ['accept', 'preparing']) {
    test(
      'logout during $action cannot restore the old seller session',
      () async {
        repo.server[OrderMode.regular] = [
          orderJson(1, itemIds: [11, 12]),
        ];
        await cubit.fetch();
        final order = cubit.state.orders.first;
        if (action == 'preparing') {
          await cubit.accept(order);
          verify(order);
          repo.preparingGate = Completer<void>();
        } else {
          repo.acceptGate = Completer<void>();
        }
        final pending = action == 'accept'
            ? cubit.accept(order)
            : cubit.markPreparing(order);
        cubit.clear();
        (action == 'accept' ? repo.acceptGate : repo.preparingGate)!.complete();
        expect(await pending, isFalse);
        await Future<void>.delayed(Duration.zero);
        expect(cubit.state, const IncomingOrdersState());
        expect(store.sessions, isEmpty);
      },
    );
  }

  group('bag', () {
    test('only a fully verified order can get a bag, once', () async {
      final order = await accept();
      expect(await cubit.assignBag(order, 'BAG-1'), isNotNull);
      expect(repo.bagCalls, isEmpty);
      verify(order);
      expect(cubit.state.isReadyToDispatch(order), isFalse);
      expect(await cubit.assignBag(order, 'BAG-1'), isNull);
      expect(cubit.state.bagFor(order)?.barcode, 'BAG-1');
      expect(cubit.state.isReadyToDispatch(order), isTrue);
      // The bag is final: a second scan doesn't replace it.
      expect(await cubit.assignBag(order, 'BAG-2'), isNull);
      expect(repo.bagCalls, ['1 BAG-1']);
      expect(cubit.state.bagFor(order)?.barcode, 'BAG-1');
    });

    test('a rejected bag returns the message and keeps the order', () async {
      final order = await accept();
      verify(order);
      repo.assignBagError = ApiException('Not in your bag pool.');
      expect(await cubit.assignBag(order, 'BAG-X'), 'Not in your bag pool.');
      expect(cubit.state.assigningBagOrderId, isNull);
      expect(cubit.state.bagFor(order), isNull);
      expect(cubit.state.isFullyVerified(order), isTrue);
    });

    test('busy while assigning: no double call and fetch waits', () async {
      final order = await accept();
      verify(order);
      await Future<void>.delayed(Duration.zero);
      repo.bagGate = Completer<void>();
      final pending = cubit.assignBag(order, 'BAG-1');
      expect(cubit.state.assigningBagOrderId, 1);
      expect(await cubit.assignBag(order, 'BAG-1'), isNotNull);
      final before = repo.totalFetches;
      await cubit.fetch();
      expect(repo.totalFetches, before);
      repo.bagGate!.complete();
      expect(await pending, isNull);
      expect(repo.bagCalls, ['1 BAG-1']);
    });

    test('bag_required from dispatch asks for a bag again', () async {
      final order = await accept();
      verify(order);
      await cubit.assignBag(order, 'BAG-1');
      repo.prepareError = ApiException(
        'Assign a bag before dispatch.',
        statusCode: 422,
        responseData: {'success': false, 'bag_required': true},
      );
      expect(await cubit.markPreparing(order), isFalse);
      expect(cubit.state.bagFor(order), isNull);
      expect(cubit.state.isFullyVerified(order), isTrue);
      expect(cubit.state.isReadyToDispatch(order), isFalse);
    });

    test(
      'an order resumed with a bag from the server skips the bag step',
      () async {
        final json = orderJson(1, itemIds: [11]);
        (json['items'] as List).first['status'] = 'accepted';
        json['bag'] = {'id': 33, 'barcode': 'BAG-000033'};
        repo.server[OrderMode.regular] = [json];
        await cubit.fetch();
        final order = cubit.state.orders.single;
        expect(cubit.state.bagFor(order)?.barcode, 'BAG-000033');
        verify(order);
        expect(cubit.state.isReadyToDispatch(order), isTrue);
        expect(await cubit.markPreparing(order), isTrue);
        expect(repo.bagCalls, isEmpty);
      },
    );
  });
}
