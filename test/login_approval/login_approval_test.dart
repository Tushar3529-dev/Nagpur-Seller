import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/model/login_approval_model.dart';
import 'package:hyper_local_seller/service/session_manager.dart';

void main() {
  group('LoginApprovalsPage.fromJson', () {
    test('parses the paginated pending list', () {
      final page = LoginApprovalsPage.fromJson({
        'success': true,
        'message': 'Pending login approvals retrieved.',
        'data': {
          'current_page': 1,
          'last_page': 2,
          'per_page': 15,
          'total': 16,
          'data': [
            {
              'user_id': 196,
              'name': 'Staff User',
              'email': 'staff@example.com',
              'mobile': '9876543210',
              'login_approval_status': 'pending',
              'login_approval_requested_at': '2026-10-07T12:00:00.000000Z',
              'login_approved_until': null,
            },
          ],
        },
      });

      expect(page.total, 16);
      expect(page.lastPage, 2);
      expect(page.items, hasLength(1));
      final item = page.items.single;
      expect(item.userId, 196);
      expect(item.name, 'Staff User');
      expect(item.status, 'pending');
      expect(item.requestedAt!.toUtc(), DateTime.utc(2026, 10, 7, 12));
      expect(item.approvedUntil, isNull);
    });

    test('tolerates an empty body', () {
      final page = LoginApprovalsPage.fromJson({'success': true});
      expect(page.items, isEmpty);
      expect(page.total, 0);
    });
  });

  group('SessionManager.isLoginApprovalError', () {
    test('matches the approval middleware 403 body', () {
      expect(
        SessionManager.isLoginApprovalError({
          'success': false,
          'message': 'Seller approval is required to access this account.',
          'data': {'login_approval_status': 'disapproved'},
        }),
        isTrue,
      );
    });

    test('ignores other 403 bodies such as missing permissions', () {
      expect(
        SessionManager.isLoginApprovalError({
          'success': false,
          'message': 'This action is unauthorized.',
          'data': <String, dynamic>{},
        }),
        isFalse,
      );
      expect(SessionManager.isLoginApprovalError('Forbidden'), isFalse);
    });
  });
}
