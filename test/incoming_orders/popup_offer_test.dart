import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/screen/order_page/incoming_orders/cubit/incoming_orders_cubit.dart';
import 'package:hyper_local_seller/screen/order_page/incoming_orders/model/pending_order_model.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';
import 'package:hyper_local_seller/service/notification_service.dart';

import 'helpers.dart';

/// The 409 the backend returns once an order's popup offer belongs to
/// another system user.
ApiException assignedElsewhere() => ApiException(
  'This order popup is assigned to another system user.',
  statusCode: 409,
  responseData: {
    'success': false,
    'message': 'This order popup is assigned to another system user.',
    'data': {'code': 'seller_order_offer_assigned_to_another_user'},
  },
);

class _OfferRepo extends FakePendingOrdersRepo {
  Object? acceptError;

  @override
  Future<PendingOrder> acceptOrder(
    PendingOrder order, {
    Set<int> skipItemIds = const {},
    void Function(int)? onItemAccepted,
  }) async {
    if (acceptError case final error?) {
      acceptError = null;
      throw error;
    }
    return super.acceptOrder(
      order,
      skipItemIds: skipItemIds,
      onItemAccepted: onItemAccepted,
    );
  }
}

void main() {
  late _OfferRepo repo;
  late FakeScanSessionStore store;
  late IncomingOrdersCubit cubit;

  setUpAll(() => initTestHive());

  setUp(() async {
    await HiveStorage.setAccessToken('test-token');
    repo = _OfferRepo();
    store = FakeScanSessionStore();
    cubit = IncomingOrdersCubit(repo, store: store);
  });

  tearDown(() => cubit.close());

  List<int> queueIds() =>
      cubit.state.orders.map((o) => o.sellerOrderId).toList();

  PendingOrder queued(int id) =>
      cubit.state.orders.firstWhere((o) => o.sellerOrderId == id);

  void verifyAll(PendingOrder order) {
    for (final item in order.items) {
      cubit.matchCode(order, item.barcode!);
      cubit.confirmQuantity(item, item.quantity);
    }
  }

  group('offer assigned to another user (409)', () {
    test('on accept: the order leaves, a notice explains, and it never '
        'returns even while the pending list still has it', () async {
      repo.server[OrderMode.regular] = [orderJson(1), orderJson(2)];
      await cubit.fetch();
      repo.acceptError = assignedElsewhere();

      expect(await cubit.accept(queued(1)), isFalse);

      expect(queueIds(), [2]);
      expect(cubit.state.isBusy, isFalse);
      expect(cubit.state.errorMessage, isNull);
      expect(
        cubit.state.notice,
        'This order popup is assigned to another system user.',
      );
      final noticeId = cubit.state.noticeId;
      expect(noticeId, greaterThan(0));

      for (var i = 0; i < 2; i++) {
        await cubit.fetch();
      }
      expect(queueIds(), [2]);
      expect(cubit.state.noticeId, noticeId, reason: 'no repeat notice');
    });

    test('on bag assignment: progress is dropped and no error is returned '
        'for the panel to show', () async {
      repo.server[OrderMode.regular] = [orderJson(1)];
      await cubit.fetch();
      await cubit.accept(queued(1));
      verifyAll(queued(1));
      repo.assignBagError = assignedElsewhere();

      expect(await cubit.assignBag(queued(1), 'BAG-1'), isNull);

      expect(cubit.state.orders, isEmpty);
      expect(cubit.state.acceptedOrderIds, isEmpty);
      expect(cubit.state.verifiedItemIds, isEmpty);
      expect(cubit.state.isBusy, isFalse);
      expect(cubit.state.notice, isNotNull);
      expect(store.sessions, isEmpty, reason: 'not restored after restart');
    });

    test('on dispatch: the order leaves without retrying', () async {
      repo.server[OrderMode.regular] = [orderJson(1)];
      await cubit.fetch();
      await cubit.accept(queued(1));
      verifyAll(queued(1));
      await cubit.assignBag(queued(1), 'BAG-1');
      repo.prepareError = assignedElsewhere();

      expect(await cubit.markPreparing(queued(1)), isFalse);

      expect(cubit.state.orders, isEmpty);
      expect(cubit.state.bags, isEmpty);
      expect(repo.calls.where((c) => c.startsWith('preparing')), isEmpty);
      await cubit.fetch();
      expect(cubit.state.orders, isEmpty);
    });

    test('a 409 with another code is an ordinary, retryable failure', () async {
      repo.server[OrderMode.regular] = [orderJson(1)];
      await cubit.fetch();
      repo.acceptError = ApiException(
        'Conflict',
        statusCode: 409,
        responseData: {
          'data': {'code': 'something_else'},
        },
      );

      expect(await cubit.accept(queued(1)), isFalse);

      expect(queueIds(), [1]);
      expect(cubit.state.failedOrderId, 1);
      expect(cubit.state.notice, isNull);
      expect(await cubit.accept(queued(1)), isTrue);
    });

    test('isAssignedElsewhere reads data.code, not the message', () {
      expect(IncomingOrdersCubit.isAssignedElsewhere(assignedElsewhere()), isTrue);
      expect(
        IncomingOrdersCubit.isAssignedElsewhere(
          ApiException(
            'This order popup is assigned to another system user.',
            statusCode: 409,
          ),
        ),
        isFalse,
      );
      expect(
        IncomingOrdersCubit.isAssignedElsewhere(Exception('offline')),
        isFalse,
      );
    });
  });

  test('seller_new_order pushes open the incoming-order popup', () {
    expect(
      NotificationService.isNewRegularOrderType('seller_new_order', '701'),
      isTrue,
    );
    expect(
      NotificationService.isNewRegularOrderType('SELLER_NEW_ORDER', null),
      isTrue,
    );
    expect(
      NotificationService.isNewRegularOrderType('order_update', '701'),
      isFalse,
    );
  });

  test('the new pending response shape (data.orders) is read', () {
    final order = PendingOrder.fromJson({
      'seller_order_id': 701,
      'order_id': 8801,
      'order_number': 'NM-20261026-AB3XK9ZM',
      'order_mode': 'regular',
      'created_at': '2026-10-26T04:50:00.000000Z',
      'customer': {'name': 'Customer Name'},
      'payment_method': 'cod',
      'total': 499.0,
      'bag': null,
      'items': [
        {
          'order_item_id': 9901,
          'product_id': 440,
          'product': 'Example Product',
          'variant': '500 g',
          'barcode': '8901234500021',
          'variant_weight': 0.5,
          'quantity': 2,
          'status': 'awaiting_store_response',
          'subtotal': 499.0,
        },
      ],
    });
    expect(order.sellerOrderId, 701);
    expect(order.bag, isNull);
    expect(order.needsAcceptance, isTrue);
    expect(order.items.single.matchesCode('8901234500021'), isTrue);
  });
}
