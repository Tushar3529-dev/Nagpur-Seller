import 'package:flutter/material.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/model/login_approval_model.dart';
import 'package:intl/intl.dart';

class SystemUserActivityBadge extends StatelessWidget {
  final String status;
  const SystemUserActivityBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final active = status == 'active';
    final l10n = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return _StatusPill(
      label: active ? l10n?.active ?? 'Active' : l10n?.inactive ?? 'Inactive',
      color: active
          ? (dark ? Colors.green.shade300 : AppColors.successColor)
          : Theme.of(context).colorScheme.onSurfaceVariant,
      icon: active ? Icons.circle : Icons.circle_outlined,
    );
  }
}

class LoginApprovalBadge extends StatelessWidget {
  final String status;
  const LoginApprovalBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    switch (status) {
      case 'pending':
        return _StatusPill(
          label: l10n?.pending ?? 'Pending',
          color: dark ? Colors.orange.shade300 : Colors.orange.shade800,
        );
      case 'approved':
        return _StatusPill(
          label: l10n?.approved ?? 'Approved',
          color: dark ? Colors.blue.shade300 : AppColors.primaryColor,
        );
      case 'disapproved':
        return _StatusPill(
          label: l10n?.approvalDisapproved ?? 'Disapproved',
          color: dark ? Colors.red.shade300 : Colors.red.shade700,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const _StatusPill({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 8, color: color),
          const SizedBox(width: 5),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    ),
  );
}

String loginApprovalMessage(BuildContext context, LoginApprovalResult result) {
  final l10n = AppLocalizations.of(context);
  if (result.loginApprovalStatus == 'disapproved') {
    return l10n?.accessRevoked ?? 'Access revoked';
  }
  final until = result.loginApprovedUntil;
  if (until == null) return l10n?.loginApproved ?? 'Login approved';
  final time = DateFormat('dd MMM, hh:mm a').format(until.toLocal());
  return l10n?.riderApprovedUntil(time) ?? 'Login approved until $time';
}

String systemUserErrorMessage(BuildContext context, String message) {
  final l10n = AppLocalizations.of(context);
  if (message == 'Something went wrong') {
    return l10n?.somethingWentWrong ?? 'Something went wrong';
  }
  if (message == 'System user details are unavailable.') {
    return l10n?.systemUserDetailsUnavailable ??
        'System user details are unavailable.';
  }
  return message;
}
