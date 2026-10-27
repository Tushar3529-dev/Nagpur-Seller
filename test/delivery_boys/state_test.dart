import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_local_seller/config/app_permissions.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/screen/more_page/view/delivery_boys/model/delivery_boy_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/delivery_boys/bloc/delivery_boy_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/delivery_boys/qr/rider_qr_cubit.dart';
import 'package:hyper_local_seller/screen/more_page/view/delivery_boys/repo/delivery_boy_repo.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';
import '../incoming_orders/helpers.dart';

DeliveryBoy rider(
  int id, {
  String status = 'inactive',
  String approval = 'pending',
  DateTime? until,
}) => DeliveryBoy.fromJson({
  'id': id,
  'user_id': '42',
  'name': 'Rider $id',
  'verification_status': 'verified',
  'status': status,
  'login_approval_status': approval,
  'login_approved_until': until?.toUtc().toIso8601String(),
});
RiderPage page(List<DeliveryBoy> data, int number) => RiderPage(
  currentPage: number,
  lastPage: 2,
  perPage: 15,
  total: 2,
  data: data,
);

class FakeRepo extends DeliveryBoyRepo {
  final calls = <({int page, int availablePage, String? search})>[];
  bool conflict = false;
  Completer<DeliveryBoysListResponse>? fetchGate;
  int qrCalls = 0;
  bool expiredQr = false;
  Object? qrError;
  @override
  Future<DeliveryBoysListResponse> getRiders({
    int page = 1,
    int availablePage = 1,
    int perPage = 15,
    String? search,
  }) async {
    calls.add((page: page, availablePage: availablePage, search: search));
    if (fetchGate != null) return fetchGate!.future;
    return DeliveryBoysListResponse(
      assigned: assigned(page),
      available: available(availablePage),
    );
  }

  RiderPage assigned(int number) => page([rider(number)], number);
  RiderPage available(int number) => page([rider(10 + number)], number);
  @override
  Future<Map<String, dynamic>> approveLogin(
    int riderId, {
    int? durationHours,
  }) async {
    return {
      'message': 'Approved by server',
      'data': {
        'rider_id': riderId,
        'login_approval_status': 'approved',
        'login_approved_until': DateTime.now()
            .add(const Duration(hours: 6))
            .toUtc()
            .toIso8601String(),
        'status': 'inactive',
      },
    };
  }

  @override
  Future<Map<String, dynamic>> rejectLogin(int riderId) async {
    return {
      'message': 'Rejected by server',
      'data': {
        'rider_id': riderId,
        'login_approval_status': 'disapproved',
        'login_approved_until': null,
        'status': 'inactive',
      },
    };
  }

  @override
  Future<DeliveryBoyResult> claimRider(int riderId) async {
    if (conflict) {
      throw ApiException(
        'Already claimed',
        statusCode: 409,
        responseData: {
          'data': {'code': 'rider_already_assigned'},
        },
      );
    }
    return (rider: rider(riderId), message: 'Claimed');
  }

  @override
  Future<RiderQrCredential> getLoginQr(int riderId) async {
    qrCalls++;
    if (qrError != null) throw qrError!;
    return RiderQrCredential(
      riderId: riderId,
      qrPayload: 'payload-$qrCalls',
      expiresAt: DateTime.now().add(
        expiredQr && qrCalls == 1
            ? const Duration(seconds: -1)
            : const Duration(hours: 6),
      ),
    );
  }

  @override
  Future<RiderQrResult> rotateLoginQr(
    int riderId, {
    required int durationHours,
  }) async {
    return (
      message: 'Rotated by server',
      credential: RiderQrCredential(
        riderId: riderId,
        qrPayload: 'replacement',
        expiresAt: DateTime.now().add(Duration(hours: durationHours)),
      ),
    );
  }
}

Future<DeliveryBoyState> nextState(
  DeliveryBoyBloc bloc,
  bool Function(DeliveryBoyState) predicate,
) => bloc.stream.firstWhere(predicate).timeout(const Duration(seconds: 3));
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
  test(
    'status remains independent of verification and live/expired approvals',
    () {
      final live = rider(
        1,
        approval: 'approved',
        until: DateTime.now().add(const Duration(hours: 1)),
      );
      expect(live.isVerified, isTrue);
      expect(live.isApprovalLive, isTrue);
      expect(live.isActive, isFalse);
      final expired = rider(
        1,
        status: 'active',
        approval: 'approved',
        until: DateTime.now().subtract(const Duration(seconds: 1)),
      );
      expect(expired.isApprovalExpired, isTrue);
      expect(expired.isActive, isTrue);
      expect(rider(1, approval: 'approved').isApprovalExpired, isTrue);
      expect(
        rider(1, status: 'unknown', approval: 'unknown').status,
        RiderStatus.inactive,
      );
      expect(
        rider(1, approval: 'unknown').loginApproval,
        RiderLoginApproval.disapproved,
      );
    },
  );
  test(
    'each paginator merges only its own list and search survives refresh',
    () async {
      final repo = FakeRepo();
      final bloc = DeliveryBoyBloc(repo: repo);
      addTearDown(bloc.close);
      var done = nextState(bloc, (s) => s.status == DeliveryBoyStatus.success);
      bloc.add(const FetchRiders());
      await done;
      done = nextState(bloc, (s) => s.assignedPage == 2);
      bloc.add(LoadMoreAssigned());
      await done;
      expect(bloc.state.assigned.map((r) => r.id), [1, 2]);
      expect(bloc.state.available.map((r) => r.id), [11]);
      done = nextState(bloc, (s) => s.availablePage == 2);
      bloc.add(LoadMoreAvailable());
      await done;
      expect(bloc.state.available.map((r) => r.id), [11, 12]);
      expect(repo.calls.last.page, 1);
      expect(repo.calls.last.availablePage, 2);
      done = nextState(bloc, (s) => s.search == 'query' && s.assignedPage == 1);
      bloc.add(const SearchChanged('query'));
      await done;
      done = nextState(bloc, (s) => !s.isRefreshing);
      bloc.add(const FetchRiders(silent: true));
      await done;
      expect(repo.calls.last.search, 'query');
      expect(bloc.state.status, DeliveryBoyStatus.success);
    },
  );
  test('approve/reject apply responses locally before the refresh', () async {
    final repo = FakeRepo();
    final bloc = DeliveryBoyBloc(repo: repo);
    addTearDown(bloc.close);
    var done = nextState(bloc, (s) => s.status == DeliveryBoyStatus.success);
    bloc.add(const FetchRiders());
    await done;
    repo.fetchGate = Completer();
    done = nextState(bloc, (s) => s.actionMessage == 'Approved by server');
    bloc.add(const ApproveLogin(1, 6));
    await done;
    expect(bloc.state.assigned.single.isApprovalLive, isTrue);
    expect(bloc.state.assigned.single.isActive, isFalse);
    done = nextState(bloc, (s) => s.actionMessage == 'Rejected by server');
    bloc.add(const RejectLogin(1));
    await done;
    expect(
      bloc.state.assigned.single.loginApproval,
      RiderLoginApproval.disapproved,
    );
    expect(bloc.state.assigned.single.loginApprovedUntil, isNull);
    final reset = nextState(bloc, (s) => s.status == DeliveryBoyStatus.initial);
    bloc.add(DeliveryBoyReset());
    await reset;
    repo.fetchGate!.complete(
      DeliveryBoysListResponse(assigned: page([], 1), available: page([], 1)),
    );
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.status, DeliveryBoyStatus.initial);
  });
  test('409 removes the conflicting rider and refreshes silently', () async {
    final repo = FakeRepo()..conflict = true;
    final bloc = DeliveryBoyBloc(repo: repo);
    addTearDown(bloc.close);
    var done = nextState(bloc, (s) => s.status == DeliveryBoyStatus.success);
    bloc.add(const FetchRiders());
    await done;
    repo.fetchGate = Completer();
    done = nextState(bloc, (s) => s.errorMessage == 'Already claimed');
    bloc.add(const ClaimRider(11));
    await done;
    expect(bloc.state.available, isEmpty);
    final refreshing = nextState(bloc, (s) => s.isRefreshing);
    await refreshing;
    repo.fetchGate!.complete(
      DeliveryBoysListResponse(assigned: page([], 1), available: page([], 1)),
    );
  });
  test('permission denial prevents list and mutations', () async {
    await HiveStorage.setUserData({'assigned_permissions': []});
    final repo = FakeRepo();
    final bloc = DeliveryBoyBloc(repo: repo);
    addTearDown(bloc.close);
    bloc.add(const FetchRiders());
    bloc.add(const ClaimRider(11));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(repo.calls, isEmpty);
    expect(bloc.state.busyRiderIds, isEmpty);
  });
  test(
    'expired QR reloads automatically and rotation signals a list refresh',
    () async {
      final repo = FakeRepo()..expiredQr = true;
      final cubit = RiderQrCubit(repo: repo, riderId: 1);
      addTearDown(cubit.close);
      await cubit.load();
      await cubit.stream
          .firstWhere(
            (s) => !s.loading && s.credential?.qrPayload == 'payload-2',
          )
          .timeout(const Duration(seconds: 3));
      expect(repo.qrCalls, 2);
      expect(cubit.state.refreshVersion, 1);
      expect(cubit.state.remaining > Duration.zero, isTrue);
      await cubit.rotate(6);
      expect(cubit.state.credential?.qrPayload, 'replacement');
      expect(cubit.state.rotatedMessage, 'Rotated by server');
      expect(cubit.state.refreshVersion, 2);
      await cubit.close();
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      expect(repo.qrCalls, 2);
    },
  );
  test('unverified QR 422 exposes only the API message', () async {
    final repo = FakeRepo()
      ..qrError = ApiException(
        'Platform verification required',
        statusCode: 422,
      );
    final cubit = RiderQrCubit(repo: repo, riderId: 1);
    addTearDown(cubit.close);
    await cubit.load();
    expect(cubit.state.errorMessage, 'Platform verification required');
    expect(cubit.state.credential, isNull);
  });
}
