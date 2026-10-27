import 'package:flutter/material.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/service/popup_presence_service.dart';
import 'package:hyper_local_seller/utils/permission_checker.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';

/// Order alerts switch with the location status behind it. Nearby orders
/// are only offered while this device reports a fresh location, so a
/// problem (location off, permission denied) is spelled out with a fix.
class OrderAlertsBanner extends StatelessWidget {
  const OrderAlertsBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!PermissionChecker.canShowOrderPopup) return const SizedBox.shrink();
    final presence = PopupPresenceService();
    return ValueListenableBuilder<PopupPresenceStatus>(
      valueListenable: presence.status,
      builder: (context, status, _) {
        final l10n = AppLocalizations.of(context);
        final enabled = HiveStorage.orderAlertsEnabled;
        final (message, color, action) = switch (status) {
          PopupPresenceStatus.active when presence.isOwnerMode => (
            l10n?.orderAlertsOwnerActive ??
                'On · you get orders no nearby staff member can take',
            Colors.green,
            null,
          ),
          PopupPresenceStatus.active => (
            l10n?.orderAlertsActive ?? 'On · nearby orders can reach you',
            Colors.green,
            null,
          ),
          PopupPresenceStatus.locating => (
            l10n?.orderAlertsLocating ?? 'Getting your location…',
            Colors.blue,
            null,
          ),
          PopupPresenceStatus.offline => (
            l10n?.orderAlertsOffline ??
                "Couldn't update your location. Retrying…",
            Colors.orange,
            null,
          ),
          PopupPresenceStatus.serviceDisabled => (
            l10n?.orderAlertsServiceDisabled ??
                'Location is off. Turn it on to receive nearby orders.',
            Colors.red,
            l10n?.orderAlertsTurnOnLocation ?? 'Turn on',
          ),
          PopupPresenceStatus.permissionDenied => (
            l10n?.orderAlertsPermissionDenied ??
                'Allow location access to receive nearby orders.',
            Colors.red,
            l10n?.orderAlertsAllow ?? 'Allow',
          ),
          PopupPresenceStatus.permissionDeniedForever => (
            l10n?.orderAlertsPermissionDenied ??
                'Allow location access to receive nearby orders.',
            Colors.red,
            l10n?.orderAlertsOpenSettings ?? 'Settings',
          ),
          PopupPresenceStatus.disabledByUser ||
          PopupPresenceStatus.off => (
            l10n?.orderAlertsOff ?? "Off · you won't receive new orders",
            Colors.grey,
            null,
          ),
        };
        return Container(
          margin: EdgeInsets.symmetric(
            horizontal: UIUtils.gapMD(context.screenType),
            vertical: 4,
          ),
          padding: const EdgeInsets.only(left: 12, right: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(
              UIUtils.radiusMD(context.screenType),
            ),
          ),
          child: Row(
            children: [
              Icon(
                enabled ? Icons.notifications_active : Icons.notifications_off,
                size: 20,
                color: color,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.orderAlertsTitle ?? 'Order alerts',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: UIUtils.caption(context.screenType),
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (enabled && action != null)
                TextButton(
                  onPressed: presence.enableLocation,
                  child: Text(action),
                ),
              Switch.adaptive(
                value: enabled,
                onChanged: presence.setEnabled,
              ),
            ],
          ),
        );
      },
    );
  }
}
