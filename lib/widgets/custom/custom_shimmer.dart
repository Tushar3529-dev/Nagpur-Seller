import 'package:flutter/material.dart';

class CustomShimmer extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const CustomShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<CustomShimmer> createState() => _CustomShimmerState();
}

class _CustomShimmerState extends State<CustomShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [
                0.1,
                _animation.value - 0.5,
                _animation.value,
                _animation.value + 0.5,
                0.9,
              ],
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
                Colors.grey.shade300,
              ],
            ),
          ),
        );
      },
    );
  }
}
class PlanCardShimmer extends StatelessWidget {
  const PlanCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151921) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 0.8,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16).copyWith(top: 24, bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomShimmer(width: 80, height: 14),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                CustomShimmer(width: 100, height: 36),
                const SizedBox(width: 12),
                CustomShimmer(width: 60, height: 16),
              ],
            ),
            const SizedBox(height: 24),
            CustomShimmer(
              width: double.infinity,
              height: 48,
              borderRadius: BorderRadius.circular(12),
            ),
            const SizedBox(height: 24),
            ...List.generate(
              4,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    CustomShimmer(width: 18, height: 18, borderRadius: BorderRadius.circular(10)),
                    const SizedBox(width: 12),
                    CustomShimmer(width: 150, height: 14),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
