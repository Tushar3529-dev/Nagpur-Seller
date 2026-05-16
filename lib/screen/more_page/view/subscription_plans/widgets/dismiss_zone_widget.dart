import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hyper_local_seller/config/colors.dart'; // ← keep your color file
import 'package:hyper_local_seller/utils/responsive.dart';

class DismissZoneWidget extends StatefulWidget {
  final bool isVisible;
  final bool isHovering;

  const DismissZoneWidget({
    super.key,
    required this.isVisible,
    required this.isHovering,
  });

  @override
  State<DismissZoneWidget> createState() => _DismissZoneWidgetState();
}

class _DismissZoneWidgetState extends State<DismissZoneWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _glowAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _scaleAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeInOutCubicEmphasized,
      ),
    );

    _glowAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _opacityAnim = Tween<double>(
      begin: 0.65,
      end: 0.92,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(covariant DismissZoneWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isHovering != oldWidget.isHovering) {
      if (widget.isHovering) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    final double zoneSize = Responsive.isMobile ? 90.0 : 120.0;
    final double iconSizeDefault = Responsive.isMobile ? 32.0 : 40.0;
    final double iconSizeActive = Responsive.isMobile ? 40.0 : 50.0;
    final double bottomOffset = Responsive.isMobile ? 40.0 : 56.0;

    final Color baseColor = widget.isHovering
        ? AppColors
              .errorColor // or better: Colors.red.shade700
        : Colors.grey.shade900;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
      bottom: widget.isVisible ? bottomOffset : -220,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 320),
          opacity: widget.isVisible ? 1.0 : 0.0,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) {
                    return Container(
                      height: zoneSize,
                      width: zoneSize,
                      decoration: BoxDecoration(
                        color: baseColor.withValues(alpha:_opacityAnim.value),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.isHovering
                              ? Colors.white.withValues(alpha:0.55)
                              : Colors.white.withValues(alpha:0.18),
                          width: widget.isHovering ? 1.8 : 1.0,
                        ),
                        boxShadow: [
                          // Soft outer glow
                          BoxShadow(
                            color: widget.isHovering
                                ? AppColors.errorColor.withValues(alpha:
                                    0.38 * _glowAnim.value,
                                  )
                                : Colors.black.withValues(alpha:
                                    0.18 * _glowAnim.value,
                                  ),
                            blurRadius: widget.isHovering ? 28 : 16,
                            spreadRadius: widget.isHovering ? 6 : 2,
                          ),
                          // Subtle inner highlight (glassmorphic feel)
                          if (widget.isHovering)
                            BoxShadow(
                              color: Colors.white.withValues(alpha:0.14),
                              blurRadius: 0,
                              spreadRadius: -2,
                              offset: const Offset(-2, -2),
                            ),
                        ],
                      ),
                      child: child,
                    );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: animation,
                            child: child,
                          ),
                        ),
                        child: Icon(
                          widget.isHovering
                              ? Icons.delete_forever_rounded
                              : Icons.delete_sweep_rounded,
                          key: ValueKey<bool>(widget.isHovering),
                          color: Colors.white.withValues(alpha:
                            widget.isHovering ? 1.0 : 0.9,
                          ),
                          size: widget.isHovering
                              ? iconSizeActive
                              : iconSizeDefault,
                          shadows: widget.isHovering
                              ? [
                                  Shadow(
                                    color: AppColors.errorColor.withValues(alpha:
                                      0.6,
                                    ),
                                    blurRadius: 12,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
