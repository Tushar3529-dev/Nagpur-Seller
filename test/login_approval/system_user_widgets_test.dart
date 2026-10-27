import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_local_seller/bloc/screen_size/screen_size_bloc.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/bloc/system_user_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/login_approvals/login_approvals_cubit.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/login_approvals/login_approvals_page.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/view/system_users_page.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/widgets/approve_login_bottom_sheet.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/widgets/system_user_detail_bottom_sheet.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/widgets/system_user_status_badges.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_card.dart';
import 'package:hyper_local_seller/widgets/custom/custom_loading_indicator.dart';
import 'system_user_helpers.dart';

void main() {
  late FakeSystemUsersRepo repo;
  late SystemUserBloc bloc;
  late LoginApprovalsCubit inbox;
  late ScreenSizeBloc screen;
  setUpAll(initSystemUserHive);
  setUp(() async {
    repo = FakeSystemUsersRepo();
    bloc = SystemUserBloc(repo: repo);
    inbox = LoginApprovalsCubit(repo: repo);
    screen = ScreenSizeBloc();
    await HiveStorage.setSystemSettings({'demoMode': false});
    await HiveStorage.setUserData({
      'assigned_permissions': ['system_user.view', 'system_user.edit'],
    });
  });
  tearDown(() async {
    await bloc.close();
    await inbox.close();
    await screen.close();
  });

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  }

  Future<void> pumpApp(
    WidgetTester tester,
    Widget home, {
    bool dark = false,
    double width = 390,
  }) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    screen.add(ScreenSizeChanged(Size(width, 900)));
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: screen),
          BlocProvider.value(value: bloc),
          BlocProvider.value(value: inbox),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          theme: dark ? ThemeData.dark() : ThemeData.light(),
          home: home,
        ),
      ),
    );
    await settle(tester);
  }

  Widget sheetLauncher(void Function(bool) onChoice) => Scaffold(
    body: Builder(
      builder: (context) => TextButton(
        onPressed: () async => onChoice(
          await ApproveLoginBottomSheet.show(context, name: 'Staff User'),
        ),
        child: const Text('Open approval'),
      ),
    ),
  );

  Future<void> openSheet(
    WidgetTester tester,
    void Function(bool) onChoice,
  ) async {
    await pumpApp(tester, sheetLauncher(onChoice));
    await tester.tap(find.text('Open approval'));
    await settle(tester);
  }

  testWidgets(
    'approval is a fixed 24 h confirm: no duration picker; Approve returns '
    'true and Cancel false',
    (tester) async {
      bool? approved;
      await openSheet(tester, (value) => approved = value);
      expect(find.textContaining('24 hours'), findsOneWidget);
      expect(find.textContaining('About Access until'), findsOneWidget);
      expect(find.byType(ChoiceChip), findsNothing);
      expect(find.byType(TextField), findsNothing);
      await tester.tap(find.text('Approve'));
      await settle(tester);
      expect(approved, isTrue);

      await tester.tap(find.text('Open approval'));
      await settle(tester);
      await tester.tap(find.text('Cancel'));
      await settle(tester);
      expect(approved, isFalse);
    },
  );

  testWidgets('permission and DemoGuard prevent opening approval sheet', (
    tester,
  ) async {
    await tester.runAsync(
      () => HiveStorage.setUserData({
        'assigned_permissions': ['system_user.view'],
      }),
    );
    await openSheet(tester, (_) {});
    expect(find.byType(ApproveLoginBottomSheet), findsNothing);
    expect(find.textContaining("permission"), findsOneWidget);
    await tester.runAsync(
      () => HiveStorage.setUserData({
        'assigned_permissions': ['system_user.view', 'system_user.edit'],
      }),
    );
    await tester.runAsync(
      () => HiveStorage.setSystemSettings({'demoMode': true}),
    );
    await tester.tap(find.text('Open approval'));
    await settle(tester);
    expect(find.byType(ApproveLoginBottomSheet), findsNothing);
  });

  for (final dark in [false, true]) {
    for (final width in [360.0, 1024.0]) {
      testWidgets(
        'badges and card render independently in dark=$dark width=$width',
        (tester) async {
          await pumpApp(
            tester,
            Scaffold(
              body: CustomCard(
                type: CardType.systemUser,
                screenType: width > 600 ? ScreenType.tablet : ScreenType.mobile,
                data: {
                  'id': 196,
                  'name': 'Staff User With A Long Name',
                  'accessPanel': 'seller',
                  'email': 'staff@example.com',
                  'mobile': '9876543210',
                  'systemUserStatus': 'inactive',
                  'loginApprovalStatus': 'approved',
                  'loginApprovedUntil': DateTime(2020, 10, 26, 13, 30),
                },
                onEdit: () {},
                onDelete: () {},
              ),
            ),
            dark: dark,
            width: width,
          );
          expect(find.text('Inactive'), findsOneWidget);
          expect(find.text('Approved'), findsOneWidget);
          expect(find.text('until 26 Oct, 01:30 PM'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'list approval patches row and refreshes inbox without full loading',
    (tester) async {
      await pumpApp(tester, const SystemUsersPage());
      expect(
        find.text('Pending'),
        findsOneWidget,
        reason:
            'status=${bloc.state.status}, rows=${bloc.state.users.length}, fetches=${repo.fetches}, error=${bloc.state.errorMessage}, text=${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).toList()}',
      );
      await tester.tap(find.text('Approve'));
      await settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Approve').last);
      await settle(tester);
      expect(repo.approvals, 1);
      expect(repo.fetches, 2);
      expect(repo.inboxFetches, greaterThanOrEqualTo(2));
      expect(find.text('Approved'), findsOneWidget);
      expect(find.text('Inactive'), findsOneWidget);
      expect(find.textContaining('Login approved until'), findsOneWidget);
    },
  );

  testWidgets('inbox approval asks for confirmation and syncs the users bloc', (
    tester,
  ) async {
    bloc.add(FetchSystemUsersEvent());
    await tester.pump();
    await pumpApp(tester, const LoginApprovalsPage());
    await tester.tap(find.text('Approve'));
    await settle(tester);
    expect(repo.approvals, 0);
    await tester.tap(find.widgetWithText(FilledButton, 'Approve').last);
    await settle(tester);
    expect(repo.approvals, 1);
    expect(bloc.state.users.single.isApproved, isTrue);
    expect(repo.fetches, 2);
    expect(inbox.state.total, 0);
    expect(find.textContaining('Login approved until'), findsOneWidget);
  });

  testWidgets(
    'detail loads, approves locally, then confirms and revokes access',
    (tester) async {
      await pumpApp(
        tester,
        Scaffold(
          body: SystemUserDetailBottomSheet(id: 196, bloc: bloc, repo: repo),
        ),
      );
      expect(repo.detailFetches, 1);
      expect(find.text('Last requested'), findsOneWidget);
      expect(find.text('—'), findsNWidgets(2));
      await tester.tap(find.widgetWithText(FilledButton, 'Approve').last);
      await settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Approve').last);
      await settle(tester);
      expect(repo.approvals, 1);
      expect(find.text('Approved'), findsOneWidget);
      expect(find.text('Extend access'), findsOneWidget);
      await tester.tap(find.text('Revoke access'));
      await settle(tester);
      expect(repo.rejections, 0);
      expect(find.text('Revoke access?'), findsOneWidget);
      await tester.tap(find.text('Revoke'));
      await settle(tester);
      expect(repo.rejections, 1);
      expect(find.text('Disapproved'), findsOneWidget);
      expect(find.text('Inactive'), findsNWidgets(2));
      expect(find.text('—'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'detail error retries and read-only permissions hide write buttons',
    (tester) async {
      repo.detailError = ApiException('Try loading again');
      await tester.runAsync(
        () => HiveStorage.setUserData({
          'assigned_permissions': ['system_user.view'],
        }),
      );
      await pumpApp(
        tester,
        Scaffold(
          body: SystemUserDetailBottomSheet(id: 196, bloc: bloc, repo: repo),
        ),
      );
      expect(find.text('Try loading again'), findsOneWidget);
      repo.detailError = null;
      await tester.tap(find.text('Try Again'));
      await settle(tester);
      expect(repo.detailFetches, 2);
      expect(find.byType(LoginApprovalBadge), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Approve'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'Disapprove'), findsNothing);
    },
  );

  testWidgets('in-flight detail action hides actions and ignores a duplicate', (
    tester,
  ) async {
    repo.decisionGate = Completer<void>();
    await pumpApp(
      tester,
      Scaffold(
        body: SystemUserDetailBottomSheet(id: 196, bloc: bloc, repo: repo),
      ),
    );
    await tester.tap(find.text('Approve'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Approve').last);
    await tester.pump(const Duration(milliseconds: 400));
    expect(repo.approvals, 1);
    expect(find.byType(CustomLoadingIndicator), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SystemUserDetailBottomSheet),
        matching: find.widgetWithText(FilledButton, 'Approve'),
      ),
      findsNothing,
    );
    repo.decisionGate!.complete();
    await settle(tester);
    expect(find.text('Approved'), findsOneWidget);
  });

  Widget detailLauncher() => Scaffold(
    body: Builder(
      builder: (context) => TextButton(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) =>
              SystemUserDetailBottomSheet(id: 196, bloc: bloc, repo: repo),
        ),
        child: const Text('Open detail'),
      ),
    ),
  );

  testWidgets('detail 404 shows server message, closes and refreshes list', (
    tester,
  ) async {
    repo.detailError = ApiException('User no longer exists', statusCode: 404);
    await pumpApp(tester, detailLauncher());
    await tester.tap(find.text('Open detail'));
    await settle(tester);
    expect(find.byType(SystemUserDetailBottomSheet), findsNothing);
    expect(find.text('User no longer exists'), findsOneWidget);
    expect(repo.fetches, 1);
  });

  for (final status in [404, 422]) {
    testWidgets(
      'detail decision $status preserves message and closes only on 404',
      (tester) async {
        repo.decisionError = ApiException(
          'Server decision error',
          statusCode: status,
        );
        await pumpApp(tester, detailLauncher());
        await tester.tap(find.text('Open detail'));
        await settle(tester);
        await tester.tap(find.text('Approve'));
        await settle(tester);
        await tester.tap(find.widgetWithText(FilledButton, 'Approve').last);
        await settle(tester);
        expect(find.text('Server decision error'), findsOneWidget);
        expect(
          find.byType(SystemUserDetailBottomSheet),
          status == 404 ? findsNothing : findsOneWidget,
        );
        expect(repo.fetches, status == 404 ? 1 : 0);
      },
    );
  }

  for (final width in [360.0, 1024.0]) {
    testWidgets('dark detail and approval sheet fit width=$width', (
      tester,
    ) async {
      repo.row = userJson(
        approval: 'approved',
        activity: 'active',
        until: '2026-10-26T08:00:00Z',
      );
      await pumpApp(tester, detailLauncher(), dark: true, width: width);
      await tester.tap(find.text('Open detail'));
      await settle(tester);
      expect(find.text('Active (logged in)'), findsOneWidget);
      await tester.tap(find.text('Extend access'));
      await settle(tester);
      expect(find.byType(ApproveLoginBottomSheet), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Cancel'));
      await settle(tester);
    });
  }

  for (final page in [const SystemUsersPage(), const LoginApprovalsPage()]) {
    testWidgets('${page.runtimeType} refreshes on resume', (tester) async {
      await pumpApp(tester, page);
      final usersBefore = repo.fetches;
      final inboxBefore = repo.inboxFetches;
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await settle(tester);
      expect(repo.inboxFetches, greaterThan(inboxBefore));
      if (page is SystemUsersPage) {
        expect(repo.fetches, greaterThan(usersBefore));
      }
    });
  }
}
