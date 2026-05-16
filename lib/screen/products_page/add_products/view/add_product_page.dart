import 'dart:developer';

import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/bloc/add_product_bloc/add_product_bloc.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/widgets/add_product_header.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/widgets/add_product_process_bottom_sheet.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/widgets/steps/category_selection_step.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/widgets/steps/product_info_step.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/widgets/steps/policies_features_step.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/widgets/steps/product_variation_step.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/widgets/steps/product_images_step.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/widgets/steps/product_description_step.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/widgets/steps/pricing_taxes_step.dart';
import 'package:hyper_local_seller/service/demo_guard.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';

class AddProductPage extends StatefulWidget {
  final bool isEdit;
  const AddProductPage({super.key, required this.isEdit});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  int _currentStep = 1;
  final int _totalSteps = 7;
  bool _isLoadingShowing = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onStepChanged(int targetStep) {
    if (targetStep == _currentStep) return;

    final bloc = context.read<AddProductBloc>();
    final data = bloc.state.productData;

    // Allow going back anytime
    if (targetStep < _currentStep) {
      FocusScope.of(context).unfocus();
      setState(() => _currentStep = targetStep);
      return;
    }

    // Going forward → only allow if current step is valid
    final (bool currentOk, String? error) = _validateStep(_currentStep, data);

    if (!currentOk) {
      showCustomSnackbar(
        context: context,
        message: error ?? AppLocalizations.of(context)!.pleaseCompleteCurrentStep,
        isError: true,
      );
      return;
    }

    // Optional: also check all previous steps (more strict)
    for (int i = 1; i < targetStep; i++) {
      if (!_isStepCompleted(i, data)) {
        showCustomSnackbar(
          context: context,
          message: AppLocalizations.of(context)!.stepMustBeCompletedBeforeJumping(i),
          isError: true,
        );
        return;
      }
    }

    FocusScope.of(context).unfocus();
    setState(() => _currentStep = targetStep);
  }

  String _getStepTitle(BuildContext context, int step) {
    switch (step) {
      case 1:
        return AppLocalizations.of(context)!.selectCategory;
      case 2:
        return AppLocalizations.of(context)!.productInformation;
      case 3:
        return AppLocalizations.of(context)!.policiesAndFeatures;
      case 4:
        return AppLocalizations.of(context)!.productVariation;
      case 5:
        return AppLocalizations.of(context)!.productImages;
      case 6:
        return AppLocalizations.of(context)!.productsDescription;
      case 7:
        return AppLocalizations.of(context)!.pricingAndTaxes;
      default:
        return "";
    }
  }

  void _onNextStep() {
    final bloc = context.read<AddProductBloc>();
    final data = bloc.state.productData;

    final (bool ok, String? error) = _validateStep(_currentStep, data);

    if (ok) {
      if (_currentStep < _totalSteps) {
        _onStepChanged(_currentStep + 1);
      } else {
        _onAddProductPressed();
      }
    } else {
      showCustomSnackbar(
        context: context,
        message:
            error ??
            AppLocalizations.of(
              context,
            )!.pleaseCompleteallRequiredFieldsInPreviousSteps,
        isError: true,
      );
    }
  }

  (bool, String?) _validateStep(int step, ProductData data) {
    switch (step) {
      case 1:
        if (data.categoryId == null) {
          return (false, AppLocalizations.of(context)!.selectAtLeastOneCategory);
        }
        return (true, null);

      case 2:
        if (data.title == null || data.title!.trim().isEmpty) {
          return (false, AppLocalizations.of(context)!.productTitleRequired);
        }
        if (data.prepTime < 0) {
          return (false, AppLocalizations.of(context)!.basePrepTimeRequired);
        }
        return (true, null);

      case 3:
        final min = data.minimumOrderQuantity;
        final stepSize = data.quantityStepSize;
        final total = data.totalAllowedQuantity;

        // Mandatory fields
        if (min <= 0) {
          return (false, AppLocalizations.of(context)!.minOrderQtyPositive);
        }
        if (stepSize <= 0) {
          return (false, AppLocalizations.of(context)!.qtyStepSizePositive);
        }

        // Optional total – but when provided, must follow rules
        if (total != 0) {
          // total is explicitly set → validate it
          if (total < 0) {
            return (false, AppLocalizations.of(context)!.totalAllowedQtyPositive);
          }
          if (total < min) {
            return (
            false,
            AppLocalizations.of(context)!.totalAllowedQtyMinOrderConflict,
            );
          }
          if (min % stepSize != 0) {
            return (
            false,
            AppLocalizations.of(context)!.minOrderQtyDivisibleByStep,
            );
          }
        } else {
          // total is null / 0 / empty → no upper limit
          // Still need to check that min is compatible with step
          if (min % stepSize != 0) {
            return (
            false,
            AppLocalizations.of(context)!.minOrderQtyDivisibleByStep,
            );
          }
          // No other checks needed when there's no total cap
        }

        return (true, null);

      case 4:
        if (data.type == 'simple') {
          if (data.barcode == null || data.barcode!.trim().isEmpty) {
            return (false, AppLocalizations.of(context)!.barcodeRequired);
          }
          if (data.variants.isNotEmpty) {
            final v = data.variants.first;
            if (v.weight == null || v.weight!.trim().isEmpty) {
              return (false, AppLocalizations.of(context)!.weightRequired);
            }
            if (v.height == null || v.height!.trim().isEmpty) {
              return (false, AppLocalizations.of(context)!.heightRequired);
            }
            if (v.breadth == null || v.breadth!.trim().isEmpty) {
              return (false, AppLocalizations.of(context)!.breadthRequired);
            }
            if (v.length == null || v.length!.trim().isEmpty) {
              return (false, AppLocalizations.of(context)!.lengthRequired);
            }
          } else {
            // If variants is empty for a simple product, we still need dimensions.
            // However, in our current flow, simple products should have the dimension info
            // either in the first variant or we should rely on the main fields if they existed.
            // Since we sync dimensions to the first variant in ProductVariationStep,
            // an empty variants list here is an edge case that should be handled.
            return (false, AppLocalizations.of(context)!.dimensionsRequired);
          }
        } else {
          if (data.variants.isEmpty) {
            return (false, AppLocalizations.of(context)!.addAtLeastOneVariant);
          }
          bool hasDefault = false;
          for (var v in data.variants) {
            if (v.isDefault) hasDefault = true;
            if (v.name == null || v.name!.trim().isEmpty) {
              return (false, AppLocalizations.of(context)!.allVariantsMustHaveName);
            }
            if (v.barcode == null || v.barcode!.trim().isEmpty) {
              return (false, AppLocalizations.of(context)!.barcodeRequiredForAllVariants);
            }
            if (v.weight == null || v.weight!.trim().isEmpty) {
              return (false, AppLocalizations.of(context)!.weightRequiredForAllVariants);
            }
            if (v.height == null || v.height!.trim().isEmpty) {
              return (false, AppLocalizations.of(context)!.heightRequiredForAllVariants);
            }
            if (v.breadth == null || v.breadth!.trim().isEmpty) {
              return (false, AppLocalizations.of(context)!.breadthRequiredForAllVariants);
            }
            if (v.length == null || v.length!.trim().isEmpty) {
              return (false, AppLocalizations.of(context)!.lengthRequiredForAllVariants);
            }
          }
          if (!hasDefault) {
            return (false, AppLocalizations.of(context)!.selectAtLeastOneDefaultVariant);
          }
        }
        return (true, null);

      case 5:
        if (data.mainImage == null) {
          return (false, AppLocalizations.of(context)!.mainProductImageCompulsory);
        }
        return (true, null);

      case 6:
        if (data.shortDescription == null ||
            data.shortDescription!.trim().isEmpty) {
          return (false, AppLocalizations.of(context)!.shortDescriptionCompulsory);
        }
        if (data.description == null || _isHtmlEmpty(data.description!)) {
          return (false, AppLocalizations.of(context)!.fullDescriptionCompulsory);
        }
        return (true, null);

      case 7:
        if (data.storePricing.isEmpty) {
          return (false, AppLocalizations.of(context)!.selectAtLeastOneStore);
        }

        for (var sp in data.storePricing) {
          if (data.type == 'simple') {
            if (sp.price == null || sp.price!.trim().isEmpty) {
              return (false, AppLocalizations.of(context)!.priceRequiredForStore(sp.storeName));
            }
            // Price vs Special Price check
            final double? price = double.tryParse(sp.price!);
            final double? specialPrice =
                sp.specialPrice != null && sp.specialPrice!.isNotEmpty
                ? double.tryParse(sp.specialPrice!)
                : null;
            if (price != null && specialPrice != null && specialPrice > price) {
              return (
                false,
                AppLocalizations.of(context)!.specialPriceGreaterError(sp.storeName),
              );
            }
            if (sp.cost == null || sp.cost!.trim().isEmpty) {
              return (false, AppLocalizations.of(context)!.costRequiredForStore(sp.storeName));
            }
            if (sp.stock == null || sp.stock!.trim().isEmpty) {
              return (false, AppLocalizations.of(context)!.stockRequiredForStore(sp.storeName));
            }
            if (sp.sku == null || sp.sku!.trim().isEmpty) {
              return (false, AppLocalizations.of(context)!.skuRequiredForStore(sp.storeName));
            }
          } else {
            // For variants, we need to check variantStorePricing for this store
            final vps = data.variantStorePricing
                .where((vp) => vp.storeId == sp.storeId)
                .toList();
            if (vps.isEmpty) {
              return (false, AppLocalizations.of(context)!.pricingNotSetForStore(sp.storeName));
            }
            for (var vp in vps) {
              final variantName =
                  data.variants
                      .firstWhere(
                        (v) => v.id == vp.variantId,
                        orElse: () => VariantData(
                          title: "Unknown",
                          attributeValueIds: [],
                        ),
                      )
                      .name ??
                  "Unknown";
              if (vp.price == null || vp.price!.trim().isEmpty) {
                return (
                  false,
                  AppLocalizations.of(context)!.priceRequiredForStoreVariant(sp.storeName, variantName),
                );
              }
              if (vp.stock == null || vp.stock!.trim().isEmpty) {
                return (
                  false,
                  AppLocalizations.of(context)!.stockRequiredForStoreVariant(sp.storeName, variantName),
                );
              }
              if (vp.sku == null || vp.sku!.trim().isEmpty) {
                return (
                  false,
                  AppLocalizations.of(context)!.skuRequiredForStoreVariant(sp.storeName, variantName),
                );
              }
              if (vp.cost == null || vp.cost!.trim().isEmpty) {
                return (
                  false,
                  AppLocalizations.of(context)!.costRequiredForStoreVariant(sp.storeName, variantName),
                );
              }

              // Price vs Special Price check
              final double? price = double.tryParse(vp.price!);
              final double? specialPrice =
                  vp.specialPrice != null && vp.specialPrice!.isNotEmpty
                  ? double.tryParse(vp.specialPrice!)
                  : null;
              if (price != null &&
                  specialPrice != null &&
                  specialPrice > price) {
                return (
                  false,
                  AppLocalizations.of(context)!.specialPriceGreaterErrorVariant(sp.storeName, variantName),
                );
              }
            }
          }
        }
        return (true, null);

      default:
        return (true, null);
    }
  }

  bool _isHtmlEmpty(String html) {
    if (html.trim().isEmpty) return true;
    // Remove HTML tags and check if text remains
    final String plainText = html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    return plainText.isEmpty;
  }

  bool _isStepCompleted(int step, ProductData data) {
    return _validateStep(step, data).$1;
  }

  bool _canSubmit(ProductData data) {

    bool allGood = true;

    for (int i = 1; i <= _totalSteps; i++) {
      final ok = _isStepCompleted(i, data);
      if (!ok) {
        allGood = false;
      }
    }


    return allGood;
  }

  void _onAddProductPressed() {
    final bloc = context.read<AddProductBloc>();
    if (_canSubmit(bloc.state.productData)) {
      if (!DemoGuard.shouldProceed(context)) return;
      bloc.add(SubmitProduct());
    } else {
      showCustomSnackbar(
        context: context,
        message: AppLocalizations.of(
          context,
        )!.pleaseCompleteallRequiredFieldsInPreviousSteps,
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenType = context.screenType;
    return BlocListener<AddProductBloc, AddProductState>(
      listener: (context, state) {
        if (state is AddProductSubmitting || state is AddProductLoadingEdit) {
          if (!_isLoadingShowing) {
            _isLoadingShowing = true;
            UIUtilsDialogs.showLoadingDialog(context);
          }
        } else if (state is AddProductSuccess) {
          if (_isLoadingShowing) {
            Navigator.pop(context, true); // Close loading dialog
            _isLoadingShowing = false;
          }
          showCustomSnackbar(
            context: context,
            message: AppLocalizations.of(context)!.productAddedSuccessfully,
          );
          Navigator.pop(context, true);
        } else if (state is AddProductFailure ||
            state is AddProductUpdating ||
            state is AddProductInitial) {
          if (_isLoadingShowing) {
            Navigator.pop(context); // Close loading dialog
            _isLoadingShowing = false;
          }
          if (state is AddProductFailure) {
            log('AddProductFailure: ${state.error}');
            showCustomSnackbar(
              context: context,
              message: state.error,
              isError: true,
            );
          }
        }
      },
      child: CustomScaffold(
        title: widget.isEdit
            ? AppLocalizations.of(context)!.editProduct
            : AppLocalizations.of(context)!.addProduct,
        showAppbar: true,
        centerTitle: true,
        onBackTap: () => Navigator.of(context).pop(),
        body: Column(
          children: [
            AddProductHeader(
              currentStep: _currentStep,
              totalSteps: _totalSteps,
              stepTitle: _getStepTitle(context, _currentStep),
              onStepTap: () => _showStepBottomSheet(context),
              screenType: screenType,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: UIUtils.gapMD(screenType),
                ),
                child: _buildStepContent(_currentStep, screenType),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(UIUtils.gapMD(screenType)),
              child: Row(
                children: [
                  if (_currentStep > 1)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _onStepChanged(_currentStep - 1),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.previous,
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  if (_currentStep > 1)
                    SizedBox(width: UIUtils.gapMD(screenType)),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _onNextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentStep == _totalSteps
                            ? AppLocalizations.of(context)!.submit
                            : AppLocalizations.of(context)!.next,
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
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(int step, ScreenType screenType) {
    switch (step) {
      case 1:
        return const CategorySelectionStep();
      case 2:
        return const ProductInfoStep();
      case 3:
        return const PoliciesFeaturesStep();
      case 4:
        return const ProductVariationStep();
      case 5:
        return const ProductImagesStep();
      case 6:
        return const ProductDescriptionStep();
      case 7:
        return const PricingTaxesStep();
      default:
        return const SizedBox.shrink();
    }
  }

  void _showStepBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddProductProcessBottomSheet(
        currentStep: _currentStep,
        totalSteps: _totalSteps,
        onStepSelected: (step) {
          _onStepChanged(step);
          Navigator.pop(context);
        },
      ),
    );
  }
}
