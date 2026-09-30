import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_local_seller/screen/order_page/incoming_orders/model/pending_order_model.dart';

import 'helpers.dart';

void main() {
  test('barcode parsing, equality and item/order JSON round trips', () {
    final order = PendingOrder.fromJson(
      orderJson(1, itemIds: [11, 12], barcodes: {11: ' A1 ', 12: 'a2'}),
    );
    expect(order.items.first.barcode, 'A1');
    expect(PendingOrder.fromJson(order.toJson()).toJson(), order.toJson());
    expect(PendingOrder.fromJson(order.toJson()), order);
    for (final item in order.items) {
      expect(PendingOrderItem.fromJson(item.toJson()), item);
      expect(item.copyWith(barcode: 'different'), isNot(item));
    }
  });
  test(
    'matchesCode trims, respects case and rejects missing and empty codes',
    () {
      final item = PendingOrder.fromJson(orderJson(1)).items.single;
      expect(item.matchesCode(''), isFalse);
      expect(item.copyWith(barcode: '').matchesCode(''), isFalse);
      expect(item.copyWith(barcode: ' A1 ').matchesCode(' A1 '), isTrue);
      expect(item.copyWith(barcode: 'A1').matchesCode('A2'), isFalse);
      expect(item.copyWith(barcode: 'A1').matchesCode('a1'), isFalse);
    },
  );

  group('PendingOrder.fromJson', () {
    test('parses every documented field', () {
      final order = PendingOrder.fromJson(
        orderJson(
          123,
          mode: 'wholesale',
          createdAt: '2026-09-22T15:47:00.000000Z',
          itemIds: [789, 790],
        ),
      );

      expect(order.sellerOrderId, 123);
      expect(order.orderId, 1230);
      expect(order.orderNumber, 'NM-20260922-123');
      expect(order.mode, OrderMode.wholesale);
      expect(order.isWholesale, isTrue);
      expect(order.createdAt, DateTime.utc(2026, 9, 22, 15, 47));
      expect(order.customerName, 'TUSHAR');
      expect(order.customerPhone, '8595857925');
      expect(order.customerAddress, contains('Bharatnagar'));
      expect(order.paymentMethod, 'cod');
      expect(order.total, '3798.00');
      expect(order.delivery, '22 Sep 21:00 - 22:00');
      expect(order.items.length, 2);
      expect(order.itemCount, 6, reason: 'sum of quantities (3 + 3)');

      final item = order.items.first;
      expect(item.orderItemId, 789);
      expect(item.product, 'Product 789');
      expect(item.variant, 'Variant 789');
      expect(item.image, 'https://example.com/product.jpg');
      expect(item.quantity, 3);
      expect(item.subtotal, '1266.00');
    });

    test('order_mode on the order wins over the requested mode', () {
      final order = PendingOrder.fromJson(
        orderJson(1, mode: 'wholesale'),
        fallbackMode: OrderMode.regular,
      );
      expect(order.mode, OrderMode.wholesale);
    });

    test('falls back to the requested mode when order_mode is missing', () {
      final json = orderJson(1)..remove('order_mode');
      expect(
        PendingOrder.fromJson(json, fallbackMode: OrderMode.wholesale).mode,
        OrderMode.wholesale,
      );
      expect(PendingOrder.fromJson(json).mode, OrderMode.regular);
    });

    test('unknown order_mode falls back instead of crashing', () {
      final order = PendingOrder.fromJson(orderJson(1, mode: 'bulk'));
      expect(order.mode, OrderMode.regular);
    });

    test('order_mode is case-insensitive', () {
      expect(
        PendingOrder.fromJson(orderJson(1, mode: 'WHOLESALE')).mode,
        OrderMode.wholesale,
      );
    });

    test('reads the older delivery_slot key', () {
      final json = orderJson(1, delivery: null)
        ..['delivery_slot'] = '19:30 - 20:00';
      expect(PendingOrder.fromJson(json).delivery, '19:30 - 20:00');
    });

    test('ids and quantities sent as strings are parsed', () {
      final json = orderJson(1)
        ..['seller_order_id'] = '55'
        ..['order_id'] = '66';
      (json['items'] as List).first['order_item_id'] = '77';
      (json['items'] as List).first['quantity'] = '4';

      final order = PendingOrder.fromJson(json);
      expect(order.sellerOrderId, 55);
      expect(order.orderId, 66);
      expect(order.items.first.orderItemId, 77);
      expect(order.items.first.quantity, 4);
    });

    test('missing and null fields do not crash', () {
      final order = PendingOrder.fromJson({
        'seller_order_id': 9,
        'customer': null,
        'items': [
          {'order_item_id': 1, 'variant': null, 'image': null},
        ],
      });
      expect(order.customerName, '');
      expect(order.createdAt, isNull);
      expect(order.delivery, isNull);
      expect(order.total, '0');
      expect(order.items.single.variant, isNull);
      expect(order.items.single.image, isNull);
      expect(order.items.single.quantity, 1);
    });

    test('empty strings and the text "null" are treated as missing', () {
      final json = orderJson(1, delivery: '  ');
      (json['items'] as List).first['variant'] = 'null';
      final order = PendingOrder.fromJson(json);
      expect(order.delivery, isNull);
      expect(order.items.first.variant, isNull);
    });

    test('non-list items value gives no items', () {
      final json = orderJson(1)..['items'] = 'oops';
      expect(PendingOrder.fromJson(json).items, isEmpty);
    });
  });

  group('item image', () {
    Map<String, dynamic> itemWith(Map<String, dynamic> extra) => {
      'order_item_id': 1,
      'product': 'P',
      ...extra,
    };

    test('accepts the documented image key and common alternatives', () {
      for (final key in [
        'image',
        'product_image',
        'image_url',
        'main_image',
        'thumbnail',
      ]) {
        final item = PendingOrderItem.fromJson(
          itemWith({key: 'https://x.test/$key.jpg'}),
        );
        expect(item.image, 'https://x.test/$key.jpg', reason: key);
      }
    });

    test('ignores relative paths that cannot be loaded', () {
      expect(
        PendingOrderItem.fromJson(itemWith({'image': '/storage/p.jpg'})).image,
        isNull,
      );
    });
  });
}
