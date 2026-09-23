// On-device preview of the incoming-order popup with sample data.
//
//   flutter run -d <device> -t test/incoming_orders/device_preview.dart
//
// Uses the real overlay, controller (5 s polling, back-button blocking) and
// ringtone, but a fake repo: accepting sends nothing to the backend.
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
import 'package:hyper_local_seller/screen/order_page/incoming_orders/view/incoming_order_overlay.dart';
import 'package:hyper_local_seller/screen/order_page/incoming_orders/view/incoming_orders_controller.dart';
import 'package:hyper_local_seller/screen/order_page/repo/order_repo.dart';

import 'helpers.dart';

const _img = 'https://admin.nagpurmart.in/storage';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Hive.initFlutter();
  await HiveStorage.initPrefs();
  if ((HiveStorage.userToken ?? '').isEmpty) {
    await HiveStorage.setAccessToken('preview');
  }

  final now = DateTime.now().toUtc();
  final repo = FakePendingOrdersRepo();
  repo.server[OrderMode.regular] = [
    orderJson(
      91,
      createdAt: now.subtract(const Duration(seconds: 20)).toIso8601String(),
      itemIds: [189],
      image: '$_img/1219/whatsapp-image-2026-09-16-at-210748.jpeg',
    )..['items'][0]['product'] = 'Airtight Storage Containers Set of 4',
    orderJson(
      90,
      createdAt: now.subtract(const Duration(minutes: 3)).toIso8601String(),
      itemIds: [188],
      image: '$_img/948/71trl6lohbl-ac-uf10001000-ql80.jpg',
    ),
  ];
  repo.server[OrderMode.wholesale] = [
    orderJson(
        99,
        mode: 'wholesale',
        createdAt: '2026-09-22T16:57:46.000000Z',
        itemIds: [206, 207],
        image:
            '$_img/916/led-desk-lamp-foldable-1200mah-battery-usb-charging-touch-original-imahnfkrenpyrzyb.webp',
      )
      ..['customer'] = {
        'name': 'Kunal',
        'phone': '9394070912',
        'address': '43XJ+RJ5, Sitabuldi, Nagpur, Maharashtra, 440001',
      }
      ..['items'][0]['product'] = 'LED Desk Lamp with USB Charging'
      ..['items'][1]['product'] = 'Milton Insulated Water Bottle 1L',
  ];

  final cubit = IncomingOrdersCubit(repo);
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider.value(value: cubit),
        BlocProvider(create: (_) => OrdersBloc(OrdersRepo())),
        BlocProvider(
          create: (_) => NotificationListBloc(NotificationListRepo()),
        ),
        BlocProvider(create: (_) => StoreSwitcherCubit(StoresRepo())),
        BlocProvider(create: (_) => HomePageBloc(repo: HomeDataRepo())),
      ],
      child: IncomingOrdersController(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          builder: (context, child) => IncomingOrderOverlay(child: child!),
          home: Scaffold(
            appBar: AppBar(title: const Text('Popup preview')),
            body: Center(
              child: Text(
                'Accepted calls: ${repo.calls.length}',
                key: const Key('status'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  cubit.fetch();
}
