import 'dart:async';
import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/screen/order_page/incoming_orders/model/pending_order_model.dart';
import 'package:hyper_local_seller/screen/order_page/incoming_orders/repo/pending_orders_repo.dart';

/// A pending order as the backend documents it.
Map<String, dynamic> orderJson(
  int sellerOrderId, {
  String mode = 'regular',
  String? createdAt,
  List<int> itemIds = const [1],
  String? image = 'https://example.com/product.jpg',
  String? delivery = '22 Sep 21:00 - 22:00',
}) {
  return {
    'seller_order_id': sellerOrderId,
    'order_id': sellerOrderId * 10,
    'order_number': 'NM-20260922-$sellerOrderId',
    'order_mode': mode,
    'created_at':
        createdAt ??
        DateTime.now()
            .toUtc()
            .subtract(const Duration(seconds: 5))
            .toIso8601String(),
    'customer': {
      'name': 'TUSHAR',
      'phone': '8595857925',
      'address': 'Negr, Bharatnagar, Nagpur, Maharashtra, 440001',
    },
    'payment_method': 'cod',
    'total': '3798.00',
    'delivery': ?delivery,
    'items': [
      for (final id in itemIds)
        {
          'order_item_id': id,
          'product': 'Product $id',
          'variant': 'Variant $id',
          'image': ?image,
          'quantity': 3,
          'subtotal': '1266.00',
        },
    ],
  };
}

Map<String, dynamic> listResponse(
  List<Map<String, dynamic>> orders, {
  String mode = 'regular',
}) => {'data': orders, 'count': orders.length, 'order_mode': mode};

/// In-memory stand-in for the pending-orders API.
class FakePendingOrdersRepo extends PendingOrdersRepo {
  final Map<OrderMode, List<Map<String, dynamic>>> server = {
    OrderMode.regular: [],
    OrderMode.wholesale: [],
  };
  final Set<OrderMode> failing = {};
  final List<String> calls = [];
  final Map<OrderMode, int> fetchCount = {
    OrderMode.regular: 0,
    OrderMode.wholesale: 0,
  };

  /// order_item_ids whose next accept (or preparing) call throws once.
  final Set<int> failAcceptOnce = {};
  final Set<int> failPreparingOnce = {};

  /// When set, accept calls wait for it — simulates a slow network.
  Completer<void>? acceptGate;

  int get totalFetches => fetchCount.values.fold(0, (a, b) => a + b);

  @override
  Future<List<PendingOrder>> getPendingOrders(OrderMode mode) async {
    fetchCount[mode] = fetchCount[mode]! + 1;
    if (failing.contains(mode)) throw Exception('${mode.name} is down');
    return server[mode]!
        .map((json) => PendingOrder.fromJson(json, fallbackMode: mode))
        .toList();
  }

  @override
  Future<dynamic> acceptItem(int orderItemId) async {
    if (acceptGate != null) await acceptGate!.future;
    if (failAcceptOnce.remove(orderItemId)) throw Exception('accept failed');
    calls.add('accept $orderItemId');
  }

  @override
  Future<dynamic> markItemPreparing(int orderItemId) async {
    if (failPreparingOnce.remove(orderItemId)) {
      throw Exception('preparing failed');
    }
    calls.add('preparing $orderItemId');
  }
}

Future<void> initTestHive({String? token = 'test-token'}) async {
  Hive.init(Directory.systemTemp.createTempSync('hive_test').path);
  await HiveStorage.setAccessToken(token);
}
