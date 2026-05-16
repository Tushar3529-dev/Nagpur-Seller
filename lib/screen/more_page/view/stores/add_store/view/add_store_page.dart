import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/add_store/bloc/add_store_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/add_store/bloc/add_store_state.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/add_store/widgets/store_header.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/add_store/widgets/steps/basic_details_step.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/add_store/widgets/steps/location_details_step.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/add_store/widgets/steps/logo_banner_step.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/add_store/widgets/steps/business_documents_step.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/add_store/widgets/steps/bank_details_step.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/model/store_model.dart';
import 'package:hyper_local_seller/service/demo_guard.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/widgets/custom/custom_loading_indicator.dart';

import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';

class AddStorePage extends StatefulWidget {
  final Store? store;
  const AddStorePage({super.key, this.store});

  @override
  State<AddStorePage> createState() => _AddStorePageState();
}

class _AddStorePageState extends State<AddStorePage> {
  int _currentStep = 1;
  final int _totalSteps = 5;

  final List<GlobalKey<FormState>> _formKeys = List.generate(
    5,
    (index) => GlobalKey<FormState>(),
  );

  @override
  void initState() {
    super.initState();
    context.read<AddStoreBloc>().add(ClearAddStoreState());
    if (widget.store != null) {
      context.read<AddStoreBloc>().add(InitializeEditStore(widget.store!));
    }
  }

  void _onStepChanged(int step) {
    if (step >= 1 && step <= _totalSteps) {
      if (step > _currentStep) {
        // Validating current step before moving forward
        if (_formKeys[_currentStep - 1].currentState?.validate() ?? false) {
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
      if (_formKeys[_currentStep - 1].currentState?.validate() ?? false) {
        // Check if user is jumping more than 1 step
        if (step > _currentStep + 1) {
          showCustomSnackbar(
            context: context,
            message:
                AppLocalizations.of(context)?.completePreviousSteps ??
                'Please complete the previous steps first',
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screenType = context.screenType;

    return BlocListener<AddStoreBloc, AddStoreState>(
      listener: (context, state) {
        if (state.successMessage != null) {
          showCustomSnackbar(context: context, message: state.successMessage!);
          context.read<AddStoreBloc>().add(ResetMessages());
          Navigator.of(context).pop(true);
        } else if (state.errorMessage != null) {
          showCustomSnackbar(
            context: context,
            message: state.errorMessage!,
            isError: true,
          );
          context.read<AddStoreBloc>().add(ResetMessages());
        }
      },
      child: CustomScaffold(
        title: widget.store != null
            ? l10n?.editStore ?? "Edit Store"
            : l10n?.addStore ?? 'Add Store',
        showAppbar: true,
        centerTitle: true,
        onBackTap: () {
          Navigator.of(context).pop();
        },
        body: BlocBuilder<AddStoreBloc, AddStoreState>(
          builder: (context, state) {
            if (state.isLoading &&
                state.formData.isEmpty &&
                widget.store != null) {
              return const Center(child: CustomLoadingIndicator());
            }
            return Column(
              children: [
                StoreHeader(
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
            );
          },
        ),
        bottomNavigationBar: _buildBottomButtons(screenType, l10n),
      ),
    );
  }

  Widget _buildBottomButtons(ScreenType screenType, AppLocalizations? l10n) {
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
                    l10n?.previous ?? 'Previous',
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
              child: BlocBuilder<AddStoreBloc, AddStoreState>(
                builder: (context, state) {
                  return ElevatedButton(
                    onPressed: state.isLoading
                        ? null
                        : () {
                            if (_currentStep < _totalSteps) {
                              _onStepChanged(_currentStep + 1);
                            } else {
                              if (_formKeys[_currentStep - 1].currentState
                                      ?.validate() ??
                                  false) {
                                _submitStore();
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
                    child: state.isLoading
                        ? const CustomLoadingIndicator(
                            size: 20,
                            color: Colors.white,
                            strokeWidth: 2,
                          )
                        : Text(
                            isLastStep
                                ? l10n?.finish ?? "Finish"
                                : l10n?.next ?? 'Next',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  );
                },
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
        return BasicDetailsStep(formKey: _formKeys[0]);
      case 2:
        return LocationDetailsStep(formKey: _formKeys[1]);
      case 3:
        return LogoBannerStep(formKey: _formKeys[2]);
      case 4:
        return BusinessDocumentsStep(formKey: _formKeys[3]);
      case 5:
        return BankDetailsStep(formKey: _formKeys[4]);
      default:
        return const SizedBox.shrink();
    }
  }

  void _submitStore() {
    if (!DemoGuard.shouldProceed(context)) return;
    context.read<AddStoreBloc>().add(
      SubmitStore(isEdit: widget.store != null, storeId: widget.store?.id),
    );
  }
}
