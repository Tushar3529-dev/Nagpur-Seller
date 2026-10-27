import 'package:flutter/material.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import '../model/dispatch_model.dart';
import '../cubit/dispatch_state.dart';

class DispatchSummaryRow extends StatelessWidget {
  final DispatchSummary summary;
  final ValueChanged<DispatchFilter> onFilter;
  const DispatchSummaryRow({
    super.key,
    required this.summary,
    required this.onFilter,
  });
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: DispatchCountTile(
            label: l10n?.dispatchReady ?? 'Ready',
            count: summary.readyOrders,
            onTap: () => onFilter(DispatchFilter.all),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DispatchCountTile(
            label: l10n?.dispatchNoRider ?? 'No rider',
            count: summary.noNearbyRiders,
            color: summary.hasAlert ? Colors.red : null,
            onTap: () => onFilter(DispatchFilter.needsAction),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DispatchCountTile(
            label: l10n?.dispatchAssigned ?? 'Assigned',
            count: summary.assignedOrders,
            onTap: () => onFilter(DispatchFilter.assigned),
          ),
        ),
      ],
    );
  }
}

class DispatchCountTile extends StatelessWidget {
  final String label;
  final int count;
  final Color? color;
  final VoidCallback? onTap;
  const DispatchCountTile({
    super.key,
    required this.label,
    required this.count,
    this.color,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final tint = color ?? AppColors.primaryColor;
    return Material(
      color: tint.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(UIUtils.radiusMD(context.screenType)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(UIUtils.gapSM(context.screenType)),
          child: Column(
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontSize: UIUtils.sectionTitle(context.screenType),
                  color: tint,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: UIUtils.caption(context.screenType)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
