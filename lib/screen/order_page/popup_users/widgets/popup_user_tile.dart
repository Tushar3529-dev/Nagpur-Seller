import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/screen/order_page/dispatch/model/dispatch_model.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import '../model/popup_users_model.dart';

/// One system user on the popup availability dashboard.
class PopupUserTile extends StatelessWidget {
  final PopupUser user;
  final int pickupRadiusMeters;

  const PopupUserTile({
    super.key,
    required this.user,
    this.pickupRadiusMeters = 200,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = TextStyle(color: theme.colorScheme.onSurfaceVariant);
    final (label, color) = _status(l10n);
    final offer = user.currentOffer;
    final store = user.nearestStore;
    final lastSeen = user.lastSeenAt;
    final contact = [?user.mobile, ?user.email].join(' · ');
    return Card(
      margin: EdgeInsets.only(bottom: UIUtils.gapSM(context.screenType)),
      child: Padding(
        padding: EdgeInsets.all(UIUtils.gapMD(context.screenType)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (user.roles.isNotEmpty)
                        Text(user.roles.join(', '), style: muted),
                    ],
                  ),
                ),
                _Badge(label: label, color: color),
              ],
            ),
            if (contact.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(contact, style: muted),
              ),
            const SizedBox(height: 8),
            if (offer != null && offer.label.isNotEmpty)
              _Line(
                icon: Icons.receipt_long_outlined,
                text:
                    l10n?.popupUsersCurrentOrder(offer.label) ??
                    'Current order ${offer.label}',
              ),
            if (store != null)
              _Line(
                icon: Icons.storefront_outlined,
                text: store.distanceM == null
                    ? store.name
                    : l10n?.popupUsersNearestStore(
                            store.name,
                            store.distanceM!,
                          ) ??
                          '${store.name} · ${store.distanceM} m',
                color:
                    store.distanceM != null &&
                        store.distanceM! > pickupRadiusMeters
                    ? Colors.orange
                    : null,
              ),
            _Line(
              icon: user.locationFresh
                  ? Icons.my_location
                  : Icons.location_disabled_outlined,
              text: lastSeen == null
                  ? l10n?.popupUsersNoLocation ?? 'No location reported'
                  : l10n?.dispatchLocationAge(_age(l10n, lastSeen)) ??
                        'Location ${_age(l10n, lastSeen)}',
              color: user.locationFresh ? null : Colors.orange,
            ),
            _Line(
              icon: Icons.verified_user_outlined,
              text: _loginText(l10n),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _Check(
                  ok: user.systemUserStatus == 'active',
                  label: l10n?.popupUsersMembership ?? 'Membership',
                ),
                _Check(
                  ok: user.hasOrderPopupPermission,
                  label: l10n?.popupUsersPopupPermission ?? 'Popup permission',
                ),
                _Check(
                  ok: user.popupPresenceActive,
                  label: l10n?.popupUsersAlertsOn ?? 'Order alerts on',
                ),
                _Check(
                  ok: user.hasFcmToken,
                  label: l10n?.popupUsersPushReady ?? 'Push notifications',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  (String, Color) _status(AppLocalizations? l10n) {
    if (user.isEligible) {
      return (l10n?.popupUsersEligibleBadge ?? 'Can receive orders', Colors.green);
    }
    final reason = switch (user.ineligibleReason) {
      PopupIneligibleReason.accountInactive =>
        l10n?.popupReasonAccountInactive ?? 'Account inactive',
      PopupIneligibleReason.systemUserInactive =>
        l10n?.popupReasonSystemUserInactive ?? 'Membership inactive',
      PopupIneligibleReason.loginNotApproved =>
        l10n?.popupReasonLoginNotApproved ?? 'Login not approved or expired',
      PopupIneligibleReason.permissionMissing =>
        l10n?.popupReasonPermissionMissing ?? 'No order popup permission',
      PopupIneligibleReason.presenceInactive =>
        l10n?.popupReasonPresenceInactive ?? 'Order alerts off',
      PopupIneligibleReason.locationStale =>
        l10n?.popupReasonLocationStale ?? 'Location not updated recently',
      PopupIneligibleReason.locationUnavailable =>
        l10n?.popupReasonLocationUnavailable ??
            'Location or store unavailable',
      PopupIneligibleReason.outsideRadius =>
        l10n?.popupReasonOutsideRadius(pickupRadiusMeters) ??
            'More than $pickupRadiusMeters m from a store',
      PopupIneligibleReason.orderInProgress =>
        l10n?.popupReasonOrderInProgress ?? 'Handling an order',
      null => humaniseDispatchValue(user.rawIneligibleReason ?? ''),
    };
    final color = user.ineligibleReason == PopupIneligibleReason.orderInProgress
        ? Colors.blue
        : user.isActive
        ? Colors.orange
        : Colors.grey;
    return (reason.isEmpty ? (l10n?.popupUsersInactive ?? 'Inactive') : reason, color);
  }

  String _loginText(AppLocalizations? l10n) {
    final until = user.loginApprovedUntil;
    if (user.loginApprovalStatus == 'approved' && until != null) {
      final date = DateFormat('d MMM, HH:mm').format(until);
      return l10n?.popupUsersLoginUntil(date) ?? 'Login approved until $date';
    }
    final status = humaniseDispatchValue(user.loginApprovalStatus ?? '');
    return status.isEmpty
        ? l10n?.popupUsersLoginUnknown ?? 'Login approval unknown'
        : l10n?.popupUsersLoginStatus(status) ?? 'Login $status';
  }

  static String _age(AppLocalizations? l10n, DateTime at) {
    final seconds = DateTime.now().difference(at).inSeconds.clamp(0, 1 << 31);
    if (seconds >= 3600) {
      return DateFormat('d MMM, HH:mm').format(at);
    }
    return seconds >= 60
        ? l10n?.dispatchAgeMinutes(seconds ~/ 60) ?? '${seconds ~/ 60}m ago'
        : l10n?.dispatchAgeSeconds(seconds) ?? '${seconds}s ago';
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 170),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      textAlign: TextAlign.end,
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );
}

class _Line extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  const _Line({required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final tint = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: tint),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, style: TextStyle(color: color)),
          ),
        ],
      ),
    );
  }
}

class _Check extends StatelessWidget {
  final bool ok;
  final String label;
  const _Check({required this.ok, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = ok ? Colors.green : Colors.grey;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          ok ? Icons.check_circle : Icons.cancel_outlined,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
