import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:hyper_local_seller/service/demo_guard.dart';
import 'package:hyper_local_seller/utils/image_path.dart';
import 'package:hyper_local_seller/widgets/custom/custom_alert_dialog.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';

class OrderDialogs {
  static void showAcceptDialog(
    BuildContext context,
    Future<void> Function() onConfirm,
  ) {
    showAppAlertDialog(
      context: context,
      title: AppLocalizations.of(context)!.acceptOrderTitle,
      message: AppLocalizations.of(context)!.acceptOrderConfirmation,
      svgPath: ImagesPath.acceptSvg,
      size: 24,
      padding: 24,
      iconColor: Colors.green,
      confirmColor: Colors.green,
      confirmText: AppLocalizations.of(context)!.accept,
      onConfirm: () async {
        await _handleAction(
          context,
          onConfirm,
          AppLocalizations.of(context)!.orderAccepted,
        );
      },
    );
  }

  static void showRejectDialog(
    BuildContext context,
    Future<void> Function() onConfirm,
  ) {
    showAppAlertDialog(
      context: context,
      title: AppLocalizations.of(context)!.rejectOrderTitle,
      message: AppLocalizations.of(context)!.rejectOrderConfirmation,
      svgPath: ImagesPath.rejectSvg,
      iconColor: Colors.red,
      confirmColor: Colors.red,
      confirmText: AppLocalizations.of(context)!.reject,
      onConfirm: () async {
        await _handleAction(
          context,
          onConfirm,
          AppLocalizations.of(context)!.orderRejected,
        );
      },
    );
  }

  static void showPreparedDialog(
    BuildContext context,
    Future<void> Function() onConfirm,
  ) {
    showAppAlertDialog(
      context: context,
      title: AppLocalizations.of(context)!.markAsPreparedTitle,
      message: AppLocalizations.of(context)!.markAsPreparedConfirmation,
      svgPath: ImagesPath.markAsPrepareSvg,
      iconColor: Colors.blue,
      confirmText: AppLocalizations.of(context)!.markAsPreparedTitle,
      size: 36,
      padding: 12,
      onConfirm: () async {
        await _handleAction(
          context,
          onConfirm,
          AppLocalizations.of(context)!.orderMarkedAsPrepared,
        );
      },
    );
  }

  /// Runs [action] behind a blocking spinner.
  static Future<T> withLoading<T>(
    BuildContext context,
    Future<T> Function() action,
  ) async {
    _showLoading(context);
    try {
      return await action();
    } finally {
      _hideLoading(context);
    }
  }

  /// Why "Process order" didn't open the order (e.g. another user accepted
  /// it first). The list is refreshed behind it.
  static Future<void> showProcessError(BuildContext context, String message) {
    final l10n = AppLocalizations.of(context);
    return showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.info_outline, color: Colors.orange, size: 32),
        title: Text(l10n?.cantProcessOrderTitle ?? "Can't process this order"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n?.processOrderOk ?? 'OK'),
          ),
        ],
      ),
    );
  }

  static Future<void> _handleAction(
    BuildContext context,
    Future<void> Function() onConfirm,
    String message,
  ) async {
    // Check Guard first
    final bool allowed = DemoGuard.shouldProceed(context);
    if (!allowed) {
      // If not allowed, DemoGuard already showed a snackbar.
      // We just return immediately.
      return;
    }

    _showLoading(context);
    try {
      await onConfirm();
      if (context.mounted) {
        _hideLoading(context);
        showCustomSnackbar(context: context, message: message);
      }
    } catch (e) {
      if (context.mounted) {
        _hideLoading(context);
        showCustomSnackbar(
          context: context,
          message: AppLocalizations.of(context)?.errorWithDetail(
                e.toString().replaceAll("Exception: ", ""),
              ) ??
              "Error: ${e.toString().replaceAll("Exception: ", "")}",
          isError: true,
        );
      }
    }
  }

  static void _showLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }

  static void _hideLoading(BuildContext context) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}
