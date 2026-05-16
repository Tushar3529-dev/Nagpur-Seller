import 'dart:developer';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/router/app_routes.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/service/subscription_reminder_service.dart';

class SubscriptionReminderWrapper extends StatefulWidget {
  final Widget child;

  const SubscriptionReminderWrapper({super.key, required this.child});

  @override
  State<SubscriptionReminderWrapper> createState() =>
      _SubscriptionReminderWrapperState();
}

class _SubscriptionReminderWrapperState
    extends State<SubscriptionReminderWrapper>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSubscription();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkSubscription();
    }
  }

  void _checkSubscription() {
    if (!HiveStorage.isSubscriptionAvailable) {
      SubscriptionReminderService().hideReminderOverlay();
      return;
    }
    final remindTimeStr = HiveStorage.choosePlanRemindTime;

    if (remindTimeStr != null &&
        (HiveStorage.activePlanId == null || HiveStorage.activePlanId == 0) &&
        HiveStorage.pendingSubscriptionId == null) {
      final remindTime = DateTime.tryParse(remindTimeStr);
      if (remindTime != null && DateTime.now().difference(remindTime).inHours >= 4) {
        HiveStorage.setChoosePlanRemindTime(null);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          MyAppRoutes.router.push(AppRoutes.subscriptionChoosePlan);
        });
        return;
      }
    }

    final endDateStr = HiveStorage.subscriptionEndDate;
    if (endDateStr.isNotEmpty) {
      log('Checking subscription reminder for $endDateStr');
      try {
        // Example format from backend: "20 Mar 2026 17:15:09"
        final format = DateFormat('dd MMM yyyy HH:mm:ss');
        final expiryDate = format.parse(endDateStr);
        log('Parsed Expiry date: $expiryDate');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          SubscriptionReminderService().checkAndShowReminder(
            context,
            expiryDate,
          );
        });
        // SubscriptionReminderService().checkAndShowReminder(context, expiryDate);
      } catch (e) {
        log('Error parsing subscription end date: $e');
        // Fallback for ISO format just in case
        final isoDate = DateTime.tryParse(endDateStr);
        if (isoDate != null) {
          SubscriptionReminderService().checkAndShowReminder(context, isoDate);
        }
      }
    } else {
      SubscriptionReminderService().hideReminderOverlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
