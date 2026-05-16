import 'package:flutter/material.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';
import 'package:hyper_local_seller/config/colors.dart';

class CustomLoadingIndicator extends StatefulWidget {
  final double size;
  final double strokeWidth;
  final Color? color;
  final double? value;
  final bool isDeterminate;
  final bool showPercentage;

  const CustomLoadingIndicator({
    super.key,
    this.size = 48,
    this.strokeWidth = 3,
    this.color,
    this.value,
    this.isDeterminate = false,
    this.showPercentage = false,
  });

  @override
  State<CustomLoadingIndicator> createState() => _CustomLoadingIndicatorState();
}

class _CustomLoadingIndicatorState extends State<CustomLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.color ?? AppColors.primaryColor;
    final bool spinnerMode = !widget.isDeterminate;
    final double initialValue =
    widget.isDeterminate ? (widget.value ?? 0) * 100 : 0;
    final int percentage = ((widget.value ?? 0) * 100).round();

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Subtle filled background circle ─────────────────────
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: effectiveColor.withValues(alpha: 0.05),
            ),
          ),

          // ── Main sleek circular slider ──────────────────────────
          SleekCircularSlider(
            initialValue: initialValue,
            appearance: CircularSliderAppearance(
              spinnerMode: spinnerMode,
              size: widget.size,
              startAngle: 270,
              angleRange: 360,
              customColors: CustomSliderColors(
                dotColor: Colors.transparent,
                progressBarColors: [
                  effectiveColor.withValues(alpha: 0.5),
                  effectiveColor,
                ],
                trackColor: effectiveColor.withValues(alpha: 0.08),
                shadowColor: effectiveColor,
                shadowMaxOpacity: 0.15,
              ),
              customWidths: CustomSliderWidths(
                progressBarWidth: widget.strokeWidth,
                trackWidth: widget.strokeWidth,
                handlerSize: 0,
                shadowWidth: widget.strokeWidth * 2.5,
              ),
            ),
            innerWidget: (_) => const SizedBox.shrink(),
          ),

          // ── Centre: percentage or soft pulsing dot ──────────────
          if (widget.isDeterminate && widget.showPercentage)
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: widget.size * 0.2,
                fontWeight: FontWeight.w600,
                color: effectiveColor,
                letterSpacing: -0.5,
              ),
            )
          else if (!widget.isDeterminate)
            FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                width: widget.size * 0.1,
                height: widget.size * 0.1,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: effectiveColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}





/*
import 'package:flutter/material.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';
import 'package:hyper_local_seller/config/colors.dart';

class CustomLoadingIndicator extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color? color;
  final double? value;
  final bool isDeterminate;

  const CustomLoadingIndicator({
    super.key,
    this.size = 40,
    this.strokeWidth = 3,
    this.color,
    this.value,
    this.isDeterminate = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool spinnerMode = !isDeterminate;
    final double initialValue = isDeterminate ? (value ?? 0) * 100 : 0;

    return SizedBox(
      width: size,
      height: size,
      child: SleekCircularSlider(
        initialValue: initialValue,
        appearance: CircularSliderAppearance(
          spinnerMode: spinnerMode,
          size: size,
          startAngle: 270,
          angleRange: 360,
          customColors: CustomSliderColors(
            dotColor: Colors.transparent,
            progressBarColor: color ?? AppColors.primaryColor,
            trackColor: (color ?? AppColors.primaryColor).withValues(alpha: 0.1),
            shadowColor: Colors.transparent,
          ),
          customWidths: CustomSliderWidths(
            progressBarWidth: strokeWidth,
            trackWidth: strokeWidth,
            handlerSize: 0,
            shadowWidth: 0,
          ),
        ),
      ),
    );
  }
}
*/
