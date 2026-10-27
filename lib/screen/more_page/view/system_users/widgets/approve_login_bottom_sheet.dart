import 'package:flutter/material.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/login_approvals/login_approvals_cubit.dart';
import 'package:hyper_local_seller/service/demo_guard.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';
import 'package:intl/intl.dart';

/// Shared guard for login access writes, including stale action callbacks.
bool canManageSystemUserLogin(BuildContext context) {
  if (!LoginApprovalsCubit.canManage) {
    showCustomSnackbar(
      context: context,
      message:
          AppLocalizations.of(context)?.noPermissionEditSystemUser ??
          "You don't have permission to edit system users",
      isWarning: true,
    );
    return false;
  }
  return DemoGuard.shouldProceed(context);
}

/// Confirms a system user's login approval. The server grants access for a
/// fixed window (currently 24 hours) and returns `login_approved_until`,
/// which the lists then show; the time here is only an estimate.
class ApproveLoginBottomSheet extends StatelessWidget {
  final String name;
  const ApproveLoginBottomSheet({super.key, required this.name});

  /// Approval length the server currently grants.
  static const approvalWindow = Duration(hours: 24);

  /// True when the seller confirmed.
  static Future<bool> show(BuildContext context, {required String name}) async {
    if (!canManageSystemUserLogin(context)) return false;
    final approved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ApproveLoginBottomSheet(name: name),
    );
    return approved ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screenType = context.screenType;
    final time = DateFormat(
      'dd MMM, hh:mm a',
    ).format(DateTime.now().add(approvalWindow));
    final access = l10n?.accessUntilPreview(time) ?? 'Access until $time';
    final preview = l10n?.aboutAccessUntilPreview(access) ?? 'About $access';
    return SafeArea(
      child: Container(
        padding: EdgeInsets.all(UIUtils.gapMD(screenType)),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.approveLoginFor(name) ?? 'Approve login for $name',
              style: TextStyle(
                fontSize: UIUtils.tileTitle(screenType),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: UIUtils.gapSM(screenType)),
            Text(
              l10n?.approveLoginSubtitle ??
                  "They can sign in for 24 hours. Approval doesn't log them in.",
            ),
            SizedBox(height: UIUtils.gapMD(screenType)),
            Text(
              preview,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: UIUtils.gapMD(screenType)),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(l10n?.cancel ?? 'Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                    ),
                    onPressed: () {
                      if (!canManageSystemUserLogin(context)) return;
                      Navigator.pop(context, true);
                    },
                    child: Text(l10n?.riderApprove ?? 'Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
