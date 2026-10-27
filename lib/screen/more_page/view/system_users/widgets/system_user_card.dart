import 'package:flutter/material.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/widgets/system_user_status_badges.dart';
import 'package:hyper_local_seller/utils/time_utils.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_loading_indicator.dart';
import 'package:intl/intl.dart';

class SystemUserCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final ScreenType screenType;
  final VoidCallback? onApprove;
  final bool isProcessing;

  const SystemUserCard({
    super.key,
    required this.data,
    required this.screenType,
    this.onApprove,
    this.isProcessing = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final muted = TextStyle(
      fontSize: UIUtils.body(screenType),
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    final status = data['loginApprovalStatus'];
    final until = data['loginApprovedUntil'] as DateTime?;
    final requested = data['loginApprovalRequestedAt'] as DateTime?;
    String? extra;
    if (status == 'approved' && until != null) {
      final time = DateFormat('dd MMM, hh:mm a').format(until.toLocal());
      extra = l10n?.approvedUntil(time) ?? 'until $time';
    } else if (status == 'pending' && requested != null) {
      final ago = TimeUtils.formatTimeAgo(requested.toIso8601String(), context);
      extra = l10n?.requestedAgo(ago) ?? 'requested $ago';
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  Text(
                    data['name'] ?? '',
                    style: TextStyle(
                      fontSize: UIUtils.tileTitle(screenType),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (data['accessPanel'] != null)
                    Text('(${data['accessPanel']})', style: muted),
                ],
              ),
            ),
            SystemUserActivityBadge(data['systemUserStatus'] ?? 'inactive'),
          ],
        ),
        SizedBox(height: UIUtils.gapSM(screenType)),
        Text(
          [
            data['email'],
            data['mobile'],
          ].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
          style: muted,
        ),
        SizedBox(height: UIUtils.gapSM(screenType)),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            LoginApprovalBadge(status ?? 'not_requested'),
            if (extra != null) Text(extra, style: muted),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                TimeUtils.formatTimeAgo(data['date'] ?? '', context),
                style: muted,
              ),
            ),
            if (isProcessing)
              const Padding(
                padding: EdgeInsets.all(10),
                child: CustomLoadingIndicator(size: 18, strokeWidth: 2),
              )
            else if (status == 'pending' && onApprove != null)
              TextButton(
                onPressed: onApprove,
                child: Text(l10n?.riderApprove ?? 'Approve'),
              ),
          ],
        ),
      ],
    );
  }
}
