// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SelectionItem<T> {
  final String label;
  final String? sublabel;
  final T value;
  final String? image;
  final IconData? icon;
  final String? leadingText;
  final bool isDisabled;
  final String? onDisabledTapMessage;

  SelectionItem({
    required this.label,
    required this.value,
    this.sublabel,
    this.image,
    this.icon,
    this.leadingText,
    this.isDisabled = false,
    this.onDisabledTapMessage,
  });
}

class CustomSelectionSheet<T> extends StatelessWidget {
  final String title;
  final List<SelectionItem<T>> items;
  final T? selectedValue;
  final ValueChanged<T> onSelected;
  final ScreenType screenType;

  const CustomSelectionSheet({
    super.key,
    required this.title,
    required this.items,
    required this.onSelected,
    required this.screenType,
    this.selectedValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(UIUtils.radiusLG(screenType)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              title,
              style: TextStyle(
                fontSize: UIUtils.pageTitle(screenType),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.symmetric(vertical: UIUtils.gapMD(screenType)),
              itemCount: items.length,
              separatorBuilder: (context, index) =>
                  SizedBox(height: 0),
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = item.value == selectedValue;

                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: UIUtils.gapMD(screenType),
                  ),
                  child: Opacity(
                    opacity: item.isDisabled ? 0.5 : 1.0,
                    child: InkWell(
                      onTap:
                          item.isDisabled
                              ? () {
                                if (item.onDisabledTapMessage != null) {
                                  showCustomSnackbar(
                                    context: context,
                                    message: item.onDisabledTapMessage!,
                                    isWarning: true,
                                  );
                                }
                              }
                              : () {
                                onSelected(item.value);
                                Navigator.pop(context);
                              },
                      borderRadius: BorderRadius.circular(
                        UIUtils.radiusMD(screenType),
                      ),
                      child: Container(
                        padding: UIUtils.tilePadding(screenType),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? AppColors.primaryColor.withValues(
                                    alpha: 0.08,
                                  )
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(
                            UIUtils.radiusMD(screenType),
                          ),
                          border: Border.all(
                            color:
                                isSelected
                                    ? AppColors.primaryColor.withValues(
                                      alpha: 0.2,
                                    )
                                    : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            if (_buildLeading(item) != null) ...[
                              _buildLeading(item)!,
                              SizedBox(width: UIUtils.gapMD(screenType)),
                            ],
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.label,
                                    style: TextStyle(
                                      fontSize: UIUtils.tileTitle(screenType),
                                      fontWeight:
                                          isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                      color:
                                          isSelected
                                              ? AppColors.primaryColor
                                              : null,
                                    ),
                                  ),
                                  if (item.sublabel != null)
                                    Text(
                                      item.sublabel!,
                                      style: TextStyle(
                                        fontSize: UIUtils.caption(screenType),
                                        color:
                                            isSelected
                                                ? AppColors.primaryColor
                                                    .withValues(alpha: 0.8)
                                                : Colors.grey.shade600,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                              if (item.isDisabled)
                              IconButton(
                                icon: const Icon(
                                  Icons.info_outline,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                                onPressed: () {
                                  if (item.onDisabledTapMessage != null) {
                                    showCustomSnackbar(
                                      context: context,
                                      message: item.onDisabledTapMessage!,
                                      isWarning: true,
                                    );
                                  }
                                },
                              ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.primaryColor,
                                size: 22,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget? _buildLeading(SelectionItem<T> item) {
    if (item.image != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(UIUtils.radiusSM(screenType)),
        child: CachedNetworkImage(
          imageUrl: item.image!,
          width: UIUtils.avatarMD(screenType) + 4,
          height: UIUtils.avatarMD(screenType) + 4,
          fit: BoxFit.cover,
          errorWidget: (context, url, error) => const Icon(Icons.broken_image),
        ),
      );
    } else if (item.icon != null) {
      return Icon(item.icon, size: UIUtils.tileIcon(screenType));
    } else if (item.leadingText != null) {
      return Container(
        width: UIUtils.avatarMD(screenType) + 4,
        height: UIUtils.avatarMD(screenType) + 4,
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(UIUtils.radiusSM(screenType)),
        ),
        alignment: Alignment.center,
        child: Text(
          item.leadingText!,
          style: TextStyle(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    }
    return null;
  }

  static void show<T>({
    required BuildContext context,
    required String title,
    required List<SelectionItem<T>> items,
    required ValueChanged<T> onSelected,
    T? selectedValue,
  }) {
    // We can't easily get screenType here without context or bloc
    // But we can assume it's available via extensions or Provider if needed.
    // However, for simplicity and consistency with current codebase:
    final screenType = context.screenTypeRead;

    showModalBottomSheet(
      context: context,
      isDismissible: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CustomSelectionSheet<T>(
        title: title,
        items: items,
        onSelected: onSelected,
        selectedValue: selectedValue,
        screenType: screenType,
      ),
    );
  }
}
