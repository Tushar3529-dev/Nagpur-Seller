import 'package:flutter/material.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/screen/more_page/view/delivery_boys/model/delivery_boy_model.dart';

class RiderStatusBadge extends StatelessWidget {
  final RiderStatus status;
  const RiderStatusBadge({super.key, required this.status});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final active = status == RiderStatus.active;
    final color = active
        ? Colors.green
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        active
            ? l10n?.riderActive ?? 'ACTIVE'
            : l10n?.riderInactive ?? 'INACTIVE',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
