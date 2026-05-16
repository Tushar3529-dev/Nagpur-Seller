import 'package:flutter/material.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';

class DemoGuard {
  /// Checks if the app is in demo mode.
  /// If in demo mode, shows a snackbar and returns false.
  /// If not in demo mode, returns true.
  static bool shouldProceed(BuildContext context) {
    if (HiveStorage.demoMode) {
      showCustomSnackbar(
        context: context,
        message: HiveStorage.sellerDemoModeMessage,
        backgroundColor: AppColors.primaryColor,
        isError: true, // Shows error icon, but blue background
      );
      return false;
    }
    return true;
  }
}
