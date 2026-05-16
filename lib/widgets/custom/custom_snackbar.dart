import 'package:flutter/material.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';

void showCustomSnackbar({
  required BuildContext context,
  required String message,
  bool isError = false,
  bool isWarning = false,
  Color? backgroundColor,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final Color snackBackgroundColor =
      backgroundColor ??
      (isWarning
          ? AppColors.pendingColor
          : isError
          ? AppColors.errorColor
          : AppColors.successColor);

  IconData icon;
  if (isWarning) {
    icon = Icons.warning_amber_rounded;
  } else if (isError) {
    icon = Icons.error_outline;
  } else {
    icon = Icons.check_circle_outline;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: UIUtils.body(context.screenTypeRead),
              ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                onAction();
              },
              child: Text(
                actionLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
        ],
      ),
      backgroundColor: snackBackgroundColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      elevation: 4,
      duration: const Duration(seconds: 4),
    ),
  );
}
