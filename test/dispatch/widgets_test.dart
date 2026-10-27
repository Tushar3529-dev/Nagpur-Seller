import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local_seller/bloc/screen_size/screen_size_bloc.dart';
import 'package:hyper_local_seller/bloc/store_switcher/store_switcher_cubit.dart';
import 'package:hyper_local_seller/config/app_permissions.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/router/app_routes.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/repo/store_repo.dart';
import 'package:hyper_local_seller/screen/order_page/bloc/orders/orders_bloc.dart';
import 'package:hyper_local_seller/screen/order_page/dispatch/cubit/dispatch_cubit.dart';
import 'package:hyper_local_seller/screen/order_page/dispatch/cubit/rider_availability_cubit.dart';
import 'package:hyper_local_seller/screen/order_page/dispatch/model/dispatch_model.dart';
import 'package:hyper_local_seller/screen/order_page/dispatch/view/dispatch_center_page.dart';
import 'package:hyper_local_seller/screen/order_page/dispatch/widgets/dispatch_alert_banner.dart';
import 'package:hyper_local_seller/screen/order_page/dispatch/widgets/dispatch_order_card.dart';
import 'package:hyper_local_seller/screen/order_page/dispatch/widgets/dispatch_status_badge.dart';
import 'package:hyper_local_seller/screen/order_page/dispatch/widgets/rider_availability_section.dart';
import 'package:hyper_local_seller/screen/order_page/dispatch/widgets/rider_availability_tile.dart';
import 'package:hyper_local_seller/screen/order_page/popup_users/cubit/popup_users_cubit.dart';
import 'package:hyper_local_seller/screen/order_page/popup_users/model/popup_users_model.dart';
import 'package:hyper_local_seller/screen/order_page/popup_users/repo/popup_users_repo.dart';
import 'package:hyper_local_seller/screen/order_page/repo/order_repo.dart';
import 'package:hyper_local_seller/screen/order_page/view/order_page.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';
import '../incoming_orders/helpers.dart';
import 'helpers.dart';

class _NoStores extends StoresRepo {
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

void main() {
  setUpAll(() => initTestHive());
  setUp(
    () => HiveStorage.setUserData({
      'assigned_permissions': [
        AppPermissions.orderView,
        AppPermissions.orderUpdateStatus,
      ],
    }),
  );

  Future<void> open(
    WidgetTester tester,
    Widget child, {
    FakeDispatchRepo? repo,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ScreenSizeBloc()),
          BlocProvider(
            create: (_) => DispatchCubit(repo ?? FakeDispatchRepo()),
          ),
          BlocProvider(
            create: (_) => RiderAvailabilityCubit(repo ?? FakeDispatchRepo()),
          ),
          BlocProvider(create: (_) => OrdersBloc(OrdersRepo())),
          BlocProvider(create: (_) => StoreSwitcherCubit(_NoStores())),
          BlocProvider(create: (_) => PopupUsersCubit(_NotOwner())),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'only permitted pre-acceptance statuses have self-deliver actions',
    (tester) async {
      for (final status in DispatchStatus.values) {
        await open(
          tester,
          DispatchOrderCard(
            order: DispatchOrder(
              orderId: 1,
              orderNumber: 'NM-1',
              status: status,
              rawStatus: status == DispatchStatus.unknown
                  ? 'future_state'
                  : status.value,
            ),
          ),
        );
        expect(
          find.text('Deliver myself'),
          status.canSelfDeliver ? findsOneWidget : findsNothing,
        );
        if (status == DispatchStatus.sellerSelfDelivery) {
          expect(
            find.textContaining(
              "Completing it in the app isn't available yet.",
            ),
            findsOneWidget,
          );
        }
        if (status == DispatchStatus.unknown) {
          expect(find.text('Future state'), findsOneWidget);
        }
        expect(find.textContaining('Mark delivered'), findsNothing);
      }
      await tester.runAsync(
        () => HiveStorage.setUserData({
          'assigned_permissions': [AppPermissions.orderView],
        }),
      );
      await open(
        tester,
        DispatchOrderCard(
          order: DispatchDashboard.fromJson(dashboardJson()).orders.first,
        ),
      );
      expect(find.text('Deliver myself'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'pending offer confirmation names rider and cancellation; Cancel sends no write',
    (tester) async {
      final repo = FakeDispatchRepo();
      await open(
        tester,
        DispatchOrderCard(order: repo.dashboard.orders.last),
        repo: repo,
      );
      await tester.tap(find.text('Deliver myself'));
      await tester.pumpAndSettle();
      expect(find.text('Deliver this order yourself?'), findsOneWidget);
      expect(
        find.textContaining('Rider Name has a pending offer'),
        findsOneWidget,
      );
      expect(find.textContaining('It will be cancelled'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(repo.writeCalls, 0);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'rider tiles label every reason, unknown safely, and format distance/freshness',
    (tester) async {
      const labels = [
        'Offline',
        'Not verified',
        'Notifications not set up',
        'Location not updated recently',
        'No pickup store',
        'Too far from store',
        'Has a pending offer',
        'On a delivery',
        'Future reason',
      ];
      for (var i = 0; i < RiderUnavailableReason.values.length; i++) {
        final reason = RiderUnavailableReason.values[i];
        await open(
          tester,
          RiderAvailabilityTile(
            rider: AvailableRider(
              id: i,
              name: 'Name',
              unavailableReason: reason,
              rawUnavailableReason: reason == RiderUnavailableReason.unknown
                  ? 'future_reason'
                  : reason.value,
              nearestPickupDistanceM: 84,
              locationAgeSeconds: i == 0 ? 18 : 378,
            ),
          ),
        );
        expect(find.text(labels[i]), findsOneWidget);
        expect(find.text('84 m from store'), findsOneWidget);
        expect(
          find.text(i == 0 ? 'Location 18s ago' : 'Location 6m ago'),
          findsOneWidget,
        );
      }
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'visible pages own 15s/30s polling; Orders and Dispatch share rider availability; retained Orders stops off-tab, background, dispose and reset',
    (tester) async {
      final repo = FakeDispatchRepo();
      final dispatch = DispatchCubit(repo);
      final availability = RiderAvailabilityCubit(repo);
      final orders = OrdersBloc(OrdersRepo());
      final screen = ScreenSizeBloc();
      final stores = StoreSwitcherCubit(_NoStores());
      final router = GoRouter(
        initialLocation: AppRoutes.orders,
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (_, _, shell) => Scaffold(body: shell),
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppRoutes.orders,
                    builder: (_, _) => const OrderPage(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/other',
                    builder: (_, _) => const Scaffold(body: Text('Other')),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.dispatchCenter,
            name: AppRoutes.dispatchCenter,
            builder: (_, _) => const DispatchCenterPage(),
          ),
          GoRoute(
            path: '/cover',
            builder: (_, _) => const Scaffold(body: Text('Covered')),
          ),
        ],
      );
      addTearDown(() async {
        router.dispose();
        await dispatch.close();
        await availability.close();
        await orders.close();
        await screen.close();
        await stores.close();
      });
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: dispatch),
            BlocProvider.value(value: availability),
            BlocProvider.value(value: orders),
            BlocProvider.value(value: screen),
            BlocProvider.value(value: stores),
            BlocProvider(create: (_) => PopupUsersCubit(_NotOwner())),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(repo.dashboardCalls, 1);
      expect(repo.availabilityCalls, 1);
      expect(find.byType(RiderAvailabilitySection), findsOneWidget);
      expect(find.text('Dispatch'), findsOneWidget);
      expect(find.byType(DispatchAlertBanner), findsOneWidget);
      await tester.pump(const Duration(seconds: 15));
      await tester.pumpAndSettle();
      expect(repo.dashboardCalls, 2);
      await tester.tap(find.byType(DispatchAlertBanner));
      await tester.pumpAndSettle();
      expect(dispatch.state.filter, DispatchFilter.needsAction);
      expect(find.byType(DispatchCenterPage), findsOneWidget);
      final dashboardAtOpen = repo.dashboardCalls;
      // Whichever page's visibility lands first, the shared timer keeps
      // one availability refresh per 30s.
      final availabilityAtOpen = repo.availabilityCalls;
      await tester.pump(const Duration(seconds: 15));
      await tester.pumpAndSettle();
      expect(repo.dashboardCalls, dashboardAtOpen + 1);
      await tester.pump(const Duration(seconds: 15));
      await tester.pumpAndSettle();
      expect(repo.availabilityCalls, availabilityAtOpen + 1);
      router.push('/cover');
      await tester.pumpAndSettle();
      final covered = (repo.dashboardCalls, repo.availabilityCalls);
      await tester.pump(const Duration(seconds: 60));
      expect((repo.dashboardCalls, repo.availabilityCalls), covered);
      router.pop();
      await tester.pumpAndSettle();
      expect(repo.availabilityCalls, covered.$2 + 1);
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      final paused = (repo.dashboardCalls, repo.availabilityCalls);
      await tester.pump(const Duration(seconds: 60));
      expect((repo.dashboardCalls, repo.availabilityCalls), paused);
      for (final state in [
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pumpAndSettle();
      expect(
        (repo.dashboardCalls, repo.availabilityCalls),
        (paused.$1 + 1, paused.$2 + 1),
      );
      router.pop();
      await tester.pumpAndSettle();
      final onOrders = repo.availabilityCalls;
      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();
      expect(repo.availabilityCalls, onOrders + 1);
      router.go('/other');
      await tester.pumpAndSettle();
      final offTab = (repo.dashboardCalls, repo.availabilityCalls);
      await tester.pump(const Duration(seconds: 60));
      expect((repo.dashboardCalls, repo.availabilityCalls), offTab);
      router.go(AppRoutes.orders);
      await tester.pumpAndSettle();
      expect(
        (repo.dashboardCalls, repo.availabilityCalls),
        (offTab.$1 + 1, offTab.$2 + 1),
      );
      dispatch.reset();
      availability.reset();
      final reset = (repo.dashboardCalls, repo.availabilityCalls);
      await tester.pump(const Duration(seconds: 60));
      expect((repo.dashboardCalls, repo.availabilityCalls), reset);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 60));
      expect((repo.dashboardCalls, repo.availabilityCalls), reset);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'availability 403 hides entire section and no permission makes no dispatch requests',
    (tester) async {
      final repo = FakeDispatchRepo()
        ..availabilityError = ApiException('Forbidden', statusCode: 403);
      final router = GoRouter(
        initialLocation: AppRoutes.dispatchCenter,
        routes: [
          GoRoute(
            path: AppRoutes.dispatchCenter,
            builder: (_, _) => const DispatchCenterPage(),
          ),
        ],
      );
      addTearDown(router.dispose);
      final dispatch = DispatchCubit(repo);
      final availability = RiderAvailabilityCubit(repo);
      addTearDown(dispatch.close);
      addTearDown(availability.close);
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: dispatch),
            BlocProvider.value(value: availability),
            BlocProvider(create: (_) => ScreenSizeBloc()),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Riders near your stores'), findsNothing);
      expect(find.text('Forbidden'), findsNothing);
      await tester.runAsync(
        () => HiveStorage.setUserData({'assigned_permissions': []}),
      );
      await tester.pumpAndSettle();
      final count = (repo.dashboardCalls, repo.availabilityCalls);
      await tester.pump(const Duration(seconds: 60));
      expect((repo.dashboardCalls, repo.availabilityCalls), count);
      await tester.pumpWidget(const SizedBox());
    },
  );
}

/// Popup user availability is owner-only; these tests aren't the owner.
class _NotOwner extends PopupUsersRepo {
  @override
  Future<PopupUsersAvailability> getAvailability() async =>
      throw ApiException('Forbidden', statusCode: 403);
}
