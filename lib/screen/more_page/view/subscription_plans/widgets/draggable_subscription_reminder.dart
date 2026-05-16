import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/service/subscription_reminder_service.dart';
import 'package:hyper_local_seller/utils/responsive.dart';
import 'package:hyper_local_seller/utils/subscription_utils.dart';

class DraggableSubscriptionReminder extends StatefulWidget {
  final int daysLeft;
  final Duration remainingDuration;
  final bool isDismissable;
  final VoidCallback onTap;
  final Function(Offset offset, BuildContext context) onDragUpdate;
  final Function(Offset offset, BuildContext context) onDragEnd;
  final VoidCallback onDragStart;

  const DraggableSubscriptionReminder({
    super.key,
    required this.daysLeft,
    required this.remainingDuration,
    required this.isDismissable,
    required this.onTap,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onDragStart,
  });

  @override
  State<DraggableSubscriptionReminder> createState() =>
      _DraggableSubscriptionReminderState();
}

class _DraggableSubscriptionReminderState
    extends State<DraggableSubscriptionReminder>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isDragging = false;
  late Duration _currentRemaining;
  Timer? _timer;

  /// Resolve badge color based on days remaining
  Color get _badgeColor {
    return SubscriptionUtils.getReminderColor(
      widget.daysLeft,
      remaining: _currentRemaining,
    );
  }

  /// Resolve icon based on severity
  IconData get _badgeIcon {
    if (_currentRemaining.inHours < 24) return Icons.timer_outlined;
    if (widget.daysLeft <= 3) return Icons.error_outline_rounded;
    return Icons.warning_amber_rounded;
  }

  String _formatDuration(Duration duration) {
    if (duration.inSeconds <= 0) return "00:00:00";
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return "$hours:$minutes:$seconds";
  }

  @override
  void initState() {
    super.initState();
    _currentRemaining = widget.remainingDuration;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (_currentRemaining.inHours < 24) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentRemaining -= const Duration(seconds: 1);
        if (_currentRemaining.inSeconds <= 0) {
          _timer?.cancel();
          // Call service to clear subscription
          SubscriptionReminderService().checkAndShowReminder(
            context,
            DateTime.now().subtract(const Duration(seconds: 1)),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final l10n = AppLocalizations.of(context);

    // Responsive sizing
    final double horizontalPad = Responsive.isMobile ? 16.0 : 20.0;
    final double verticalPad = Responsive.isMobile ? 10.0 : 14.0;
    final double iconSize = Responsive.isMobile ? 20.0 : 24.0;
    final double fontSize = Responsive.isMobile ? 14.0 : 16.0;
    final double spacing = Responsive.isMobile ? 8.0 : 10.0;

    return GestureDetector(
      onTapDown: (_) {
        if (!_isDragging) _animationController.forward();
      },
      onTapUp: (_) {
        if (!_isDragging) {
          _animationController.reverse();
          widget.onTap();
        }
      },
      onTapCancel: () {
        if (!_isDragging) _animationController.reverse();
      },
      onPanStart: (details) {
        setState(() => _isDragging = true);
        _animationController.forward();
        widget.onDragStart();
      },
      onPanUpdate: (details) {
        widget.onDragUpdate(details.delta, context);
      },
      onPanEnd: (details) {
        setState(() => _isDragging = false);
        _animationController.reverse();
        final renderBox = context.findRenderObject() as RenderBox?;
        final position = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
        widget.onDragEnd(position, context);
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnimation.value, child: child),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPad,
            vertical: verticalPad,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: _badgeColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              // Premium glow effect
              BoxShadow(
                color: _badgeColor.withValues(alpha: 0.25),
                blurRadius: 20,
                spreadRadius: 4,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
            gradient: LinearGradient(
              colors: [Colors.white, _badgeColor.withValues(alpha: 0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _badgeColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(_badgeIcon, color: _badgeColor, size: iconSize - 2),
              ),
              SizedBox(width: spacing),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentRemaining.inHours < 24
                        ? 'Expires in'
                        : (l10n?.subscriptionReminder ?? 'Expiring Soon'),
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      letterSpacing: 0.2,
                    ),
                  ),
                  Text(
                    _currentRemaining.inHours < 24
                        ? _formatDuration(_currentRemaining)
                        : (l10n?.daysLeft(widget.daysLeft) ??
                            '${widget.daysLeft} Days Left'),
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                      fontSize: fontSize,
                      letterSpacing: -0.2,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
