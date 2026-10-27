import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/app_permissions.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/service/demo_guard.dart';
import 'package:hyper_local_seller/utils/permission_checker.dart';
import 'package:hyper_local_seller/widgets/custom/custom_alert_dialog.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';
import '../cubit/dispatch_cubit.dart';
import '../model/dispatch_model.dart';

// Match OrderDialogs' confirmation convention with the shared alert dialog.
class SelfDeliverSheet {
  static Future<void> show(BuildContext context, DispatchOrder order) async {
    if (!PermissionChecker.hasPermission(AppPermissions.orderUpdateStatus) ||
        !order.status.canSelfDeliver) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final name =
        order.deliveryBoyName ??
        (order.deliveryBoyId == null
            ? l10n?.dispatchRiderFallback ?? 'Rider'
            : l10n?.dispatchRiderId(order.deliveryBoyId!) ??
                  'rider #${order.deliveryBoyId}');
    final pending = order.status == DispatchStatus.awaitingRiderAcceptance;
    final info = pending
        ? l10n?.dispatchSelfDeliverPendingOffer(name) ??
              "$name has a pending offer for this order. It will be cancelled and you'll be responsible for delivery."
        : l10n?.dispatchSelfDeliverInfo ??
              "This order will stop being offered to riders and you'll be responsible for delivery.";
    await showAppAlertDialog(
      context: context,
      title: l10n?.dispatchSelfDeliverTitle ?? 'Deliver this order yourself?',
      message:
          '#${order.orderNumber} · ${order.bagBarcode}\n\n$info\n\n${l10n?.dispatchSelfDeliveryInfo ?? "You're responsible for delivering this order. Completing it in the app isn't available yet."}',
      icon: pending
          ? Icons.warning_amber_rounded
          : Icons.delivery_dining_outlined,
      iconColor: pending ? Colors.orange : null,
      confirmText: l10n?.confirm ?? 'Confirm',
      cancelText: l10n?.cancel ?? 'Cancel',
      onConfirm: () async {
        if (!context.mounted ||
            !PermissionChecker.hasPermission(
              AppPermissions.orderUpdateStatus,
            ) ||
            !DemoGuard.shouldProceed(context)) {
          return;
        }
        final result = await context.read<DispatchCubit>().selfDeliver(
          order.orderId,
        );
        if (!context.mounted || result.isIgnored) return;
        showCustomSnackbar(
          context: context,
          message: result.message.isEmpty
              ? l10n?.somethingWentWrong ?? 'Something went wrong'
              : result.message,
          isError: !result.isSuccess,
        );
      },
    );
  }
}
