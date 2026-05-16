import 'package:flutter/material.dart';

class SubscriptionUtils {
  /// Calculates the number of days left until the given [expiryDate].
  static int getDaysLeft(DateTime expiryDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return expiry.difference(today).inDays;
  }

  /// Calculates the precise duration remaining until expiry.
  static Duration getRemainingDuration(DateTime expiryDate) {
    final now = DateTime.now();
    return expiryDate.difference(now);
  }

  /// Determines the background color of the reminder widget based on days left.
  static Color getReminderColor(int daysLeft, {Duration? remaining}) {
    if (remaining != null && remaining.inHours < 24) {
      return Colors.red;
    }
    if (daysLeft <= 1) {
      return Colors.red;
    } else if (daysLeft <= 3) {
      return Colors.orange;
    } else {
      return Colors.blue;
    }
  }

  /// Checks if the reminder should be shown based on the remaining duration.
  static bool shouldShowReminder(Duration remaining) {
    // Show when 7 days or less remaining, but not if already expired
    return remaining.inSeconds > 0 && remaining.inDays <= 7;
  }
}
