import 'package:flutter/material.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/config/constant.dart';
import 'package:hyper_local_seller/screen/auth/bloc/auth/auth_state.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_buttons.dart';

/// Shown in place of the login form while a system user's login is waiting
/// for the seller's approval. [onCheckApproval] retries the same login request.
class LoginApprovalPendingView extends StatelessWidget {
  final AuthApprovalPending state;
  final bool isChecking;
  final VoidCallback onCheckApproval;
  final VoidCallback onBackToLogin;

  const LoginApprovalPendingView({
    super.key,
    required this.state,
    required this.isChecking,
    required this.onCheckApproval,
    required this.onBackToLogin,
  });

  @override
  Widget build(BuildContext context) {
    final screenType = context.screenType;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fontColor = isDark
        ? AppColors.darkFontColor
        : AppColors.lightFontColor;
    final timeFormat = DateFormat('dd MMM yyyy, hh:mm a');

    TextStyle style({double? size, FontWeight? weight, Color? color}) =>
        TextStyle(
          fontFamily: AppConstants.fontFamily,
          fontSize: size ?? UIUtils.body(screenType),
          fontWeight: weight,
          color: color ?? fontColor,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: UIUtils.gapLG(screenType)),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.hourglass_top_rounded,
            size: 44,
            color: AppColors.primaryColor,
          ),
        ),
        SizedBox(height: UIUtils.gapLG(screenType)),
        Text(
          'Waiting for seller approval',
          textAlign: TextAlign.center,
          style: style(size: 22, weight: UIUtils.bold),
        ),
        SizedBox(height: UIUtils.gapSM(screenType)),
        Text(
          state.message,
          textAlign: TextAlign.center,
          style: style(color: Colors.grey[600]),
        ),
        SizedBox(height: UIUtils.gapLG(screenType)),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.mainDarkContainerBgColor
                : AppColors.mainLightContainerBgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.lightOutline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow(Icons.person_outline, state.email, style),
              if (state.requestedAt != null) ...[
                const SizedBox(height: 8),
                _infoRow(
                  Icons.schedule,
                  'Requested ${timeFormat.format(state.requestedAt!)}',
                  style,
                ),
              ],
              const SizedBox(height: 8),
              _infoRow(
                Icons.refresh,
                'Last checked ${DateFormat('hh:mm:ss a').format(state.checkedAt)}',
                style,
              ),
            ],
          ),
        ),
        SizedBox(height: UIUtils.gapMD(screenType)),
        Text(
          AppLocalizations.of(context)?.askSellerApproveLogin ?? 'Ask your seller to approve this login. Your seller chooses how long access lasts.',
          textAlign: TextAlign.center,
          style: style(size: UIUtils.body(screenType) - 1, color: Colors.grey),
        ),
        SizedBox(height: UIUtils.gapXL(screenType)),
        PrimaryButton(
          text: 'Check approval',
          icon: Icons.refresh,
          backgroundColor: AppColors.primaryColor,
          onPressed: isChecking ? null : onCheckApproval,
        ),
        SizedBox(height: UIUtils.gapSM(screenType)),
        TextButton(
          onPressed: isChecking ? null : onBackToLogin,
          child: Text(
            'Back to login',
            style: style(
              color: AppColors.primaryColor,
              weight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(
    IconData icon,
    String text,
    TextStyle Function({double? size, FontWeight? weight, Color? color}) style,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: style())),
      ],
    );
  }
}
