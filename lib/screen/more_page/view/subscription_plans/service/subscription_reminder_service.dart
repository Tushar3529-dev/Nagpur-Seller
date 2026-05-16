import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hyper_local_seller/config/global_keys.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/widgets/draggable_subscription_reminder.dart';
import 'package:hyper_local_seller/utils/subscription_utils.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/widgets/dismiss_zone_widget.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local_seller/router/app_routes.dart';
import 'package:intl/intl.dart';

class SubscriptionReminderService {
  static final SubscriptionReminderService _instance =
      SubscriptionReminderService._internal();

  factory SubscriptionReminderService() {
    return _instance;
  }

  SubscriptionReminderService._internal();

  OverlayEntry? _overlayEntry;
  bool _isDismissZoneVisible = false;
  bool _isHoveringDismissZone = false;
  bool _sessionDismissed = false;
  Offset _currentPosition = Offset.zero;

  // The size of the screen and the widget to calculate snapping
  Size _screenSize = Size.zero;
  final double _widgetWidth = 140.0;
  final double _widgetHeight = 50.0;

  String get _dismissDateKey {
    final uid = HiveStorage.userData?['id'] ?? 'guest';
    return 'subscription_dismiss_date_$uid';
  }

  /// Initializes the service and shows the reminder if conditions are met.
  Future<void> checkAndShowReminder(
    BuildContext context,
    DateTime expiryDate,
  ) async {
    if (HiveStorage.userToken == null || HiveStorage.userToken!.isEmpty) {
      hideReminderOverlay();
      return;
    }

    final remaining = SubscriptionUtils.getRemainingDuration(expiryDate);
    final daysLeft = SubscriptionUtils.getDaysLeft(expiryDate);

    // Rule: Once countdown is over, clear the active subscription
    if (remaining.inSeconds <= 0) {
      await HiveStorage.clearSubscriptionLimits();
      hideReminderOverlay();
      _showExpiredDialog(GlobalKeys.navigatorKey.currentContext ?? context);
      return;
    }

    if (!SubscriptionUtils.shouldShowReminder(remaining)) {
      hideReminderOverlay();
      return;
    }

    // Rules for dismissal:
    // 1. Less than 24 hr: user can't dismiss
    // 2. 2 days: dismissable but whenever app opens then it will be visible (session-based)
    // 3. 1 week: if user close the floating message it will be shown on next day (daily Hive-based)

    bool isDismissable = true;

    if (remaining.inHours < 24) {
      isDismissable = false;
    } else if (remaining.inHours < 48) {
      // Less than 2 days
      if (_sessionDismissed) return;
    } else {
      // More than 2 days, up to 1 week
      final box = await Hive.openBox('AppPrefs');
      final String? dismissDateString = box.get(_dismissDateKey);
      final today = DateTime.now();
      final todayString = '${today.year}-${today.month}-${today.day}';

      if (dismissDateString == todayString && !kDebugMode) {
        // Already dismissed today
        return;
      }
    }

    if (!context.mounted) return;
    // Capture screen size for positioning
    _screenSize = MediaQuery.of(context).size;

    // Initial position: Bottom right
    if (_overlayEntry == null) {
      _currentPosition = Offset(
        _screenSize.width - _widgetWidth - 20,
        _screenSize.height - _widgetHeight - 100,
      );
    }

    showReminderOverlay(context, daysLeft, remaining, isDismissable);
  }

  void showReminderOverlay(
    BuildContext context,
    int daysLeft,
    Duration remaining,
    bool isDismissable,
  ) {
    if (_overlayEntry != null) {
      // already showing - bit of a race condition if we update parameters,
      // so we remove and re-add or just update state if it were a proper bloc.
      // For now, let's remove and re-add to ensure fresh parameters.
      hideReminderOverlay();
    }

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // Dismiss Zone - only if dismissable
            if (isDismissable)
              DismissZoneWidget(
                isVisible: _isDismissZoneVisible,
                isHovering: _isHoveringDismissZone,
              ),

            // Draggable Reminder
            AnimatedPositioned(
              duration: _isDismissZoneVisible
                  ? const Duration(milliseconds: 0)
                  : const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              left: _currentPosition.dx,
              top: _currentPosition.dy,
              child: Material(
                color: Colors.transparent,
                child: DraggableSubscriptionReminder(
                  daysLeft: daysLeft,
                  remainingDuration: remaining,
                  isDismissable: isDismissable,
                  onTap: () => _handleTap(context),
                  onDragStart: isDismissable ? _handleDragStart : () {},
                  onDragUpdate: isDismissable
                      ? (delta, ctx) => _handleDragUpdate(delta, ctx)
                      : (delta, ctx) {},
                  onDragEnd: isDismissable
                      ? (position, ctx) => _handleDragEnd(position, ctx)
                      : (position, ctx) {},
                ),
              ),
            ),
          ],
        );
      },
    );

    final overlay =
        GlobalKeys.navigatorKey.currentState?.overlay ??
        Overlay.maybeOf(context);
    if (overlay != null) {
      overlay.insert(_overlayEntry!);
    } else {
      // In case it's called too early, retry on the next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        GlobalKeys.navigatorKey.currentState?.overlay?.insert(_overlayEntry!);
      });
    }
  }

  void hideReminderOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> dismissReminder() async {
    final box = await Hive.openBox('AppPrefs');
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';

    final endDateStr = HiveStorage.subscriptionEndDate;
    if (endDateStr.isNotEmpty) {
      final format = DateFormat('dd MMM yyyy HH:mm:ss');
      final expiryDate = format.parse(endDateStr);
      final remaining = SubscriptionUtils.getRemainingDuration(expiryDate);

      if (remaining.inHours < 48) {
        _sessionDismissed = true;
      } else {
        await box.put(_dismissDateKey, todayString);
      }
    } else {
      await box.put(_dismissDateKey, todayString);
    }

    hideReminderOverlay();
  }

  void resetSession() {
    _sessionDismissed = false;
  }


  void _showExpiredDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const _SubscriptionExpiredDialog(),
    );
  }

  void _handleTap(BuildContext context) {
    final dialogContext = GlobalKeys.navigatorKey.currentContext ?? context;

    final endDateStr = HiveStorage.subscriptionEndDate;
    final format = DateFormat('dd MMM yyyy HH:mm:ss');

    final expiryDate = format.parse(endDateStr);

    showDialog(
      context: dialogContext,
      barrierDismissible: true,
      builder: (context) => _SubscriptionReminderDialog(
        daysLeft: SubscriptionUtils.getDaysLeft(expiryDate),
        planName: HiveStorage.activePlanName,
      ),
    );
  }

  void _handleDragStart() {
    _isDismissZoneVisible = true;
    _overlayEntry?.markNeedsBuild();
  }

  void _handleDragUpdate(Offset delta, BuildContext context) {
    // Update position
    _currentPosition += delta;

    // Constrain to screen bounds during drag
    _currentPosition = Offset(
      _currentPosition.dx.clamp(0.0, _screenSize.width - _widgetWidth),
      _currentPosition.dy.clamp(0.0, _screenSize.height - _widgetHeight),
    );

    final dismissRect = Rect.fromLTWH(
      (_screenSize.width / 2) - 60,
      _screenSize.height - 120,
      120,
      120,
    );

    final widgetCenter = Offset(
      _currentPosition.dx + (_widgetWidth / 2),
      _currentPosition.dy + (_widgetHeight / 2),
    );

    final isHovering = dismissRect.contains(widgetCenter);

    if (_isHoveringDismissZone != isHovering) {
      _isHoveringDismissZone = isHovering;
    }

    _overlayEntry?.markNeedsBuild();
  }

  void _handleDragEnd(Offset position, BuildContext context) {
    _isDismissZoneVisible = false;

    if (_isHoveringDismissZone) {
      // Dropped in dismiss zone
      _isHoveringDismissZone = false;
      dismissReminder();
    } else {
      // Snap to edge
      _snapToEdge();
      _overlayEntry?.markNeedsBuild();
    }
  }

  void _snapToEdge() {
    final centerX = _currentPosition.dx + (_widgetWidth / 2);

    // Determine near left or right edge
    if (centerX < _screenSize.width / 2) {
      _currentPosition = Offset(0, _currentPosition.dy); // Snap left
    } else {
      _currentPosition = Offset(
        _screenSize.width - _widgetWidth,
        _currentPosition.dy,
      ); // Snap right
    }
  }
}

class _SubscriptionReminderDialog extends StatelessWidget {
  final int daysLeft;
  final String planName;

  const _SubscriptionReminderDialog({
    required this.daysLeft,
    this.planName = '',
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = SubscriptionUtils.getReminderColor(daysLeft);
    final l10n = AppLocalizations.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              children: [
                // Icon Stack
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.event_available_rounded,
                          color: Colors.blue,
                          size: 36,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.priority_high,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Title
                Text(
                  l10n?.subscriptionExpiring ?? 'Subscription Expiring',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                // Subtitle
                Text(
                  l10n?.subscriptionExpiringMessage ??
                      'Your subscription will expire soon.\nPlease renew to continue using seller\nservices and maintain access to your\ndashboard.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                // Info Box
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              l10n?.daysRemain.toUpperCase() ?? 'DAYS REMAINING',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.black45,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n?.daysLeft(daysLeft) ?? '$daysLeft Days',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: badgeColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        color: Colors.grey.withValues(alpha: 0.2),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              l10n?.currentPlan.toUpperCase() ?? 'CURRENT PLAN',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.black45,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              planName.isNotEmpty
                                  ? planName.toUpperCase()
                                  : (l10n?.activePlan.toUpperCase() ?? 'ACTIVE PLAN'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Renew Now Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      SubscriptionReminderService().hideReminderOverlay();
                      context.push(AppRoutes.subscriptionPlans);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n?.renewNow ?? 'Renew Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Remind Me Later Button
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blueGrey,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    l10n?.remindMeLater ?? 'Remind Me Later',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          // Footer
          // Container(
          //   width: double.infinity,
          //   padding: const EdgeInsets.symmetric(vertical: 16),
          //   decoration: BoxDecoration(
          //     color: Colors.grey.withValues(alpha: 0.04),
          //     borderRadius: const BorderRadius.only(
          //       bottomLeft: Radius.circular(24),
          //       bottomRight: Radius.circular(24),
          //     ),
          //   ),
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     children: [
          //       Icon(Icons.shield_outlined, size: 14, color: Colors.grey[600]),
          //       const SizedBox(width: 6),
          //       Text(
          //         'SECURE PAYMENT PROCESSING',
          //         style: TextStyle(
          //           fontSize: 10,
          //           fontWeight: FontWeight.w600,
          //           color: Colors.grey[600],
          //           letterSpacing: 0.5,
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }
}

class _SubscriptionExpiredDialog extends StatelessWidget {
  const _SubscriptionExpiredDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              children: [
                // Icon Stack
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.event_busy_rounded,
                          color: Colors.red,
                          size: 36,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Title
                const Text(
                  'Subscription Expired',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                // Subtitle
                const Text(
                  'Your subscription has expired.\nPlease renew to continue using seller\nservices and maintain access to your\ndashboard.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                // Renew Now Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      SubscriptionReminderService().hideReminderOverlay();
                      context.push(AppRoutes.subscriptionPlans);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n?.renewNow ?? 'Renew Now',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Remind Me Later Button
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blueGrey,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    l10n?.remindMeLater ?? 'Remind Me Later',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

