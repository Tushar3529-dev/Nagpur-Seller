import 'package:flutter/material.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_buttons.dart';
import 'package:hyper_local_seller/widgets/custom/custom_svg.dart';

Future<void> showAppAlertDialog({
  required BuildContext context,
  required String title,
  required String message,
  IconData? icon,
  String? svgPath,
  Color? iconColor,
  Color? confirmColor,
  String? confirmText,
  String? cancelText,
  bool isDestructive = false,
  VoidCallback? onConfirm,
  VoidCallback? onCancel,
  bool barrierDismissible = true,
  double? size,
  double? padding,
}) async {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final screenType = context.screenTypeRead;

  final bool hasVisual = icon != null || svgPath != null;
  final bool isCenteredLayout = hasVisual;

  await showDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) {
      return AlertDialog(
        backgroundColor: isDark
            ? AppColors.mainDarkContainerBgColor
            : AppColors.mainLightContainerBgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIUtils.radiusXL(screenType)),
        ),
        titlePadding: isCenteredLayout
            ? EdgeInsets.fromLTRB(
                UIUtils.gapLG(screenType),
                UIUtils.gapXL(screenType),
                UIUtils.gapLG(screenType),
                0,
              )
            : EdgeInsets.fromLTRB(
                UIUtils.gapLG(screenType),
                UIUtils.gapXL(screenType),
                UIUtils.gapLG(screenType),
                0,
              ),
        contentPadding: EdgeInsets.fromLTRB(
          UIUtils.gapLG(screenType),
          12,
          UIUtils.gapLG(screenType),
          20,
        ),
        actionsPadding: EdgeInsets.fromLTRB(
          UIUtils.gapXL(screenType),
          12,
          UIUtils.gapXL(screenType),
          20,
        ),
        title: isCenteredLayout
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (svgPath != null)
                    Container(
                      decoration: BoxDecoration(
                        color: iconColor?.withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      padding: EdgeInsets.all(padding ?? 12),
                      margin: const EdgeInsets.only(bottom: 10),
                      child: CustomSvg(
                        svgPath: svgPath,
                        width: size ?? 36,
                        height: size ?? 36,
                        color:
                            iconColor ??
                            (isDestructive
                                ? AppColors.errorColor
                                : AppColors.primaryColor),
                      ),
                    )
                  else if (icon != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Icon(
                        icon,
                        size: 48,
                        color:
                            iconColor ??
                            (isDestructive
                                ? AppColors.errorColor
                                : AppColors.primaryColor),
                      ),
                    ),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: UIUtils.sectionTitle(screenType),
                      fontWeight: UIUtils.bold,
                      color: isDark ? Colors.white : AppColors.lightTertiary,
                    ),
                  ),
                ],
              )
            : Text(
                title,
                style: TextStyle(
                  fontSize: UIUtils.sectionTitle(screenType),
                  fontWeight: UIUtils.bold,
                  color: isDark ? Colors.white : AppColors.lightTertiary,
                ),
              ),
        content: Text(
          message,
          textAlign: isCenteredLayout ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: UIUtils.body(screenType),
            height: 1.45,
            color: isDark ? Colors.white70 : Colors.grey.shade800,
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  text:
                      cancelText ??
                      AppLocalizations.of(context)?.cancel ??
                      "Cancel",
                  onPressed: () {
                    Navigator.pop(context);
                    onCancel?.call();
                  },
                ),
              ),
              SizedBox(width: UIUtils.gapMD(screenType)),
              Expanded(
                child: PrimaryButton(
                  text:
                      confirmText ??
                      AppLocalizations.of(context)?.confirm ??
                      "Confirm",
                  backgroundColor: isDestructive
                      ? AppColors.errorColor
                      : confirmColor,
                  foregroundColor: isDestructive ? Colors.white : null,
                  onPressed: () {
                    Navigator.pop(context);
                    onConfirm?.call();
                  },
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}
