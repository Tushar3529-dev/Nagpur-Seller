import 'package:flutter/material.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import '../model/dispatch_model.dart';

class DispatchStatusBadge extends StatelessWidget {
  final DispatchOrder order;
  const DispatchStatusBadge({super.key, required this.order});
  static Color color(DispatchStatus status) => switch (status) {
    DispatchStatus.noNearbyRiders => Colors.red,
    DispatchStatus.awaitingRiderAcceptance => Colors.orange,
    DispatchStatus.riderAssigned => Colors.green,
    DispatchStatus.sellerSelfDelivery => AppColors.primaryColor,
    _ => Colors.grey,
  };
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = switch (order.status) {
      DispatchStatus.noNearbyRiders =>
        l10n?.dispatchStatusNoNearbyRiders ?? 'No nearby riders',
      DispatchStatus.waitingForDispatch =>
        l10n?.dispatchStatusWaitingForDispatch ?? 'Waiting for dispatch',
      DispatchStatus.awaitingRiderAcceptance =>
        l10n?.dispatchStatusAwaitingRider ?? 'Awaiting rider',
      DispatchStatus.riderAssigned =>
        l10n?.dispatchStatusRiderAssigned ?? 'Rider assigned',
      DispatchStatus.sellerSelfDelivery =>
        l10n?.dispatchStatusSelfDelivery ?? 'Self delivery',
      DispatchStatus.unknown => humaniseDispatchValue(order.rawStatus),
    };
    final tint = color(order.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: tint,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
