import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';

/// A reusable dashed border upload area widget for file/image uploads.
class CustomUploadArea extends StatelessWidget {
  final String hint;
  final IconData? icon;
  final double height;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final String? fileName;

  const CustomUploadArea({
    super.key,
    required this.hint,
    this.icon,
    this.height = 150,
    this.onTap,
    this.onRemove,
    this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool hasImage = fileName != null && fileName!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            GestureDetector(
              onTap: hasImage ? null : onTap,
              child: CustomPaint(
                painter: DashedRectPainter(
                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                ),
                child: Container(
                  width: double.infinity,
                  height: height,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: hasImage
                      ? _buildPreview(context, isDark)
                      : _buildPlaceholder(isDark),
                ),
              ),
            ),
            if (hasImage && onRemove != null)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPreview(BuildContext context, bool isDark) {
    // Check if it's a local file path
    final file = File(fileName!);
    if (file.existsSync()) {
      final isVideo = fileName!.toLowerCase().endsWith('.mp4') ||
          fileName!.toLowerCase().endsWith('.mov') ||
          fileName!.toLowerCase().endsWith('.mkv') ||
          fileName!.toLowerCase().endsWith('.avi');

      if (isVideo) {
        return Container(
          width: double.infinity,
          height: height,
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.videocam,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                size: 32,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  fileName!.split('/').last,
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }

      return Image.file(
        file,
        width: double.infinity,
        height: height,
        fit: BoxFit.cover,
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.insert_drive_file,
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          size: 20,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            fileName!.split('/').last,
            style: TextStyle(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            size: 20,
          ),
          const SizedBox(width: 8),
        ],
        Text(
          hint,
          style: TextStyle(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}


/// Custom painter to draw a dashed rectangular border.
class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double radius;

  DashedRectPainter({
    this.color = Colors.grey,
    this.strokeWidth = 1.0,
    this.gap = 5.0,
    this.radius = 8.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    Path path = Path();
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    ));

    Path dashPath = Path();
    double distance = 0.0;
    for (PathMetric measurePath in path.computeMetrics()) {
      while (distance < measurePath.length) {
        dashPath.addPath(
          measurePath.extractPath(distance, distance + gap),
          Offset.zero,
        );
        distance += gap * 2;
      }
      distance = 0.0;
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
