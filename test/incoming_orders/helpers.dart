import 'dart:async';
import 'dart:io';
import 'package:hyper_local_seller/screen/order_page/incoming_orders/repo/scan_session_store.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/screen/order_page/incoming_orders/model/pending_order_model.dart';
import 'package:hyper_local_seller/screen/order_page/incoming_orders/repo/pending_orders_repo.dart';

/// A pending order as the backend documents it.
Map<String, dynamic> orderJson(
  int sellerOrderId, {
  Map<int, String> barcodes = const {},
  Map<int, int> quantities = const {},
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
          'quantity': quantities[id] ?? 3,
          'barcode': barcodes[id] ?? 'A${itemIds.indexOf(id) + 1}',
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
  Completer<void>? preparingGate;
  final Map<int, Map<int, String>> statuses = {};
  final Set<int> failStatusFor = {};

  /// Bags assigned, as "sellerOrderId barcode".
  final List<String> bagCalls = [];
  Object? assignBagError;
  Completer<void>? bagGate;
  int availableBags = 5;
  int bagCountCalls = 0;

  /// Thrown once by the next [markOrderPreparing].
  Object? prepareError;

  @override
  Future<AssignedBag> assignBag(PendingOrder order, String barcode) async {
    if (bagGate != null) await bagGate!.future;
    if (assignBagError != null) throw assignBagError!;
    bagCalls.add('${order.sellerOrderId} ${barcode.trim()}');
    return AssignedBag(id: order.sellerOrderId, barcode: barcode.trim());
  }

  @override
  Future<int> availableBagCount() async {
    bagCountCalls++;
    return availableBags;
  }

  @override
  Future<Map<int, String>> itemStatuses(int sellerOrderId) async {
    if (failStatusFor.contains(sellerOrderId)) throw Exception('offline');
    return statuses[sellerOrderId] ?? {};
  }

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
  Future<PendingOrder> acceptOrder(
    PendingOrder order, {
    Set<int> skipItemIds = const {},
    void Function(int)? onItemAccepted,
  }) async {
    for (final item in order.items) {
      if (skipItemIds.contains(item.orderItemId)) continue;
      await acceptItem(item.orderItemId);
      onItemAccepted?.call(item.orderItemId);
    }
    return order.copyWith(
      items: [
        for (final item in order.items) item.copyWith(status: 'accepted'),
      ],
    );
  }

  @override
  Future<void> markOrderPreparing(
    PendingOrder order, {
    Map<int, String> verifiedBarcodes = const {},
    Set<int> skipItemIds = const {},
    void Function(int)? onItemDone,
  }) async {
    if (prepareError case final error?) {
      prepareError = null;
      throw error;
    }
    for (final item in order.items) {
      if (skipItemIds.contains(item.orderItemId) ||
          statuses[order.sellerOrderId]?[item.orderItemId] == 'preparing') {
        continue;
      }
      await markItemPreparing(item.orderItemId);
      statuses.putIfAbsent(order.sellerOrderId, () => {})[item.orderItemId] =
          'preparing';
      onItemDone?.call(item.orderItemId);
    }
  }

  @override
  Future<dynamic> acceptItem(int orderItemId) async {
    if (acceptGate != null) await acceptGate!.future;
    if (failAcceptOnce.remove(orderItemId)) throw Exception('accept failed');
    calls.add('accept $orderItemId');
  }

  @override
  Future<dynamic> markItemPreparing(
    int orderItemId, {
    String? barcode,
    int? quantity,
  }) async {
    if (preparingGate != null) await preparingGate!.future;
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

class FakeScanSessionStore extends ScanSessionStore {
  List<ScanSession> sessions = [];
  final List<List<ScanSession>> saves = [];
  int clearCount = 0;

  @override
  Future<List<ScanSession>> load() async => List.of(sessions);

  @override
  Future<void> save(Iterable<ScanSession> value) async {
    sessions = List.of(value);
    saves.add(List.of(sessions));
  }

  @override
  Future<void> clear() async {
    clearCount++;
    sessions = [];
  }
}
