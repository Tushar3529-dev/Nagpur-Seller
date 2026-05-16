import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:hyper_local_seller/config/colors.dart';

class AddProductProcessBottomSheet extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final Function(int) onStepSelected;

  const AddProductProcessBottomSheet({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.onStepSelected,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              // Down arrow for close
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFF424242),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 30),
                ),
              ),
              const SizedBox(height: 15),
              Text(
                AppLocalizations.of(context)!.addProductsProcess,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  itemCount: totalSteps,
                  itemBuilder: (context, index) {
                    final step = index + 1;
                    bool isCompleted = step < currentStep;
                    bool isCurrent = step == currentStep;
                    
                    Color cardBgColor;
                    Color circleColor;
                    Color circleBorderColor;
                    Color textColor;
                    Color subTextColor;
                    Color numberTextColor;

                    if (isCompleted) {
                      cardBgColor = Colors.white;
                      circleColor = Colors.transparent;
                      circleBorderColor = AppColors.stepCompletedColor;
                      textColor = Colors.black;
                      subTextColor = AppColors.stepCompletedColor;
                      numberTextColor = AppColors.stepCompletedColor;
                    } else if (isCurrent) {
                      cardBgColor = AppColors.stepCurrentBgColor;
                      circleColor = AppColors.stepCurrentColor;
                      circleBorderColor = AppColors.stepCurrentColor;
                      textColor = Colors.black;
                      subTextColor = const Color(0xFF64748B);
                      numberTextColor = Colors.white;
                    } else {
                      cardBgColor = AppColors.stepPendingBgColor;
                      circleColor = AppColors.stepPendingCircleColor;
                      circleBorderColor = AppColors.stepPendingCircleColor;
                      textColor = Colors.black;
                      subTextColor = AppColors.stepPendingColor;
                      numberTextColor = Colors.black;
                    }

                    return GestureDetector(
                      onTap: () => onStepSelected(step),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cardBgColor,
                          borderRadius: BorderRadius.circular(16),
                          border: isCompleted || isCurrent
                              ? Border.all(color: const Color(0xFFE2E8F0))
                              : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                color: circleColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: circleBorderColor, width: 2),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "$step.",
                                style: TextStyle(
                                  color: numberTextColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getStepTitle(context, step),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                  Text(
                                    isCompleted ? AppLocalizations.of(context)!.stepCompleted : isCurrent ? AppLocalizations.of(context)!.stepCurrent : AppLocalizations.of(context)!.stepPending,
                                    style: TextStyle(
                                      color: subTextColor,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getStepTitle(BuildContext context, int step) {
    switch (step) {
      case 1: return AppLocalizations.of(context)!.selectCategory;
      case 2: return AppLocalizations.of(context)!.productInformation;
      case 3: return AppLocalizations.of(context)!.policiesAndFeatures;
      case 4: return AppLocalizations.of(context)!.productVariation;
      case 5: return AppLocalizations.of(context)!.productImages;
      case 6: return AppLocalizations.of(context)!.productsDescription;
      case 7: return AppLocalizations.of(context)!.pricingAndTaxes;
      default: return "";
    }
  }
}
