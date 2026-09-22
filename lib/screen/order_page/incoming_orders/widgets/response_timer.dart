import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hyper_local_seller/config/colors.dart';

/// Circular count-up timer showing how long an order has been waiting,
/// measured from the order's `created_at` so it stays correct across restarts.
///
/// The ring fills over the first [target]; after that it stays full and
/// turns red to show the order is overdue.
class ResponseTimer extends StatefulWidget {
  final DateTime? since;
  final Duration target;
  final double size;

  const ResponseTimer({
    super.key,
    required this.since,
    this.target = const Duration(seconds: 60),
    this.size = 112,
  });

  @override
  State<ResponseTimer> createState() => _ResponseTimerState();
}

class _ResponseTimerState extends State<ResponseTimer> {
  late DateTime _start;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _start = _resolveStart();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant ResponseTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.since != widget.since) _start = _resolveStart();
  }

  DateTime _resolveStart() {
    final since = widget.since?.toLocal();
    final now = DateTime.now();
    // A device clock behind the server shouldn't show a negative time.
    if (since == null || since.isAfter(now)) return now;
    return since;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final elapsed = DateTime.now().difference(_start);
    final isOverdue = elapsed >= widget.target;
    final progress = isOverdue
        ? 1.0
        : elapsed.inMilliseconds / widget.target.inMilliseconds;
    final ringColor = isOverdue ? Colors.red.shade600 : Colors.green.shade600;
    final surface = isDark
        ? AppColors.darkProductCardColor
        : AppColors.mainLightBackgroundColor;

    return Container(
      width: widget.size,
      height: widget.size,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress,
          color: ringColor,
          trackColor: isDark
              ? AppColors.darkOutline
              : AppColors.stepCurrentBgColor,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          // Scales down instead of overflowing with large system font sizes.
          child: FittedBox(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isOverdue ? 'OVERDUE' : 'WAITING',
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1,
                    fontWeight: FontWeight.w600,
                    color: isOverdue ? ringColor : theme.hintColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _format(elapsed),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: isOverdue ? ringColor : AppColors.primaryColor,
                  ),
                ),
                Text(
                  'response time',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _format(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (d.inHours > 0) return '${d.inHours}:${two(minutes)}:${two(seconds)}';
    return '${two(minutes)}:${two(seconds)}';
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 7.0;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);

    canvas.drawArc(
      arcRect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    canvas.drawArc(
      arcRect,
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.trackColor != trackColor;
}
