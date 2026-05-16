// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_svg.dart';

class AnalysisCard extends StatelessWidget {
  final String label;
  final String value;
  final String trend;
  final Color trendColor;
  final String svgPath;
  final Color iconBgColor;
  final ScreenType screenType;
  final VoidCallback? onTap;

  const AnalysisCard({
    super.key,
    required this.label,
    required this.value,
    required this.trend,
    required this.trendColor,
    required this.svgPath,
    required this.iconBgColor,
    required this.screenType,
    this.onTap
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: UIUtils.cardPadding(screenType),
        decoration: BoxDecoration(
          color: isDark
              ? Theme.of(context).colorScheme.surfaceContainer
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(UIUtils.radiusMD(screenType)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: UIUtils.caption(screenType) + 1,
                    fontWeight: UIUtils.semiBold,
                    color: Colors.grey.shade600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconBgColor.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(UIUtils.radiusXS(screenType)),
                  ),
                  child: CustomSvg(
                    svgPath: svgPath,
                    width: UIUtils.smallIcon(screenType) + 4,
                    height: UIUtils.smallIcon(screenType) + 4,
                    color: iconBgColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: UIUtils.gapSM(screenType)),
            Text(
              value,
              style: TextStyle(
                fontSize: UIUtils.appTitle(screenType),
                fontWeight: UIUtils.bold,
              ),
            ),
            SizedBox(height: UIUtils.gapXS(screenType)),
            Text(
              trend,
              style: TextStyle(
                fontSize: UIUtils.caption(screenType),
                fontWeight: UIUtils.semiBold,
                color: trendColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
