// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hyper_local_seller/config/constant.dart';
import 'package:hyper_local_seller/widgets/custom/custom_buttons.dart';

/// Reusable empty state widget for lists with no data
class EmptyStateWidget extends StatelessWidget {
  final String svgPath;
  final String title;
  final String? subtitle;
  final String? actionText;
  final VoidCallback? onAction;
  final double svgSize;

  const EmptyStateWidget({
    super.key,
    required this.svgPath,
    required this.title,
    this.subtitle,
    this.actionText,
    this.onAction,
    this.svgSize = 180,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              svgPath,
              width: svgSize,
              height: svgSize,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: AppConstants.fontFamily,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: AppConstants.fontFamily,
                  color: theme.colorScheme.onSurface.withValues(alpha:0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 24),
              PrimaryButton(
                text: actionText!,
                onPressed: onAction!,
                width: 160,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
