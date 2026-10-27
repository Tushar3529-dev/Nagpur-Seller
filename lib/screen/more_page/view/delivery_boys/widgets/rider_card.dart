import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/screen/more_page/view/delivery_boys/model/delivery_boy_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/delivery_boys/widgets/rider_status_badge.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_loading_indicator.dart';

String riderApprovalText(BuildContext context, DeliveryBoy rider) {
  final l10n = AppLocalizations.of(context);
  if (rider.isApprovalLive) {
    final time = DateFormat('d MMM, h:mm a').format(rider.loginApprovedUntil!);
    return l10n?.riderApprovedUntil(time) ?? 'Login approved until $time';
  }
  if (rider.isApprovalExpired) {
    return l10n?.riderApprovalExpired ?? 'Approval expired';
  }
  if (rider.isLoginPending) {
    final date = rider.loginApprovalRequestedAt;
    final elapsed = date == null
        ? Duration.zero
        : DateTime.now().difference(date);
    final relative = elapsed.inDays > 0
        ? l10n?.riderDaysAgo(elapsed.inDays) ?? '${elapsed.inDays}d ago'
        : elapsed.inHours > 0
        ? l10n?.riderHoursAgo(elapsed.inHours) ?? '${elapsed.inHours}h ago'
        : elapsed.inMinutes > 0
        ? l10n?.riderMinutesAgo(elapsed.inMinutes) ??
              '${elapsed.inMinutes}m ago'
        : l10n?.riderJustNow ?? 'just now';
    return l10n?.riderLoginRequested(relative) ?? 'Login requested $relative';
  }
  return l10n?.riderLoginNotApproved ?? 'Login not approved';
}

class RiderCard extends StatelessWidget {
  final DeliveryBoy rider;
  final String? zoneName;
  final bool canManage;
  final bool showApproval;
  final bool isBusy;
  final VoidCallback? onTap;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  const RiderCard({
    super.key,
    required this.rider,
    this.zoneName,
    required this.canManage,
    this.showApproval = true,
    required this.isBusy,
    this.onTap,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screenType = context.screenType;
    final theme = Theme.of(context);
    Widget chip(String text, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: UIUtils.caption(screenType)),
      ),
    );
    return Material(
      color: theme.brightness == Brightness.dark
          ? AppColors.mainDarkContainerBgColor
          : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UIUtils.radiusMD(screenType)),
        side: BorderSide(color: AppColors.lightOutlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(UIUtils.radiusMD(screenType)),
        onTap: canManage && !isBusy ? onTap : null,
        child: Padding(
          padding: EdgeInsets.all(UIUtils.gapMD(screenType)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      rider.name,
                      style: TextStyle(
                        fontSize: UIUtils.tileTitle(screenType),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  RiderStatusBadge(status: rider.status),
                ],
              ),
              SizedBox(height: UIUtils.gapSM(screenType)),
              Text(
                [
                  rider.email,
                  if (rider.mobile.isNotEmpty) rider.mobile,
                ].join(' · '),
                style: TextStyle(
                  fontSize: UIUtils.body(screenType),
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (zoneName != null) Text(zoneName!),
              SizedBox(height: UIUtils.gapSM(screenType)),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  chip(
                    rider.isVerified
                        ? l10n?.riderVerified ?? 'Verified'
                        : l10n?.riderVerificationPending ??
                              'Verification pending',
                    rider.isVerified ? Colors.green : Colors.orange,
                  ),
                  if (showApproval)
                    chip(
                      riderApprovalText(context, rider),
                      rider.isApprovalLive
                          ? Colors.green
                          : rider.isLoginPending
                          ? Colors.orange
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
              if (!rider.isVerified)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    l10n?.riderVerificationCaption ??
                        'Platform admin must verify before login',
                    style: TextStyle(
                      fontSize: UIUtils.caption(screenType),
                      color: Colors.orange,
                    ),
                  ),
                ),
              if (isBusy)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Center(
                    child: CustomLoadingIndicator(size: 20, strokeWidth: 2),
                  ),
                )
              else if (canManage && rider.isLoginPending)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onReject,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.errorColor,
                            side: const BorderSide(color: AppColors.errorColor),
                          ),
                          child: Text(l10n?.riderDisapprove ?? 'Disapprove'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: onApprove,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                          ),
                          child: Text(l10n?.riderApprove ?? 'Approve'),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
