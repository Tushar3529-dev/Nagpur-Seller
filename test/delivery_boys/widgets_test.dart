import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_local_seller/bloc/screen_size/screen_size_bloc.dart';
import 'package:hyper_local_seller/config/app_permissions.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/screen/more_page/view/delivery_boys/bloc/delivery_boy_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/delivery_boys/view/add_edit_rider_page.dart';
import 'package:hyper_local_seller/screen/more_page/view/delivery_boys/view/delivery_boys_page.dart';
import 'package:hyper_local_seller/screen/more_page/view/delivery_boys/widgets/login_duration_sheet.dart';
import 'package:hyper_local_seller/screen/more_page/view/delivery_zone/bloc/delivery_zone_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/delivery_zone/repo/delivery_zone_repo.dart';
import '../incoming_orders/helpers.dart';
import 'state_test.dart' show FakeRepo;

class _Zones extends DeliveryZoneRepo {
  @override
  Future<dynamic> getDeliveryZone({
    int? page,
    int? perPage,
    String? search,
  }) async => {
    'success': true,
    'data': {
      'current_page': 1,
      'last_page': 1,
      'total': 2,
      'data': [
        {
          'id': 1,
          'name': 'Active zone',
          'slug': 'active-zone',
          'status': 'active',
        },
        {
          'id': 2,
          'name': 'Inactive zone',
          'slug': 'inactive-zone',
          'status': 'inactive',
        },
      ],
    },
  };
}

void main() {
  setUpAll(() => initTestHive());
  setUp(
    () => HiveStorage.setUserData({
      'assigned_permissions': [
        AppPermissions.deliveryBoyView,
        AppPermissions.deliveryBoyManage,
      ],
    }),
  );
  Future<void> open(WidgetTester tester, Widget home, {FakeRepo? repo}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      RepositoryProvider<DeliveryZoneRepo>(
        create: (_) => _Zones(),
        child: MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => ScreenSizeBloc()),
            BlocProvider(
              create: (_) => DeliveryBoyBloc(repo: repo ?? FakeRepo()),
            ),
            BlocProvider(create: (_) => DeliveryZoneBloc(_Zones())),
          ],
          child: MaterialApp(home: home),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'duration picker starts at 12h, distinguishes default from cancel and validates bounds',
    (tester) async {
      LoginDurationSelection? result;
      await open(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await LoginDurationSheet.show(context);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '12h'))
            .selected,
        isTrue,
      );
      await tester.tap(find.widgetWithText(ChoiceChip, 'Custom'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '721');
      await tester.pumpAndSettle();
      expect(find.text('Enter a whole number from 1 to 720'), findsOneWidget);
      await tester.ensureVisible(find.text('Confirm'));
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginDurationSheet), findsOneWidget);
      await tester.tap(find.text('Use platform default'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Confirm'));
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(result, isNotNull);
      expect(result!.hours, isNull);
    },
  );
  testWidgets(
    'rotation omits the default option and requires a valid duration',
    (tester) async {
      LoginDurationSelection? result;
      await open(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await LoginDurationSheet.show(context, rotate: true);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Use platform default'), findsNothing);
      await tester.tap(find.widgetWithText(ChoiceChip, '6h'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Confirm'));
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(result?.hours, 6);
    },
  );
  testWidgets('form validates required fields and lists only active zones', (
    tester,
  ) async {
    await open(tester, const AddEditRiderPage());
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Full name is required'), findsOneWidget);
    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
    expect(find.text('Select a delivery zone'), findsOneWidget);
    await tester.ensureVisible(find.byType(DropdownButtonFormField<int>));
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    expect(find.text('Active zone'), findsOneWidget);
    expect(find.text('Inactive zone'), findsNothing);
  });
  testWidgets(
    'list debounces search, refreshes silently each minute, and stops while paused or disposed',
    (tester) async {
      final repo = FakeRepo();
      await open(tester, const DeliveryBoysPage(), repo: repo);
      expect(repo.calls.length, 1);
      expect(find.text('Rider 1'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'rider');
      await tester.pump(const Duration(milliseconds: 399));
      expect(repo.calls.length, 1);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pumpAndSettle();
      expect(repo.calls.last.search, 'rider');
      final before = repo.calls.length;
      await tester.pump(const Duration(seconds: 60));
      await tester.pumpAndSettle();
      expect(repo.calls.length, before + 1);
      expect(find.text('Rider 1'), findsOneWidget);
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      final paused = repo.calls.length;
      await tester.pump(const Duration(seconds: 120));
      expect(repo.calls.length, paused);
      for (final state in [
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pumpAndSettle();
      expect(repo.calls.length, paused + 1);
      await tester.pumpWidget(const SizedBox());
      final disposed = repo.calls.length;
      await tester.pump(const Duration(seconds: 120));
      expect(repo.calls.length, disposed);
    },
  );
  testWidgets('view-only permission hides Available and add actions', (
    tester,
  ) async {
    await tester.runAsync(
      () => HiveStorage.setUserData({
        'assigned_permissions': [AppPermissions.deliveryBoyView],
      }),
    );
    await open(tester, const DeliveryBoysPage());
    expect(find.text('My riders (2)'), findsOneWidget);
    expect(find.textContaining('Available ('), findsNothing);
    expect(find.byIcon(Icons.add), findsNothing);
    expect(find.text('Approve'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
