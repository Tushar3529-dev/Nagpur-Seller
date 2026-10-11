import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local_seller/bloc/screen_size/screen_size_bloc.dart';
import 'package:hyper_local_seller/bloc/store_switcher/store_switcher_cubit.dart';
import 'package:hyper_local_seller/config/app_permissions.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/screen/dashboard/dashboard.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/repo/store_repo.dart';
import 'package:hyper_local_seller/screen/order_page/bloc/orders/orders_bloc.dart';
import 'package:hyper_local_seller/screen/order_page/repo/order_repo.dart';

import '../incoming_orders/helpers.dart';

class _NoStoresRepo extends StoresRepo {
  @override
  Future<dynamic> getStores({
    int? page,
    int? perPage,
    String? search,
    String? status,
    String? visibilityStatus,
    String? verificationStatus,
  }) async => throw Exception('offline');
}

GoRouter _router(String initialLocation) {
  GoRoute page(String path) => GoRoute(
    path: path,
    builder: (_, _) => Center(child: Text('page:$path')),
  );
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) =>
            Dashboard(index: shell.currentIndex, navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [page('/home')]),
          StatefulShellBranch(routes: [page('/orders')]),
          StatefulShellBranch(routes: [page('/products')]),
          StatefulShellBranch(routes: [page('/more')]),
        ],
      ),
    ],
  );
}

void main() {
  setUpAll(() => initTestHive());

  Future<void> grant(List<String> permissions) =>
      HiveStorage.setUserData({'assigned_permissions': permissions});

  Future<void> pumpDashboard(
    WidgetTester tester, {
    String initialLocation = '/home',
  }) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ScreenSizeBloc()),
          BlocProvider(create: (_) => StoreSwitcherCubit(_NoStoresRepo())),
          BlocProvider(create: (_) => OrdersBloc(OrdersRepo())),
        ],
        child: MaterialApp.router(routerConfig: _router(initialLocation)),
      ),
    );
    await tester.pumpAndSettle();
  }

  List<String> barLabels(WidgetTester tester) => tester
      .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
      .items
      .map((item) => item.label!)
      .toList();

  testWidgets('every tab shows with order and product access', (tester) async {
    await tester.runAsync(
      () => grant([AppPermissions.orderView, AppPermissions.productView]),
    );
    await pumpDashboard(tester);

    expect(barLabels(tester), ['Home', 'Orders', 'Scan', 'Products', 'More']);

    await tester.tap(find.text('Orders'));
    await tester.pumpAndSettle();
    expect(find.text('page:/orders'), findsOneWidget);
  });

  testWidgets('Orders tab is hidden without order.view', (tester) async {
    await tester.runAsync(() => grant([AppPermissions.productView]));
    await pumpDashboard(tester);

    expect(barLabels(tester), ['Home', 'Scan', 'Products', 'More']);

    // Bar positions still open the right branches.
    await tester.tap(find.text('Products'));
    await tester.pumpAndSettle();
    expect(find.text('page:/products'), findsOneWidget);
    expect(
      tester
          .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
          .currentIndex,
      2,
    );

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.text('page:/more'), findsOneWidget);
  });

  testWidgets('Scan and Products are hidden without product.view', (
    tester,
  ) async {
    await tester.runAsync(() => grant([AppPermissions.orderView]));
    await pumpDashboard(tester);

    expect(barLabels(tester), ['Home', 'Orders', 'More']);
  });

  testWidgets('only Home and More remain with neither module', (tester) async {
    await tester.runAsync(() => grant([]));
    await pumpDashboard(tester);

    expect(barLabels(tester), ['Home', 'More']);
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.text('page:/more'), findsOneWidget);
  });

  testWidgets('opening a hidden tab directly falls back to Home', (
    tester,
  ) async {
    await tester.runAsync(() => grant([AppPermissions.productView]));
    await pumpDashboard(tester, initialLocation: '/orders');

    expect(find.text('page:/home'), findsOneWidget);
    expect(barLabels(tester), isNot(contains('Orders')));
  });

  testWidgets('losing order.view while on Orders hides the tab', (
    tester,
  ) async {
    await tester.runAsync(() => grant([AppPermissions.orderView]));
    await pumpDashboard(tester, initialLocation: '/orders');
    expect(find.text('page:/orders'), findsOneWidget);

    await tester.runAsync(() => grant([]));
    await tester.pumpAndSettle();

    expect(barLabels(tester), ['Home', 'More']);
    expect(find.text('page:/home'), findsOneWidget);
  });
}
