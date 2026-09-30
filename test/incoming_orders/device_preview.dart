// Run: flutter run -d emulator-5554 -t test/incoming_orders/device_preview.dart
// Real camera, ringtone, overlay and scan persistence; isolated fake backend.
// The top-right buttons add orders or reset the preview. Airplane mode causes
// preparing to fail. Preview data never uses the production scan-session box.
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hyper_local_seller/bloc/store_switcher/store_switcher_cubit.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/screen/home_page/bloc/home_page/home_page_bloc.dart';
import 'package:hyper_local_seller/screen/home_page/bloc/notification/notification_list_bloc.dart';
import 'package:hyper_local_seller/screen/home_page/repo/home_data_repo.dart';
import 'package:hyper_local_seller/screen/home_page/repo/notification_list_repo.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/repo/store_repo.dart';
import 'package:hyper_local_seller/screen/order_page/bloc/orders/orders_bloc.dart';
import 'package:hyper_local_seller/screen/order_page/incoming_orders/cubit/incoming_orders_cubit.dart';
import 'package:hyper_local_seller/screen/order_page/incoming_orders/model/pending_order_model.dart';
import 'package:hyper_local_seller/screen/order_page/incoming_orders/repo/scan_session_store.dart';
import 'package:hyper_local_seller/screen/order_page/incoming_orders/view/incoming_order_overlay.dart';
import 'package:hyper_local_seller/screen/order_page/incoming_orders/view/incoming_orders_controller.dart';
import 'package:hyper_local_seller/screen/order_page/repo/order_repo.dart';
import 'helpers.dart';

class _PreviewRepo extends FakePendingOrdersRepo {
  final Box box;
  _PreviewRepo(this.box) {
    final raw = box.get('orders');
    server[OrderMode.regular] = raw is String
        ? (jsonDecode(raw) as List).cast<Map<String, dynamic>>()
        : [
            _sample(90, [901, 902, 903, 904, 905]),
          ];
    final saved = box.get('statuses');
    if (saved is String) {
      final decoded = jsonDecode(saved) as Map<String, dynamic>;
      for (final entry in decoded.entries) {
        statuses[int.parse(entry.key)] = {
          for (final item in (entry.value as Map<String, dynamic>).entries)
            int.parse(item.key): item.value as String,
        };
      }
    }
  }
  static Map<String, dynamic> _sample(int id, List<int> items) => orderJson(
    id,
    itemIds: items,
    image: null,
    quantities: {for (final item in items) item: 3},
  );
  Future<void> _saveBackend() async {
    await box.put('orders', jsonEncode(server[OrderMode.regular]));
    await box.put(
      'statuses',
      jsonEncode({
        for (final order in statuses.entries)
          '${order.key}': {
            for (final item in order.value.entries) '${item.key}': item.value,
          },
      }),
    );
  }

  @override
  Future<List<PendingOrder>> getPendingOrders(OrderMode mode) async {
    final orders = await super.getPendingOrders(mode);
    return orders
        .where(
          (order) => order.items.any(
            (item) => statuses[order.sellerOrderId]?[item.orderItemId] == null,
          ),
        )
        .toList();
  }

  @override
  Future<dynamic> acceptItem(int id) async {
    await super.acceptItem(id);
    for (final order in server[OrderMode.regular]!) {
      if ((order['items'] as List).any((item) => item['order_item_id'] == id)) {
        statuses.putIfAbsent(order['seller_order_id'] as int, () => {})[id] =
            'accepted';
      }
    }
    await _saveBackend();
  }

  @override
  Future<dynamic> markItemPreparing(int id) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final connection = await Connectivity().checkConnectivity();
    if (connection.contains(ConnectivityResult.none)) {
      throw Exception('No network connection');
    }
    await super.markItemPreparing(id);
    for (final order in statuses.values) {
      if (order.containsKey(id)) order[id] = 'preparing';
    }
    await _saveBackend();
  }

  Future<void> addOrder() async {
    final id = 91 + server[OrderMode.regular]!.length;
    server[OrderMode.regular]!.add(_sample(id, [id * 10 + 1, id * 10 + 2]));
    await _saveBackend();
  }

  Future<void> reset() async {
    statuses.clear();
    server[OrderMode.regular] = [
      _sample(90, [901, 902, 903, 904, 905]),
    ];
    await _saveBackend();
  }
}

// Refreshes from the popup stay local to the preview.
class _OrdersRepo extends OrdersRepo {
  @override
  Future<dynamic> getOrders({
    int? page,
    int? perPage,
    String? search,
    String? paymentType,
    String? range,
    String? sortBy,
    String? sortDir,
    String? status,
    int? storeId,
    dynamic orderMode,
  }) async => {
    'success': true,
    'data': {'data': [], 'current_page': 1, 'last_page': 1, 'total': 0},
  };
}

class _NotificationsRepo extends NotificationListRepo {
  @override
  Future<dynamic> getUnreadCount() async => {
    'success': true,
    'data': {'unread_count': 0},
  };
}

class _StoresRepo extends StoresRepo {
  @override
  Future<dynamic> getStores({
    int? page,
    int? perPage,
    String? search,
    String? status,
    String? visibilityStatus,
    String? verificationStatus,
  }) async => {
    'success': true,
    'data': {'data': []},
  };
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Hive.initFlutter();
  await HiveStorage.initPrefs();
  if ((HiveStorage.userToken ?? '').isEmpty) {
    await HiveStorage.setAccessToken('preview');
  }
  final repo = _PreviewRepo(await Hive.openBox('incomingOrderPreviewBackend'));
  final store = ScanSessionStore(boxName: 'incomingOrderScansPreview');
  final cubit = IncomingOrdersCubit(repo, store: store);
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider.value(value: cubit),
        BlocProvider(create: (_) => OrdersBloc(_OrdersRepo())),
        BlocProvider(create: (_) => NotificationListBloc(_NotificationsRepo())),
        BlocProvider(create: (_) => StoreSwitcherCubit(_StoresRepo())),
        BlocProvider(create: (_) => HomePageBloc(repo: HomeDataRepo())),
      ],
      child: IncomingOrdersController(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: ThemeMode.system,
          builder: (context, child) => Stack(
            children: [
              IncomingOrderOverlay(child: child!),
              Positioned(
                top: MediaQuery.paddingOf(context).top,
                right: 0,
                child: Material(
                  color: Colors.transparent,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final action in ['Add', 'Fail', 'Reset'])
                        TextButton(
                          onPressed: () async {
                            if (action == 'Add') await repo.addOrder();
                            if (action == 'Reset') {
                              cubit.clear();
                              await store.clear();
                              await repo.reset();
                            }
                            if (action == 'Fail' && cubit.state.hasPending) {
                              repo.failPreparingOnce.add(
                                cubit.state.orders.first.items.last.orderItemId,
                              );
                            }
                            await cubit.fetch();
                          },
                          child: Text(action),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          home: Scaffold(
            appBar: AppBar(title: const Text('Order scan preview')),
            body: BlocBuilder<IncomingOrdersCubit, IncomingOrdersState>(
              builder: (context, state) => ListView(
                children: [
                  const ListTile(
                    title: Text(
                      'Fake backend • real camera and saved progress',
                    ),
                  ),
                  for (final entry in repo.statuses.entries)
                    ListTile(
                      title: Text('Order ${entry.key}'),
                      subtitle: Text(
                        entry.value.values.every((s) => s == 'preparing')
                            ? 'Preparing'
                            : 'Accepted / packing',
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await cubit.fetch();
}
