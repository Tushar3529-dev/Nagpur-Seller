import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';

class SettingsSection extends StatelessWidget {
  final String sectionTitle;
  final List<SettingsTileData> tiles;

  const SettingsSection({
    super.key,
    required this.sectionTitle,
    required this.tiles,
  });

  @override
  Widget build(BuildContext context) {
    final screenType = context.screenType;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final containerColor = isDark
        ? theme.colorScheme.surfaceContainer
        : theme.colorScheme.surface;
    final borderColor = isDark
        ? theme.colorScheme.surfaceContainer
        : AppColors.customBoxBorder;
    final dividerColor = isDark
        ? AppColors.darkOutline
        : theme.colorScheme.outlineVariant;
    final sectionTitleColor = isDark
        ? Colors.white
        : theme.colorScheme.onSecondaryContainer;

    return Container(
      margin: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(UIUtils.radiusXL(screenType)),
        border: Border.all(
          strokeAlign: BorderSide.strokeAlignOutside,
          color: borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Padding(
            padding: UIUtils.sectionPadding(screenType),
            child: Text(
              sectionTitle.toUpperCase(),
              style: TextStyle(
                fontSize: UIUtils.sectionTitle(screenType),
                fontWeight: FontWeight.w600,
                color: sectionTitleColor,
                letterSpacing: 0.5,
              ),
            ),
          ),

          Divider(height: 1, thickness: 0.5, color: dividerColor),

          // Tiles List
          ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tiles.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, thickness: 0.5, color: dividerColor),
            itemBuilder: (context, index) {
              final tile = tiles[index];
              return SettingsTile(
                img: tile.img,
                title: tile.title,
                subtitle: tile.subtitle,
                onTap: tile.onTap,
                color: tile.color,
              );
            },
          ),
        ],
      ),
    );
  }
}

class SettingsTile extends StatelessWidget {
  final String img;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color? color;

  const SettingsTile({
    super.key,
    required this.img,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final screenType = context.screenType;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white70 : theme.colorScheme.tertiary;
    final titleColor = isDark
        ? AppColors.darkFontColor
        : AppColors.lightFontColor;
    final subtitleColor = isDark ? Colors.white70 : Colors.grey.shade600;
    final iconBgColor = isDark
        ? AppColors.darkExtraCardColor
        : AppColors.customBoxBorder;
    final chevronColor = isDark ? Colors.grey[400] : AppColors.chevronIconColor;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: UIUtils.tilePadding(screenType),
        child: Row(
          children: [
            // Icon
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SvgPicture.asset(
                img,
                width: UIUtils.tileIcon(screenType),
                height: UIUtils.tileIcon(screenType),
                colorFilter: ColorFilter.mode(
                  color ?? iconColor,
                  BlendMode.srcIn,
                ),
              ),
            ),
            SizedBox(width: UIUtils.gapMD(screenType)),

            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: UIUtils.tileTitle(screenType),
                      fontWeight: FontWeight.w400,
                      color: color ?? titleColor,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: UIUtils.tileSubtitle(screenType),
                        fontWeight: FontWeight.w400,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Chevron
            Icon(
              Icons.chevron_right,
              color: chevronColor,
              size: UIUtils.chevronIcon(screenType),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsTileData {
  final String img;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? color;

  const SettingsTileData({
    required this.img,
    required this.title,
    this.subtitle = '',
    required this.onTap,
    this.color,
  });
}

class SettingsSectionData {
  final String title;
  final List<SettingsTileData> tiles;

  const SettingsSectionData({required this.title, required this.tiles});
}
