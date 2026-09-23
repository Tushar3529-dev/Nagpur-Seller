import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
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

import 'package:hyper_local_seller/service/order_ringtone_service.dart';

import 'helpers.dart';

/// Orders without images: network images need sqflite (cache), which is not
/// available in widget tests. Image parsing is covered in model_test.dart.
Map<String, dynamic> _order(
  int id, {
  String mode = 'regular',
  String? createdAt,
  List<int> itemIds = const [1],
}) => orderJson(
  id,
  mode: mode,
  createdAt: createdAt,
  itemIds: itemIds,
  image: null,
);

/// Records what the app asks the audio plugin to do.
final audioCalls = <String>[];

void _mockPlatformChannels() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  Future<Object?> audio(MethodCall call) async {
    final args = call.arguments;
    final mode = args is Map ? args['releaseMode'] : null;
    audioCalls.add(
      mode == null
          ? call.method
          : '${call.method}:${mode.toString().split('.').last}',
    );
    return null;
  }

  messenger.setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers'),
    audio,
  );
  messenger.setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers.global'),
    audio,
  );
  for (final name in [
    'xyz.luan/audioplayers.global/events',
    'xyz.luan/audioplayers/events/incoming_order_ringtone',
  ]) {
    messenger.setMockStreamHandler(
      EventChannel(name),
      MockStreamHandler.inline(onListen: (_, _) {}),
    );
  }
  // audioplayers copies the asset to a temp file before playing it.
  final tempDir = Directory.systemTemp.createTempSync('audio_test').path;
  messenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (_) async => tempDir,
  );
  messenger.setMockMethodCallHandler(
    const MethodChannel('dexterous.com/flutter/local_notifications'),
    (_) async => null,
  );
  messenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/firebase_messaging'),
    (_) async => null,
  );
}

final _storeSwitcher = StoreSwitcherCubit(StoresRepo());

Widget _app(IncomingOrdersCubit cubit, {double textScale = 1.0}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider.value(value: cubit),
      BlocProvider(create: (_) => OrdersBloc(OrdersRepo())),
      BlocProvider(create: (_) => NotificationListBloc(NotificationListRepo())),
      // Shared, never closed: StoreSwitcherCubit.loadStores emits without an
      // isClosed check, which throws if its request finishes after teardown.
      BlocProvider.value(value: _storeSwitcher),
      BlocProvider(create: (_) => HomePageBloc(repo: HomeDataRepo())),
    ],
    child: IncomingOrdersController(
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: IncomingOrderOverlay(child: child!),
        ),
        home: const Scaffold(body: Center(child: Text('Home screen'))),
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
    _mockPlatformChannels();
    await initTestHive();
  });

  late FakePendingOrdersRepo repo;
  late IncomingOrdersCubit cubit;

  setUp(() async {
    await HiveStorage.setAccessToken('test-token');
    audioCalls.clear();
    repo = FakePendingOrdersRepo();
    cubit = IncomingOrdersCubit(repo);
  });

  Future<void> pumpApp(
    WidgetTester tester, {
    Size size = const Size(412, 915),
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.runAsync(() => cubit.fetch());
    await tester.pumpWidget(_app(cubit, textScale: textScale));
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> disposeApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  // Runs first: OrderRingtoneService is a singleton and its AudioPlayer can be
  // left waiting on a fake-async zone from an earlier test.
  testWidgets('ringtone loops while pending and stops after the last accept', (
    tester,
  ) async {
    await tester.runAsync(() => OrderRingtoneService().stop());
    audioCalls.clear();

    // App starts with nothing pending, like before an order arrives.
    await pumpApp(tester);
    expect(OrderRingtoneService().isRinging, isFalse);
    expect(audioCalls, isNot(contains('resume')));

    // A new order shows up on the next 5 s poll.
    repo.server[OrderMode.regular] = [_order(1)];
    await tester.pump(const Duration(seconds: 5));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();

    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }
    expect(find.text('Accept and prepare order'), findsOneWidget);
    expect(OrderRingtoneService().isRinging, isTrue);
    expect(audioCalls, contains('setReleaseMode:loop'), reason: 'loops');

    repo.server[OrderMode.regular] = [];
    await tester.tap(find.text('Accept and prepare order'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Accept and prepare order'), findsNothing);
    expect(OrderRingtoneService().isRinging, isFalse, reason: 'ring stopped');
    expect(audioCalls, contains('stop'));
    expect(repo.calls, ['accept 1', 'preparing 1']);
    await disposeApp(tester);
  });

  testWidgets('no pending orders: app shows normally, no ringing', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.text('Home screen'), findsOneWidget);
    expect(find.text('Accept and prepare order'), findsNothing);
    expect(audioCalls, isNot(contains('resume')));
    await disposeApp(tester);
  });

  testWidgets('regular order shows every field', (tester) async {
    repo.server[OrderMode.regular] = [
      _order(1, itemIds: [11, 12]),
    ];
    await pumpApp(tester);

    expect(find.text('New regular order'), findsOneWidget);
    expect(find.text('Order #NM-20260922-1'), findsOneWidget);
    expect(find.text('TUSHAR'), findsOneWidget);
    expect(find.text('8595857925'), findsOneWidget);
    expect(find.textContaining('Bharatnagar'), findsOneWidget);
    expect(find.text('ORDER TYPE'), findsOneWidget);
    expect(find.text('Regular'), findsOneWidget);
    expect(find.text('ORDERED'), findsOneWidget);
    expect(find.text('Cash on delivery'), findsOneWidget);
    expect(find.textContaining('3798.00'), findsOneWidget);
    expect(find.text('6 items'), findsOneWidget);
    expect(find.text('22 Sep 21:00 - 22:00'), findsOneWidget);
    expect(find.text('Product 11'), findsOneWidget);
    expect(find.text('Variant 12 · Qty 3'), findsOneWidget);
    expect(find.text('WAITING'), findsOneWidget);
    expect(find.text('Accept and prepare order'), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('wholesale order uses the same popup with wholesale labels', (
    tester,
  ) async {
    repo.server[OrderMode.wholesale] = [
      _order(5, mode: 'wholesale', createdAt: '2026-09-18T08:00:00Z'),
    ];
    await pumpApp(tester);

    expect(find.text('Wholesale order due soon'), findsOneWidget);
    expect(find.text('Wholesale'), findsOneWidget);
    expect(
      find.text('Delivery slot ends within 30 minutes. Start preparing.'),
      findsOneWidget,
    );
    // Timer counts from when the popup appeared, not the order date days ago.
    expect(find.text('00:00'), findsOneWidget);
    expect(find.text('WAITING'), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('timer counts up and turns overdue after 60 s', (tester) async {
    repo.server[OrderMode.regular] = [
      _order(
        1,
        createdAt: DateTime.now()
            .toUtc()
            .subtract(const Duration(seconds: 75))
            .toIso8601String(),
      ),
    ];
    await pumpApp(tester);
    expect(find.text('OVERDUE'), findsOneWidget);
    expect(find.textContaining('01:1'), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('queue: shows one at a time with a waiting count', (
    tester,
  ) async {
    repo.server[OrderMode.regular] = [_order(1), _order(2)];
    repo.server[OrderMode.wholesale] = [_order(3, mode: 'wholesale')];
    await pumpApp(tester);

    expect(find.text('3 orders waiting'), findsOneWidget);
    expect(find.text('INCOMING ORDER · 1 OF 3'), findsOneWidget);
    expect(find.text('Accept and prepare order'), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('popup cannot be dismissed by tapping outside', (tester) async {
    repo.server[OrderMode.regular] = [_order(1)];
    await pumpApp(tester);

    await tester.tapAt(const Offset(5, 5));
    await tester.tapAt(const Offset(400, 900));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Accept and prepare order'), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('Android back button is swallowed while orders are pending', (
    tester,
  ) async {
    repo.server[OrderMode.regular] = [_order(1)];
    await pumpApp(tester);

    final handled = await tester.binding.handlePopRoute();
    expect(handled, isTrue, reason: 'back press consumed, app not closed');
    await tester.pump();
    expect(find.text('Accept and prepare order'), findsOneWidget);
    await disposeApp(tester);
  });

  // Regression: on Android with predictive back, if the framework reports it
  // can't handle back, the OS closes the app without calling didPopRoute.
  // Found on the Pixel 10 Pro emulator (API 37).
  testWidgets('tells Android the app handles Back while orders are pending', (
    tester,
  ) async {
    final reported = <bool>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemNavigator.setFrameworkHandlesBack') {
          reported.add(call.arguments as bool);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

    await pumpApp(tester);
    reported.clear();

    // Order arrives: must report true even though the home route can't pop.
    repo.server[OrderMode.regular] = [_order(1)];
    await tester.pump(const Duration(seconds: 5));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    await tester.pump();
    expect(reported.last, isTrue);

    // Accepted, queue empty: hand Back back to the system (home can't pop).
    repo.server[OrderMode.regular] = [];
    await tester.tap(find.text('Accept and prepare order'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
    await tester.pump();
    expect(reported.last, isFalse);
    // Let the post-accept refreshes of the other blocs settle.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    await disposeApp(tester);
  });

  testWidgets('back button works normally with no pending orders', (
    tester,
  ) async {
    await pumpApp(tester);
    final controller = tester.state(find.byType(IncomingOrdersController));
    expect(await (controller as WidgetsBindingObserver).didPopRoute(), isFalse);
    await disposeApp(tester);
  });

  testWidgets('accept moves to the next order in the queue', (tester) async {
    final now = DateTime.now().toUtc();
    repo.server[OrderMode.regular] = [
      _order(
        1,
        createdAt: now.subtract(const Duration(minutes: 1)).toIso8601String(),
      ),
      _order(2, createdAt: now.toIso8601String()),
    ];
    await pumpApp(tester);
    expect(find.text('Order #NM-20260922-1'), findsOneWidget);

    await tester.tap(find.text('Accept and prepare order'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Order #NM-20260922-2'), findsOneWidget);
    expect(find.text('1 order waiting'), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('error then retry', (tester) async {
    repo.server[OrderMode.regular] = [_order(1)];
    repo.failAcceptOnce.add(1);
    await pumpApp(tester);

    await tester.tap(find.text('Accept and prepare order'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();

    expect(find.textContaining("Couldn't accept this order"), findsOneWidget);
    expect(find.text('Retry accept'), findsOneWidget);

    repo.server[OrderMode.regular] = [];
    await tester.tap(find.text('Retry accept'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Retry accept'), findsNothing);
    expect(find.text('Accept and prepare order'), findsNothing);
    await disposeApp(tester);
  });

  testWidgets('shows a spinner while accepting', (tester) async {
    repo.server[OrderMode.regular] = [_order(1)];
    await pumpApp(tester);
    repo.acceptGate = Completer();

    await tester.tap(find.text('Accept and prepare order'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Accept and prepare order'), findsNothing);

    repo.acceptGate!.complete();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await disposeApp(tester);
  });

  testWidgets('polls every 5 seconds', (tester) async {
    await pumpApp(tester);
    final start = repo.totalFetches;

    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(seconds: 5));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
    }
    // 3 ticks x 2 endpoints.
    expect(repo.totalFetches - start, 6);
    await disposeApp(tester);
  });

  testWidgets('new order is picked up by the next poll', (tester) async {
    await pumpApp(tester);
    expect(find.text('Accept and prepare order'), findsNothing);

    repo.server[OrderMode.wholesale] = [_order(9, mode: 'wholesale')];
    await tester.pump(const Duration(seconds: 5));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Wholesale order due soon'), findsOneWidget);
    await disposeApp(tester);
  });

  for (final (size, scale) in [
    (const Size(360, 640), 1.0),
    (const Size(360, 640), 1.5),
    (const Size(412, 915), 2.0),
    (const Size(800, 1280), 1.0),
  ]) {
    testWidgets('no overflow at ${size.width.toInt()}x${size.height.toInt()} '
        'with text scale $scale', (tester) async {
      repo.server[OrderMode.regular] = [
        _order(1, itemIds: [1, 2, 3, 4, 5, 6, 7, 8]),
      ];
      repo.server[OrderMode.wholesale] = [_order(2, mode: 'wholesale')];
      await pumpApp(tester, size: size, textScale: scale);
      expect(tester.takeException(), isNull);
      expect(find.text('Accept and prepare order'), findsOneWidget);
      await disposeApp(tester);
    });
  }
}
