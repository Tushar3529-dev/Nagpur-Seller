import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_local_seller/screen/order_page/dispatch/cubit/dispatch_cubit.dart';
import 'package:hyper_local_seller/screen/order_page/dispatch/model/dispatch_model.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';
import 'helpers.dart';

void main() {
  late FakeDispatchRepo repo;
  late DispatchCubit cubit;
  setUp(() {
    repo = FakeDispatchRepo();
    cubit = DispatchCubit(repo);
  });
  tearDown(() => cubit.close());
  test(
    'load sets dashboard and local lastUpdated; silent errors retain data',
    () async {
      expect(cubit.pollInterval, const Duration(seconds: 15));
      await cubit.load();
      expect(cubit.state.dashboard, repo.dashboard);
      expect(cubit.state.lastUpdated, isNotNull);
      repo.dashboardError = ApiException('Offline');
      await cubit.refresh();
      expect(cubit.state.dashboard, repo.dashboard);
      expect(cubit.state.error, isNull);
      expect(cubit.state.isRefreshing, isFalse);
    },
  );
  test('first load exposes only API message and retry recovers', () async {
    repo.dashboardError = ApiException('Server message');
    await cubit.load();
    expect(cubit.state.error, 'Server message');
    expect(cubit.state.isLoading, isFalse);
    repo.dashboardError = null;
    await cubit.load();
    expect(cubit.state.error, isNull);
    expect(cubit.state.dashboard, isNotNull);
  });
  test('filters and priority sort use oldest first within a status', () async {
    final orders = [
      for (final status in DispatchStatus.values)
        for (final day in [2, 1])
          DispatchOrder(
            orderId: status.index * 10 + day,
            orderNumber: '$day',
            status: status,
            createdAt: DateTime(2026, 10, day),
          ),
    ];
    repo.dashboard = DispatchDashboard(orders: orders);
    await cubit.load();
    expect(cubit.state.visibleOrders.map((o) => o.orderId), [
      1,
      2,
      21,
      22,
      11,
      12,
      31,
      32,
      41,
      42,
      51,
      52,
    ]);
    cubit.setFilter(DispatchFilter.needsAction);
    expect(cubit.state.visibleOrders.map((o) => o.orderId), [1, 2]);
    cubit.setFilter(DispatchFilter.awaiting);
    expect(cubit.state.visibleOrders.map((o) => o.orderId), [21, 22, 11, 12]);
    cubit.setFilter(DispatchFilter.assigned);
    expect(cubit.state.visibleOrders.map((o) => o.orderId), [31, 32, 41, 42]);
  });
  test('success updates optimistically, clears rider and reconciles', () async {
    await cubit.load();
    repo.writeGate = Completer<void>();
    final write = cubit.selfDeliver(184);
    final optimistic = cubit.state.dashboard!.orders.last;
    expect(optimistic.status, DispatchStatus.sellerSelfDelivery);
    expect(optimistic.deliveryBoyName, isNull);
    expect(optimistic.deliveryBoyId, isNull);
    expect(cubit.state.pendingSelfDeliver, {184});
    repo.writeGate!.complete();
    final result = await write;
    expect(result.isSuccess, isTrue);
    expect(result.message, 'Order marked for seller self-delivery.');
    await Future<void>.delayed(Duration.zero);
    expect(repo.dashboardCalls, 2);
    expect(cubit.state.pendingSelfDeliver, isEmpty);
    expect(
      cubit.state.dashboard!.orders.last.status,
      DispatchStatus.sellerSelfDelivery,
    );
  });
  test('no-rider count decrements without becoming negative', () async {
    await cubit.load();
    repo.writeGate = Completer<void>();
    final write = cubit.selfDeliver(183);
    expect(cubit.state.dashboard!.summary.noNearbyRiders, 0);
    repo.writeGate!.complete();
    await write;
  });
  for (final status in [409, 404, 403, 422, 500]) {
    test(
      '$status restores order and summary, returns server message',
      () async {
        await cubit.load();
        final original = cubit.state.dashboard;
        repo.writeError = ApiException('Server $status', statusCode: status);
        repo.dashboardGate = Completer<DispatchDashboard>();
        final result = await cubit.selfDeliver(183);
        expect(result.isSuccess, isFalse);
        expect(result.statusCode, status);
        expect(result.message, 'Server $status');
        expect(cubit.state.dashboard, original);
        expect(cubit.state.pendingSelfDeliver, isEmpty);
        expect(repo.dashboardCalls, status == 409 || status == 404 ? 2 : 1);
        repo.dashboardGate!.complete(repo.dashboard);
      },
    );
  }
  test(
    'rollback restores exact summary even when the no-rider count was already zero',
    () async {
      repo.dashboard = DispatchDashboard(orders: repo.dashboard.orders);
      await cubit.load();
      final original = cubit.state.dashboard;
      repo.writeError = ApiException('Failed', statusCode: 500);
      await cubit.selfDeliver(183);
      expect(cubit.state.dashboard, original);
      expect(cubit.state.dashboard!.summary.noNearbyRiders, 0);
    },
  );

  test('duplicate pending write is ignored', () async {
    await cubit.load();
    repo.writeGate = Completer<void>();
    final first = cubit.selfDeliver(183);
    expect((await cubit.selfDeliver(183)).isIgnored, isTrue);
    expect(repo.writeCalls, 1);
    repo.writeGate!.complete();
    await first;
  });
  test(
    'refresh ignores overlapping reads; poll never undoes pending self-delivery',
    () async {
      await cubit.load();
      repo.writeGate = Completer<void>();
      final write = cubit.selfDeliver(183);
      repo.dashboardGate = Completer<DispatchDashboard>();
      final read = cubit.refresh();
      final duplicate = cubit.refresh();
      expect(repo.dashboardCalls, 2);
      repo.dashboardGate!.complete(repo.dashboard);
      await Future.wait([read, duplicate]);
      expect(
        cubit.state.dashboard!.orders.first.status,
        DispatchStatus.sellerSelfDelivery,
      );
      repo.dashboardGate = null;
      repo.writeGate!.complete();
      await write;
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.isRefreshing, isFalse);
    },
  );
  test(
    'reset discards stale reads and writes from the previous session',
    () async {
      await cubit.load();
      repo.writeGate = Completer<void>();
      final write = cubit.selfDeliver(183);
      repo.dashboardGate = Completer<DispatchDashboard>();
      final read = cubit.refresh();
      cubit.reset();
      repo.dashboardGate!.complete(repo.dashboard);
      repo.writeGate!.complete();
      await read;
      expect((await write).isIgnored, isTrue);
      expect(cubit.state, const DispatchState());
    },
  );
  for (final action in ['stop', 'close', 'reset']) {
    test('polling is idempotent and $action cancels timer', () async {
      await cubit.close();
      cubit = DispatchCubit(
        repo,
        pollInterval: const Duration(milliseconds: 10),
      );
      cubit.startPolling();
      cubit.startPolling();
      expect(repo.dashboardCalls, 1);
      await Future<void>.delayed(const Duration(milliseconds: 45));
      expect(repo.dashboardCalls, greaterThanOrEqualTo(3));
      switch (action) {
        case 'stop':
          cubit.stopPolling();
        case 'close':
          await cubit.close();
        case 'reset':
          cubit.reset();
      }
      final count = repo.dashboardCalls;
      await Future<void>.delayed(const Duration(milliseconds: 35));
      expect(repo.dashboardCalls, count);
      if (action == 'reset') expect(cubit.state, const DispatchState());
    });
  }
  test(
    'releasing one page retains shared polling until last page releases it',
    () async {
      await cubit.close();
      cubit = DispatchCubit(
        repo,
        pollInterval: const Duration(milliseconds: 10),
      );
      final orders = Object();
      final dispatch = Object();
      cubit.setPollingOwner(orders, visible: true);
      cubit.setPollingOwner(dispatch, visible: true);
      cubit.setPollingOwner(orders, visible: false);
      await Future<void>.delayed(const Duration(milliseconds: 35));
      expect(repo.dashboardCalls, greaterThan(1));
      cubit.setPollingOwner(dispatch, visible: false);
      final count = repo.dashboardCalls;
      await Future<void>.delayed(const Duration(milliseconds: 25));
      expect(repo.dashboardCalls, count);
    },
  );
}
