import 'package:flutter/material.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import '../model/dispatch_model.dart';

class RiderAvailabilityTile extends StatelessWidget {
  final AvailableRider rider;
  const RiderAvailabilityTile({super.key, required this.rider});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = rider.isAvailableInRadius
        ? l10n?.dispatchRiderAvailable ?? 'Available'
        : switch (rider.unavailableReason) {
            RiderUnavailableReason.inactive =>
              l10n?.dispatchReasonInactive ?? 'Offline',
            RiderUnavailableReason.notVerified =>
              l10n?.dispatchReasonNotVerified ?? 'Not verified',
            RiderUnavailableReason.noFcmToken =>
              l10n?.dispatchReasonNoFcmToken ?? 'Notifications not set up',
            RiderUnavailableReason.locationStale =>
              l10n?.dispatchReasonLocationStale ??
                  'Location not updated recently',
            RiderUnavailableReason.noPickupStore =>
              l10n?.dispatchReasonNoPickupStore ?? 'No pickup store',
            RiderUnavailableReason.outsidePickupRadius =>
              l10n?.dispatchReasonOutsideRadius ?? 'Too far from store',
            RiderUnavailableReason.pendingOffer =>
              l10n?.dispatchReasonPendingOffer ?? 'Has a pending offer',
            RiderUnavailableReason.activeDelivery =>
              l10n?.dispatchReasonActiveDelivery ?? 'On a delivery',
            _ => humaniseDispatchValue(rider.rawUnavailableReason ?? ''),
          };
    final color = rider.isAvailableInRadius ? Colors.green : Colors.grey;
    final seconds = rider.locationAgeSeconds;
    final age = seconds == null
        ? null
        : seconds >= 60
        ? l10n?.dispatchAgeMinutes(seconds ~/ 60) ?? '${seconds ~/ 60}m ago'
        : l10n?.dispatchAgeSeconds(seconds) ?? '${seconds}s ago';
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: UIUtils.gapSM(context.screenType),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rider.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (rider.deliveryZone != null) Text(rider.deliveryZone!),
          if (label.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  label,
                  style: TextStyle(color: color, fontSize: 12),
                ),
              ),
            ),
          if (rider.nearestPickupDistanceM != null)
            Text(
              l10n?.dispatchDistanceFromStore(rider.nearestPickupDistanceM!) ??
                  '${rider.nearestPickupDistanceM} m from store',
            ),
          if (age != null)
            Text(
              l10n?.dispatchLocationAge(age) ?? 'Location $age',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
