import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_local_seller/screen/order_page/incoming_orders/cubit/incoming_orders_cubit.dart';
import 'package:hyper_local_seller/screen/order_page/incoming_orders/model/pending_order_model.dart';
import 'package:hyper_local_seller/screen/order_page/incoming_orders/repo/scan_session_store.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';

import 'helpers.dart';

class _ValidationRepo extends FakePendingOrdersRepo {
  Map<int, String>? submittedCodes;

  @override
  Future<void> markOrderPreparing(
    PendingOrder order, {
    Map<int, String> verifiedBarcodes = const {},
    Set<int> skipItemIds = const {},
    void Function(int)? onItemDone,
  }) async {
    submittedCodes = Map.of(verifiedBarcodes);
    throw ApiException(
      'Verification failed.',
      statusCode: 422,
      responseData: {
        'data': {
          'errors': [
            {
              'order_item_id': 11,
              'field': 'quantity',
              'message': 'Count again.',
            },
          ],
        },
      },
    );
  }
}

Map<String, dynamic> _accepted({
  String? barcode = '8901234500021',
  int quantity = 2,
}) {
  final json = orderJson(
    1,
    itemIds: [11, 12],
    quantities: {11: quantity, 12: 1},
    barcodes: {11: barcode ?? '', 12: '8901234500022'},
  );
  for (final item in json['items'] as List) {
    item['status'] = 'accepted';
  }
  return json;
}

void main() {
  late _ValidationRepo repo;
  late FakeScanSessionStore store;
  late IncomingOrdersCubit cubit;
  setUpAll(initTestHive);
  setUp(() {
    repo = _ValidationRepo();
    store = FakeScanSessionStore();
    cubit = IncomingOrdersCubit(repo, store: store);
    repo.server[OrderMode.regular] = [_accepted()];
  });
  tearDown(() => cubit.close());

  test(
    'server-accepted orders resume without accept requests or ringing',
    () async {
      await cubit.fetch();
      expect(cubit.state.acceptedOrderIds, {1});
      expect(cubit.state.hasUnaccepted, isFalse);
      expect(repo.calls, isEmpty);
      expect(store.sessions.single.order.items.first.barcode, '8901234500021');
    },
  );

  test('quantity requires a matching actual scanned code', () async {
    await cubit.fetch();
    final order = cubit.state.orders.single;
    final item = order.items.first;
    expect(cubit.confirmQuantity(item, 2), isFalse);
    expect(cubit.matchCode(order, 'A1').$1, ScanMatch.notInOrder);
    expect(cubit.matchCode(order, ' 8901234500021 ').$1, ScanMatch.matched);
    expect(cubit.confirmQuantity(item, 1), isFalse);
    expect(cubit.confirmQuantity(item, 2), isTrue);
    expect(cubit.state.verifiedBarcodes, {11: '8901234500021'});
    expect(store.sessions.single.verifiedBarcodes, {11: '8901234500021'});
  });

  test('missing barcode stays missing and cannot be verified', () async {
    repo.server[OrderMode.regular] = [_accepted(barcode: null)];
    await cubit.fetch();
    final order = cubit.state.orders.single;
    expect(order.items.first.barcode, isNull);
    expect(cubit.matchCode(order, 'A1').$1, ScanMatch.notInOrder);
    expect(cubit.confirmQuantity(order.items.first, 2), isFalse);
    expect(await cubit.markPreparing(order), isFalse);
    expect(repo.submittedCodes, isNull);
  });

  test(
    'refresh preserves an in-flight scan but invalidates changed quantity',
    () async {
      await cubit.fetch();
      final order = cubit.state.orders.single;
      cubit.matchCode(order, '8901234500021');
      await cubit.fetch();
      expect(cubit.confirmQuantity(order.items.first, 2), isTrue);
      repo.server[OrderMode.regular] = [_accepted(quantity: 3)];
      await cubit.fetch();
      expect(cubit.state.verifiedItemIds, isEmpty);
      expect(cubit.state.verifiedBarcodes, isEmpty);
      expect(cubit.confirmQuantity(order.items.first, 3), isFalse);
    },
  );

  test(
    'backend field errors clear only affected verification and save codes',
    () async {
      await cubit.fetch();
      final order = cubit.state.orders.single;
      for (final item in order.items) {
        cubit.matchCode(order, item.barcode!);
        expect(cubit.confirmQuantity(item, item.quantity), isTrue);
      }
      expect(await cubit.assignBag(order, 'BAG-1'), isNull);
      expect(await cubit.markPreparing(order), isFalse);
      expect(repo.submittedCodes, {11: '8901234500021', 12: '8901234500022'});
      expect(cubit.state.itemErrors, {
        11: {'quantity': 'Count again.'},
      });
      expect(cubit.state.verifiedItemIds, {12});
      expect(store.sessions.single.verifiedBarcodes, {12: '8901234500022'});
      expect(cubit.state.isFullyVerified(order), isFalse);
    },
  );

  test(
    'successful pending refresh drops stale saved orders and their codes',
    () async {
      await cubit.fetch();
      final order = cubit.state.orders.single;
      cubit.matchCode(order, order.items.first.barcode!);
      cubit.confirmQuantity(order.items.first, 2);
      repo.server[OrderMode.regular] = [];
      await cubit.fetch();
      expect(cubit.state.orders, isEmpty);
      expect(cubit.state.acceptedOrderIds, isEmpty);
      expect(cubit.state.verifiedBarcodes, isEmpty);
      expect(store.sessions, isEmpty);
    },
  );

  test('failed pending refresh retains saved progress', () async {
    await cubit.fetch();
    final order = cubit.state.orders.single;
    cubit.matchCode(order, order.items.first.barcode!);
    cubit.confirmQuantity(order.items.first, 2);
    repo.server[OrderMode.regular] = [];
    repo.failing.add(OrderMode.regular);
    await cubit.fetch();
    expect(cubit.state.orders, hasLength(1));
    expect(cubit.state.verifiedBarcodes, {11: '8901234500021'});
  });

  test(
    'legacy saved dummy values are replaced by pending data, ticks discarded',
    () async {
      final old = PendingOrder.fromJson(orderJson(1, itemIds: [11, 12]));
      store.sessions = [
        ScanSession(old, {11}, verifiedBarcodes: {11: 'A1'}),
      ];
      repo.statuses[1] = {11: 'accepted', 12: 'accepted'};
      await cubit.fetch();
      expect(cubit.state.orders.single.items.first.barcode, '8901234500021');
      expect(cubit.state.verifiedItemIds, isEmpty);
      expect(cubit.state.verifiedBarcodes, isEmpty);
      expect(store.sessions.single.order.items.first.barcode, '8901234500021');
    },
  );
}
