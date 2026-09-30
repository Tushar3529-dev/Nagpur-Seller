import 'package:flutter/material.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/store_configuration/widgets/store_config_header.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/store_configuration/widgets/steps/scheduling_step.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/store_configuration/widgets/steps/information_step.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/store_configuration/widgets/steps/policies_step.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/store_configuration/widgets/steps/metadata_step.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/store_configuration/widgets/success_screen.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';

class StoreConfigurationPage extends StatefulWidget {
  const StoreConfigurationPage({super.key});

  @override
  State<StoreConfigurationPage> createState() => _StoreConfigurationPageState();
}

class _StoreConfigurationPageState extends State<StoreConfigurationPage> {
  int _currentStep = 1;
  final int _totalSteps = 4;
  bool _showSuccess = false;

  final List<GlobalKey<FormState>> _formKeys = List.generate(4, (index) => GlobalKey<FormState>());

  void _onStepChanged(int step) {
    if (step >= 1 && step <= _totalSteps) {
      if (step > _currentStep) {
        // Validating current step before moving forward
        if (_formKeys[_currentStep - 1].currentState?.validate() ?? true) {
          FocusScope.of(context).unfocus();
          setState(() {
            _currentStep = step;
          });
        }
      } else {
        // Going back is always allowed
        FocusScope.of(context).unfocus();
        setState(() {
          _currentStep = step;
        });
      }
    }
  }

  void _onStepTap(int step) {
    if (step == _currentStep) return;

    if (step > _currentStep) {
      // Check if current step is valid
      if (_formKeys[_currentStep - 1].currentState?.validate() ?? true) {
        // Check if user is jumping more than 1 step
        if (step > _currentStep + 1) {
          showCustomSnackbar(
            context: context,
            message: AppLocalizations.of(context)!.completePreviousSteps,
            isError: true,
          );
          return;
        }
        _onStepChanged(step);
      }
    } else {
      _onStepChanged(step);
    }
  }

  void _onFinish() {
    setState(() {
      _showSuccess = true;
    });
  }

  void _onSuccessFinish() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenType = context.screenType;

    if (_showSuccess) {
      return CustomScaffold(
        title: 'storeConfiguration',
        showAppbar: true,
        centerTitle: true,
        onBackTap: () {
          Navigator.of(context).pop();
        },
        body: SuccessScreen(onFinish: _onSuccessFinish),
      );
    }

    return CustomScaffold(
      title: 'storeConfiguration',
      showAppbar: true,
      centerTitle: true,
      onBackTap: () {
        Navigator.of(context).pop();
      },
      body: Column(
        children: [
          StoreConfigHeader(
            currentStep: _currentStep,
            totalSteps: _totalSteps,
            screenType: screenType,
            onStepTap: _onStepTap,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                UIUtils.gapMD(screenType),
                UIUtils.gapSM(screenType),
                UIUtils.gapMD(screenType),
                UIUtils.gapMD(screenType),
              ),
              child: _buildStepContent(_currentStep),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomButtons(screenType, l10n),
    );
  }

  Widget _buildBottomButtons(ScreenType screenType, AppLocalizations l10n) {
    final bool isFirstStep = _currentStep == 1;
    final bool isLastStep = _currentStep == _totalSteps;

    return Container(
      padding: EdgeInsets.all(UIUtils.gapMD(screenType)),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (!isFirstStep) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _onStepChanged(_currentStep - 1),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    side: const BorderSide(color: AppColors.primaryColor),
                  ),
                  child: Text(
                    l10n.previous,
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 16,
                      fontWeight: UIUtils.semiBold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
            ],
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  if (_currentStep < _totalSteps) {
                    _onStepChanged(_currentStep + 1);
                  } else {
                    if (_formKeys[_currentStep - 1].currentState?.validate() ?? true) {
                      _onFinish();
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isLastStep ? 'finish' : l10n.next,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(int step) {
    switch (step) {
      case 1:
        return SchedulingStep(formKey: _formKeys[0]);
      case 2:
        return InformationStep(formKey: _formKeys[1]);
      case 3:
        return PoliciesStep(formKey: _formKeys[2]);
      case 4:
        return MetadataStep(formKey: _formKeys[3]);
      default:
        return const SizedBox.shrink();
    }
  }
}
