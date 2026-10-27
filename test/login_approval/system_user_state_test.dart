import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/bloc/system_user_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/login_approvals/login_approvals_cubit.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/model/login_approval_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/model/system_users_model.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';
import 'system_user_helpers.dart';

void main() {
  setUpAll(initSystemUserHive);
  test('null, unknown, and independent statuses round trip safely', () {
    final user = SystemUser.fromJson(
      userJson(approval: 'unknown', activity: 'unknown'),
    );
    expect(user.loginApprovalStatus, 'not_requested');
    expect(user.systemUserStatus, 'inactive');
    expect(user.loginApprovedUntil, isNull);
    expect(user.loginApprovalRequestedAt, isNull);
    final approved = SystemUser.fromJson(
      userJson(approval: 'approved', until: '2020-01-01T08:00:00Z'),
    );
    expect(approved.isApproved, isTrue);
    expect(approved.isActive, isFalse);
    expect(approved.loginApprovedUntil!.isUtc, isFalse);
    expect(approved.toJson()['login_approval_status'], 'approved');
    expect(
      approved.copyWithApproval(clearApprovedUntil: true).loginApprovedUntil,
      isNull,
    );
    expect(
      approved.copyWithApproval(systemUserStatus: 'active').isActive,
      isTrue,
    );
    expect(
      approved.copyWithApproval().loginApprovedUntil,
      approved.loginApprovedUntil,
    );
  });
  test('detail uses all top-level statuses even when absent or null', () {
    final detail = SystemUserDetail.fromJson({
      'user': userJson(
        approval: 'approved',
        activity: 'active',
        until: '2099-01-01T08:00:00Z',
      ),
      'login_approval_status': 'pending',
      'system_user_status': 'inactive',
      'login_approved_until': null,
    });
    expect(detail.user.isApprovalPending, isTrue);
    expect(detail.user.isActive, isFalse);
    expect(detail.user.loginApprovedUntil, isNull);
    expect(detail.user.name, 'Staff User');
    expect(() => SystemUserDetail.fromJson({}), throwsA(isA<ApiException>()));
  });
  test(
    'pending request and decision parse user_id, timestamps and defaults',
    () {
      final request = LoginApprovalRequest.fromJson({
        ...userJson(activity: 'active'),
        'user_id': '196',
      });
      expect(request.userId, 196);
      expect(request.systemUserStatus, 'active');
      final result = LoginApprovalResult.fromJson({
        'user_id': '196',
        'login_approval_status': 'invalid',
        'system_user_status': null,
        'login_approved_until': 'invalid',
      });
      expect(result.loginApprovalStatus, 'not_requested');
      expect(result.systemUserStatus, 'inactive');
      expect(result.loginApprovedUntil, isNull);
    },
  );
  test(
    'approve patches immediately, blocks duplicate decisions and silently refreshes search',
    () async {
      final repo = FakeSystemUsersRepo()
        ..decisionGate = Completer()
        ..refreshGate = Completer();
      final bloc = SystemUserBloc(repo: repo);
      bloc.add(FetchSystemUsersEvent(search: 'packer'));
      await bloc.stream.firstWhere((s) => s.status == SystemUserStatus.success);
      final states = <SystemUserState>[];
      final subscription = bloc.stream.listen(states.add);
      bloc.add(ApproveSystemUserLoginEvent(id: 196));
      await bloc.stream.firstWhere((s) => s.processingIds.contains(196));
      bloc.add(ApproveSystemUserLoginEvent(id: 196));
      bloc.add(DisapproveSystemUserLoginEvent(id: 196));
      await Future<void>.delayed(Duration.zero);
      expect(repo.approvals, 1);
      expect(repo.rejections, 0);
      repo.decisionGate!.complete();
      final patched = await bloc.stream.firstWhere(
        (s) => s.approvalResult != null,
      );
      expect(patched.users.single.isApproved, isTrue);
      expect(patched.users.single.isActive, isFalse);
      expect(patched.processingIds, isEmpty);
      expect(patched.actionMessage, contains('Login approved until'));
      await Future<void>.delayed(Duration.zero);
      expect(repo.fetches, 2);
      expect(repo.search, 'packer');
      expect(repo.approvals, 1);
      expect(states.every((s) => s.status != SystemUserStatus.loading), isTrue);
      repo.refreshGate!.complete();
      await bloc.close();
      await subscription.cancel();
    },
  );
  test(
    'apply event patches without networking; reject clears expiry',
    () async {
      final repo = FakeSystemUsersRepo();
      final bloc = SystemUserBloc(repo: repo);
      bloc.add(FetchSystemUsersEvent());
      await bloc.stream.firstWhere((s) => s.status == SystemUserStatus.success);
      bloc.add(ApplyLoginApprovalResultEvent(repo.result));
      await bloc.stream.firstWhere((s) => s.users.single.isApproved);
      expect(repo.fetches, 1);
      bloc.add(DisapproveSystemUserLoginEvent(id: 196));
      final revoked = await bloc.stream.firstWhere(
        (s) => s.approvalResult?.loginApprovalStatus == 'disapproved',
      );
      expect(revoked.users.single.isDisapproved, isTrue);
      expect(revoked.users.single.isActive, isFalse);
      expect(revoked.users.single.loginApprovedUntil, isNull);
      expect(revoked.actionMessage, 'Access revoked');
      await bloc.close();
    },
  );
  for (final status in [422, 404]) {
    test(
      '$status preserves API message, clears processing and refetches on not found',
      () async {
        final repo = FakeSystemUsersRepo()
          ..decisionError = ApiException(
            'Server validation',
            statusCode: status,
          );
        final bloc = SystemUserBloc(repo: repo);
        bloc.add(FetchSystemUsersEvent());
        await bloc.stream.firstWhere(
          (s) => s.status == SystemUserStatus.success,
        );
        bloc.add(ApproveSystemUserLoginEvent(id: 196));
        final failure = await bloc.stream.firstWhere(
          (s) => s.errorMessage != null,
        );
        expect(failure.errorMessage, 'Server validation');
        expect(failure.processingIds, isEmpty);
        expect(failure.approvalErrorStatus, status);
        await Future<void>.delayed(Duration.zero);
        expect(repo.fetches, status == 404 ? 2 : 1);
        await bloc.close();
      },
    );
  }
  test(
    'inbox duration and decision result remove pending row and refresh count',
    () async {
      final repo = FakeSystemUsersRepo();
      final cubit = LoginApprovalsCubit(repo: repo);
      await cubit.fetch();
      final decisions = <LoginApprovalsState>[];
      final subscription = cubit.stream.listen((s) {
        if (s.actionMessage != null) decisions.add(s);
      });
      await cubit.approve(196);
      await Future<void>.delayed(Duration.zero);
      expect(repo.inboxFetches, 2);
      expect(cubit.state.total, 0);
      expect(cubit.state.lastResult!.systemUserStatus, 'inactive');
      expect(decisions.single.actionMessage, contains('Login approved until'));
      await subscription.cancel();
      await cubit.close();
    },
  );
  test('create/edit/delete events keep working', () async {
    final bloc = SystemUserBloc(repo: FakeSystemUsersRepo());
    bloc.add(ManageSystemUserEvent(data: {'name': 'New'}));
    await bloc.stream.firstWhere((s) => s.actionMessage == 'Saved');
    bloc.add(ManageSystemUserEvent(data: {'id': 196, 'name': 'Edit'}));
    await bloc.stream.firstWhere((s) => s.actionMessage == 'Saved');
    bloc.add(DeleteSystemUserEvent(id: 196));
    await bloc.stream.firstWhere((s) => s.actionMessage == 'Deleted');
    await bloc.close();
  });
}
