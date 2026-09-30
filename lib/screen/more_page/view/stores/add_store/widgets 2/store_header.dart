import 'package:flutter/material.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';

class StoreHeader extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final ScreenType screenType;
  final Function(int) onStepTap;

  const StoreHeader({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.screenType,
    required this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: UIUtils.gapMD(screenType),
        vertical: UIUtils.gapSM(screenType),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: UIUtils.gapSM(screenType),
        vertical: UIUtils.gapMD(screenType),
      ),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(UIUtils.radiusMD(screenType)),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Row(
        children: List.generate(totalSteps * 2 - 1, (index) {
          if (index.isEven) {
            final stepNumber = (index ~/ 2) + 1;
            return GestureDetector(
              onTap: () => onStepTap(stepNumber),
              child: _buildStepCircle(stepNumber, isDark, l10n),
            );
          } else {
            final stepBeforeLine = (index ~/ 2) + 1;
            return _buildConnectingLine(stepBeforeLine, isDark);
          }
        }),
      ),
    );
  }

  Widget _buildStepCircle(int stepNumber, bool isDark, AppLocalizations? l10n) {
    final bool isCompleted = stepNumber < currentStep;
    final bool isCurrent = stepNumber == currentStep;
    final bool isActive = isCompleted || isCurrent;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? (isCompleted
                      ? AppColors.successColor
                      : AppColors.primaryColor)
                : (isDark ? Colors.grey.shade800 : const Color(0xFFF1F5F9)),
            border: !isActive
                ? Border.all(
                    color: isDark
                        ? Colors.grey.shade700
                        : const Color(0xFFE2E8F0),
                    width: 1.5,
                  )
                : null,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    stepNumber.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? Colors.white
                          : (isDark
                                ? Colors.grey.shade500
                                : const Color(0xFF94A3B8)),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _getStepLabel(stepNumber, l10n).replaceAll('\n', ' '),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9, // Smaller for 5 steps
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive
                ? (isDark ? Colors.white : Colors.black87)
                : (isDark ? Colors.grey.shade500 : const Color(0xFF94A3B8)),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectingLine(int stepBeforeLine, bool isDark) {
    final bool isActive = stepBeforeLine < currentStep;

    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 15),
        color: isActive
            ? AppColors.primaryColor
            : (isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0)),
      ),
    );
  }

  String _getStepLabel(int step, AppLocalizations? l10n) {
    switch (step) {
      case 1:
        return l10n?.basic ?? "Basic";
      case 2:
        return l10n?.location ?? "Location";
      case 3:
        return l10n?.identity ?? "Identity";
      case 4:
        return l10n?.documents ?? "Documents";
      case 5:
        return l10n?.bank ?? "Bank";
      default:
        return "";
    }
  }
}
