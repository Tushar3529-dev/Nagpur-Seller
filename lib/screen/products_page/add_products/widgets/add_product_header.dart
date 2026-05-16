import 'package:flutter/material.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';

class AddProductHeader extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final String stepTitle;
  final VoidCallback onStepTap;
  final ScreenType screenType;

  const AddProductHeader({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepTitle,
    required this.onStepTap,
    required this.screenType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        UIUtils.gapMD(screenType),
        UIUtils.gapSM(screenType),
        UIUtils.gapMD(screenType),
        0.0,
      ),
      margin: EdgeInsets.all(UIUtils.gapMD(screenType)),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(UIUtils.radiusMD(screenType)),
        border: Border.all(color: AppColors.lightOutline),
      ),
      child: InkWell(
        onTap: onStepTap,
        child: Row(
          children: [
            // Circular Progress
            SizedBox(
              width: 50,
              height: 70,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      value: currentStep / totalSteps,
                      strokeWidth: 6,
                      strokeCap: StrokeCap.round,
                      backgroundColor: AppColors.primaryColor.withValues(
                        alpha: 0.07,
                      ),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primaryColor,
                      ),
                    ),
                  ),
                  Text(
                    "$currentStep/$totalSteps",
                    style: TextStyle(
                      fontSize: UIUtils.body(screenType),
                      fontWeight: UIUtils.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: UIUtils.gapMD(screenType)),
            // Step Title and info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    stepTitle,
                    style: TextStyle(
                      fontSize: UIUtils.sectionTitle(screenType),
                      fontWeight: UIUtils.bold,
                    ),
                  ),
                  Text(
                    "Step $currentStep of $totalSteps",
                    style: TextStyle(
                      fontSize: UIUtils.sectionSubtitle(screenType),
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.primaryColor,
              size: UIUtils.tileIcon(screenType),
            ),
          ],
        ),
      ),
    );
  }
}
