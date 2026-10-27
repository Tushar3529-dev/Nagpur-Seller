import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/screen/more_page/view/delivery_boys/bloc/delivery_boy_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/delivery_boys/model/delivery_boy_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/delivery_boys/widgets/login_duration_sheet.dart';
import 'package:hyper_local_seller/screen/more_page/view/delivery_boys/widgets/rider_card.dart';
import 'package:hyper_local_seller/service/demo_guard.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_alert_dialog.dart';

enum RiderAction { approve, reject, qr, edit, delete }

class RiderActionsSheet extends StatelessWidget {
  final DeliveryBoy rider;
  final String? zoneName;
  const RiderActionsSheet({super.key, required this.rider, this.zoneName});

  static Future<void> approve(BuildContext context, DeliveryBoy rider) async {
    if (!DeliveryBoyBloc.canManage) return;
    final selection = await LoginDurationSheet.show(context);
    if (!context.mounted ||
        selection == null ||
        !DeliveryBoyBloc.canManage ||
        !DemoGuard.shouldProceed(context)) {
      return;
    }
    context.read<DeliveryBoyBloc>().add(
      ApproveLogin(rider.id, selection.hours),
    );
  }

  static Future<void> reject(BuildContext context, DeliveryBoy rider) async {
    if (!DeliveryBoyBloc.canManage) return;
    final l10n = AppLocalizations.of(context);
    await showAppAlertDialog(
      context: context,
      title: l10n?.riderEndSession ?? 'Disapprove / end session',
      message:
          l10n?.riderRejectConfirmation ??
          "This disapproves password login and ends the rider's current session. The QR stays valid until it expires or you regenerate it.",
      confirmText: l10n?.riderDisapprove ?? 'Disapprove',
      isDestructive: true,
      onConfirm: () {
        if (context.mounted &&
            DeliveryBoyBloc.canManage &&
            DemoGuard.shouldProceed(context)) {
          context.read<DeliveryBoyBloc>().add(RejectLogin(rider.id));
        }
      },
    );
  }

  static Future<void> delete(BuildContext context, DeliveryBoy rider) async {
    if (!DeliveryBoyBloc.canManage) return;
    final l10n = AppLocalizations.of(context);
    await showAppAlertDialog(
      context: context,
      title: l10n?.riderDelete ?? 'Delete rider',
      message:
          l10n?.riderDeleteConfirmation ??
          'Delete this rider and end their sessions?',
      confirmText: l10n?.delete ?? 'Delete',
      isDestructive: true,
      onConfirm: () {
        if (context.mounted &&
            DeliveryBoyBloc.canManage &&
            DemoGuard.shouldProceed(context)) {
          context.read<DeliveryBoyBloc>().add(DeleteRider(rider.id));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: UIUtils.pagePadding(context.screenType),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              rider.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (zoneName != null) Text(zoneName!),
            Text(riderApprovalText(context, rider)),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: Text(
                rider.isApprovalLive
                    ? l10n?.riderExtendApproval ?? 'Extend approval'
                    : l10n?.riderApprovePassword ?? 'Approve password login',
              ),
              onTap: () => Navigator.pop(context, RiderAction.approve),
            ),
            if (rider.loginApproval != RiderLoginApproval.disapproved ||
                rider.isActive)
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: Text(
                  l10n?.riderEndSession ?? 'Disapprove / end session',
                ),
                onTap: () => Navigator.pop(context, RiderAction.reject),
              ),
            ListTile(
              leading: const Icon(Icons.qr_code),
              enabled: rider.isVerified,
              title: Text(l10n?.riderShowQr ?? 'Show login QR'),
              subtitle: rider.isVerified
                  ? null
                  : Text(
                      l10n?.riderQrAfterVerification ??
                          'Available after platform verification',
                    ),
              onTap: () => Navigator.pop(context, RiderAction.qr),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(l10n?.riderEdit ?? 'Edit rider'),
              onTap: () => Navigator.pop(context, RiderAction.edit),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: Text(l10n?.riderDelete ?? 'Delete rider'),
              onTap: () => Navigator.pop(context, RiderAction.delete),
            ),
          ],
        ),
      ),
    );
  }
}
