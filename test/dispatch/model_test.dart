import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_local_seller/screen/order_page/dispatch/model/dispatch_model.dart';
import 'helpers.dart';

void main() {
  test(
    'exact dashboard sample parses counts, every field and local timestamps',
    () {
      final dashboard = DispatchDashboard.fromJson(dashboardJson());
      expect(
        dashboard.summary,
        const DispatchSummary(
          readyOrders: 2,
          noNearbyRiders: 1,
          assignedOrders: 1,
        ),
      );
      expect(dashboard.summary.hasAlert, isTrue);
      expect(dashboard.orders.length, 2);
      final first = dashboard.orders.first;
      expect(first.orderId, 183);
      expect(first.orderNumber, 'NM-20261025-AB3XK9ZM');
      expect(first.status, DispatchStatus.noNearbyRiders);
      expect(first.rawStatus, 'no_nearby_riders');
      expect(first.deliveryBoyId, isNull);
      expect(first.deliveryBoyName, isNull);
      expect(first.pickup, 'Sharma Kirana');
      expect(first.pickupStoreId, 12);
      expect(first.pickupLatitude, 21.1458);
      expect(first.pickupLongitude, 79.0882);
      expect(first.nearbyAvailableRiders, 0);
      expect(first.bagBarcode, 'BAG-000183');
      expect(
        first.createdAt,
        DateTime.parse('2026-10-25T10:00:00+00:00').toLocal(),
      );
      expect(first.createdAt!.isUtc, isFalse);
      final second = dashboard.orders.last;
      expect(second.orderId, 184);
      expect(second.orderNumber, 'NM-20261025-CD4LM2PQ');
      expect(second.status, DispatchStatus.awaitingRiderAcceptance);
      expect(second.deliveryBoyId, 5);
      expect(second.deliveryBoyName, 'Rider Name');
      expect(second.nearbyAvailableRiders, 2);
      expect(second.bagBarcode, 'BAG-000184');
      expect(
        second
            .copyWith(deliveryBoyId: () => null, deliveryBoyName: () => null)
            .deliveryBoyId,
        isNull,
      );
      expect(
        second
            .copyWith(deliveryBoyId: () => null, deliveryBoyName: () => null)
            .deliveryBoyName,
        isNull,
      );
      expect(second.copyWith().deliveryBoyName, 'Rider Name');
      expect(first.toString(), isNot(contains('21.1458')));
    },
  );
  test('unknown status preserves raw value and humanises safely', () {
    final order = DispatchOrder.fromJson({'status': 'future_dispatch_state'});
    expect(order.status, DispatchStatus.unknown);
    expect(order.rawStatus, 'future_dispatch_state');
    expect(humaniseDispatchValue(order.rawStatus), 'Future dispatch state');
    expect(DispatchStatus.parse(null), DispatchStatus.unknown);
    expect(DispatchStatus.parse(123), DispatchStatus.unknown);
  });
  test('missing dashboard fields and invalid nullable fields are safe', () {
    for (final json in <Map<String, dynamic>>[
      {},
      {'data': {}},
      {
        'data': {'summary': null, 'orders': null},
      },
    ]) {
      final dashboard = DispatchDashboard.fromJson(json);
      expect(dashboard.summary, const DispatchSummary());
      expect(dashboard.orders, isEmpty);
    }
    final order = DispatchOrder.fromJson({
      'delivery_boy_name': ' ',
      'pickup_latitude': 'bad',
      'created_at': 'invalid',
    });
    expect(order.deliveryBoyName, isNull);
    expect(order.pickupLatitude, isNull);
    expect(order.pickupLongitude, isNull);
    expect(order.createdAt, isNull);
  });
  test('self-delivery is allowed only for the three pre-acceptance states', () {
    expect(DispatchStatus.values.where((s) => s.canSelfDeliver), [
      DispatchStatus.noNearbyRiders,
      DispatchStatus.waitingForDispatch,
      DispatchStatus.awaitingRiderAcceptance,
    ]);
    expect(DispatchStatus.values.where((s) => s.needsAction), [
      DispatchStatus.noNearbyRiders,
    ]);
  });
}
