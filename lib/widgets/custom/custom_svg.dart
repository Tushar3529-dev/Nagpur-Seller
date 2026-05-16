import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A reusable SVG widget with theme-aware coloring.
///
/// When [isEnabled] is false, the SVG displays in grey.
/// When [isEnabled] is true, the SVG uses black (light theme) or white (dark theme).
/// Use [color] to override the automatic color behavior.
class CustomSvg extends StatelessWidget {
  /// Path to the SVG asset (required)
  final String svgPath;

  /// Width of the SVG (optional - uses intrinsic size if null)
  final double? width;

  /// Height of the SVG (optional - uses intrinsic size if null)
  final double? height;

  /// Explicit color override (optional - takes precedence over theme colors)
  final Color? color;

  /// Whether the SVG is in enabled state (default: true)
  /// - false: displays in grey
  /// - true: displays in theme-appropriate color (black/white)
  final bool isEnabled;

  /// Whether to apply a color filter to the SVG (default: false)
  final bool colorFilterOn;

  /// How the SVG should be inscribed into the space (default: BoxFit.contain)
  final BoxFit fit;

  const CustomSvg({
    super.key,
    required this.svgPath,
    this.width,
    this.height,
    this.color,
    this.isEnabled = true,
    this.fit = BoxFit.contain,
    this.colorFilterOn = true,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    // Determine the color to use
    Color effectiveColor;
    if (color != null) {
      // Explicit color override
      effectiveColor = color!;
    } else if (!isEnabled) {
      // Disabled state: greyish color
      effectiveColor = Colors.grey;
    } else {
      // Enabled state: black for light theme, white for dark theme
      effectiveColor = brightness == Brightness.dark
          ? Colors.white
          : Colors.black;
    }

    return SvgPicture.asset(
      svgPath,
      width: width,
      height: height,
      fit: fit,
      colorFilter: colorFilterOn
          ? ColorFilter.mode(effectiveColor, BlendMode.srcIn)
          : null,
    );
  }
}
