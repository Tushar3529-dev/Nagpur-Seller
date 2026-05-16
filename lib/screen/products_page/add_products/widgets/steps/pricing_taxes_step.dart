// ignore_for_file: deprecated_member_use

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/bloc/stores_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/tax_group/bloc/tax_group_bloc.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/bloc/add_product_bloc/add_product_bloc.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/widgets/custom/custom_dropdown.dart';
import 'package:hyper_local_seller/widgets/custom/custom_textfield.dart';

class PricingTaxesStep extends StatefulWidget {
  const PricingTaxesStep({super.key});

  @override
  State<PricingTaxesStep> createState() => _PricingTaxesStepState();
}

class _PricingTaxesStepState extends State<PricingTaxesStep> {
  List<int> _selectedTaxGroupIds = [];
  final TextEditingController _storeSearchController = TextEditingController();
  final Set<int> _expandedStoreIds = {}; // Track expanded stores

  @override
  void initState() {
    super.initState();
    context.read<TaxGroupsBloc>().add(LoadTaxGroupsInitial());
    context.read<StoresBloc>().add(LoadStoresInitial());
    final productData = context.read<AddProductBloc>().state.productData;
    _selectedTaxGroupIds = List<int>.from(productData.taxGroupIds);
  }

  @override
  void dispose() {
    _storeSearchController.dispose();
    super.dispose();
  }

  void _showTaxGroupSelection(BuildContext context, List<dynamic> taxGroups) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.5,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
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
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Select Tax Groups",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "Done",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      itemCount: taxGroups.length,
                      itemBuilder: (context, index) {
                        final tax = taxGroups[index];
                        final isSelected =
                            _selectedTaxGroupIds.contains(tax.id);

                        return CheckboxListTile(
                          title: Text(tax.title),
                          value: isSelected,
                          activeColor: AppColors.primaryColor,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedTaxGroupIds.add(tax.id);
                              } else {
                                _selectedTaxGroupIds.remove(tax.id);
                              }
                            });
                            final bloc = context.read<AddProductBloc>();
                            bloc.add(
                              UpdateProductData(
                                bloc.state.productData.copyWith(
                                  taxGroupIds: _selectedTaxGroupIds,
                                ),
                              ),
                            );
                            setModalState(() {});
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _addStorePricing(int storeId, String storeName) {
    final bloc = context.read<AddProductBloc>();
    final data = bloc.state.productData;
    final currentPricing = List<StorePricing>.from(data.storePricing);

    if (currentPricing.any((p) => p.storeId == storeId)) return;

    currentPricing.add(StorePricing(storeId: storeId, storeName: storeName));

    // Initialize variant store pricing entries for this new store
    final currentVariantPricing = List<VariantStorePricing>.from(
      data.variantStorePricing,
    );
    if (data.type == 'variant') {
      for (var variant in data.variants) {
        if (variant.id != null) {
          currentVariantPricing.add(
            VariantStorePricing(storeId: storeId, variantId: variant.id!),
          );
        }
      }
    }

    bloc.add(
      UpdateProductData(
        data.copyWith(
          storePricing: currentPricing,
          variantStorePricing: currentVariantPricing,
        ),
      ),
    );
    setState(() {});
  }

  void _removeStorePricing(int storeId) {
    final bloc = context.read<AddProductBloc>();
    final data = bloc.state.productData;

    final currentPricing = List<StorePricing>.from(data.storePricing);
    currentPricing.removeWhere((p) => p.storeId == storeId);

    final currentVariantPricing = List<VariantStorePricing>.from(
      data.variantStorePricing,
    );
    currentVariantPricing.removeWhere((p) => p.storeId == storeId);

    bloc.add(
      UpdateProductData(
        data.copyWith(
          storePricing: currentPricing,
          variantStorePricing: currentVariantPricing,
        ),
      ),
    );
    setState(() {});
  }

  void _updateStorePricing(
      int storeId, {
        String? price,
        String? specialPrice,
        String? cost,
        String? stock,
        String? sku,
      }) {
    final bloc = context.read<AddProductBloc>();
    final currentPricing = List<StorePricing>.from(
      bloc.state.productData.storePricing,
    );
    final index = currentPricing.indexWhere((p) => p.storeId == storeId);

    if (index != -1) {
      currentPricing[index] = currentPricing[index].copyWith(
        price: price,
        specialPrice: specialPrice,
        cost: cost,
        stock: stock,
        sku: sku,
      );
      bloc.add(
        UpdateProductData(
          bloc.state.productData.copyWith(storePricing: currentPricing),
        ),
      );
    }
  }

  void _updateVariantStorePricing(
      int storeId,
      String variantId, {
        String? price,
        String? specialPrice,
        String? cost,
        String? stock,
        String? sku,
      }) {
    final bloc = context.read<AddProductBloc>();
    final currentPricing = List<VariantStorePricing>.from(
      bloc.state.productData.variantStorePricing,
    );
    int index = currentPricing.indexWhere(
          (p) => p.storeId == storeId && p.variantId == variantId,
    );

    if (index != -1) {
      currentPricing[index] = currentPricing[index].copyWith(
        price: price,
        specialPrice: specialPrice,
        cost: cost,
        stock: stock,
        sku: sku,
      );
    } else {
      currentPricing.add(
        VariantStorePricing(
          storeId: storeId,
          variantId: variantId,
          price: price,
          specialPrice: specialPrice,
          cost: cost,
          stock: stock,
          sku: sku,
        ),
      );
    }
    bloc.add(
      UpdateProductData(
        bloc.state.productData.copyWith(variantStorePricing: currentPricing),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenType = context.screenType;
    final productData = context.watch<AddProductBloc>().state.productData;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlocBuilder<TaxGroupsBloc, TaxGroupsState>(
          builder: (context, state) {
            final selectedTaxes = state.items
                .where((tax) => _selectedTaxGroupIds.contains(tax.id))
                .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Tax Group",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => _showTaxGroupSelection(context, state.items),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF0D1117)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade700
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedTaxes.isEmpty
                                ? "Select Tax Group"
                                : selectedTaxes.map((t) => t.title).join(", "),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: selectedTaxes.isEmpty
                                  ? Colors.grey.shade500
                                  : null,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 10),
        const Text(
          "Leave empty for zero tax",
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        // const SizedBox(height: 5),
        // const Text(
        //   "You can select multiple tags",
        //   style: TextStyle(fontSize: 12, color: Colors.blueGrey),
        // ),
        const SizedBox(height: 30),

        Text(
          "Store Pricing",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          "Set pricing for each store",
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 15),

        GestureDetector(
          onTap: () => _showMultiStoreSelection(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF0D1117)
                  : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade700
                    : Colors.grey.shade300,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    productData.storePricing.isEmpty
                        ? AppLocalizations.of(context)!.searchAndSelectStores
                        : productData.storePricing
                        .map((p) => p.storeName)
                        .join(", "),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: productData.storePricing.isEmpty
                          ? Colors.grey.shade500
                          : null,
                      fontSize: 15,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),

        if (productData.storePricing.isNotEmpty)
          ...productData.storePricing
              .map(
                (pricing) => _buildStoreCard(pricing, screenType, productData),
          )
              ,

        const SizedBox(height: 20),
      ],
    );
  }

  void _showMultiStoreSelection(BuildContext context) {
    final storesBloc = context.read<StoresBloc>();
    final addProductBloc = context.read<AddProductBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return BlocBuilder<StoresBloc, StoresState>(
              bloc: storesBloc,
              builder: (context, storesState) {
                return Container(
                  height: MediaQuery.of(context).size.height * 0.5,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
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
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Select Stores",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                "Done",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: CustomTextField(
                          controller: _storeSearchController,
                          hint: "Search stores...",
                          prefixIcon: const Icon(Icons.search),
                          onChanged: (v) => setModalState(() {}),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Divider(height: 1),
                      if (storesState.isInitialLoading)
                        const Expanded(
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (storesState.items.isEmpty)
                        Expanded(
                          child: Center(child: Text(AppLocalizations.of(context)!.noStoresFound)),
                        )
                      else
                        Expanded(
                          child: BlocBuilder<AddProductBloc, AddProductState>(
                            bloc: addProductBloc,
                            builder: (context, addProductState) {
                              final currentPricing =
                                  addProductState.productData.storePricing;
                              final filteredStores = storesState.items
                                  .where(
                                    (s) =>
                                    (s.name).toLowerCase().contains(
                                      _storeSearchController.text
                                          .toLowerCase(),
                                    ),
                              )
                                  .toList();

                              return ListView.builder(
                                itemCount: filteredStores.length,
                                padding: const EdgeInsets.only(bottom: 20),
                                itemBuilder: (context, index) {
                                  final store = filteredStores[index];
                                  final isSelected = currentPricing.any(
                                        (p) => p.storeId == store.id,
                                  );

                                  return CheckboxListTile(
                                    title: Text(
                                      store.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    value: isSelected,
                                    activeColor: AppColors.primaryColor,
                                    controlAffinity:
                                    ListTileControlAffinity.trailing,
                                    onChanged: (bool? value) {
                                      if (value == true) {
                                        _addStorePricing(
                                          store.id,
                                          store.name,
                                        );
                                      } else {
                                        _removeStorePricing(store.id);
                                      }
                                      setModalState(
                                            () {},
                                      ); // Force local update for checkbox
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    ).then((_) => _storeSearchController.clear());
  }

  Widget _buildStoreCard(
      StorePricing pricing,
      ScreenType screenType,
      ProductData productData,
      ) {
    final isExpanded = _expandedStoreIds.contains(pricing.storeId);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStoreCardHeader(pricing, isExpanded),
          if (isExpanded) ...[
            const Divider(height: 1),
            if (productData.type == 'simple')
              _buildSimplePricingUI(pricing)
            else
              _buildVariantPricingUI(pricing, productData),
          ],
        ],
      ),
    );
  }

  Widget _buildStoreCardHeader(StorePricing pricing, bool isExpanded) {
    return InkWell(
      onTap: () {
        setState(() {
          if (isExpanded) {
            _expandedStoreIds.remove(pricing.storeId);
          } else {
            _expandedStoreIds.add(pricing.storeId);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha:0.05)
              : Colors.grey.withValues(alpha:0.05),
          borderRadius: BorderRadius.vertical(
            top: const Radius.circular(8),
            bottom: Radius.circular(isExpanded ? 0 : 8),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                pricing.storeName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 24,
              ),
              onPressed: () => _removeStorePricing(pricing.storeId),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
            const SizedBox(width: 8),
            Icon(
              isExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimplePricingUI(StorePricing pricing) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMiniField(
            AppLocalizations.of(context)!.price,
            pricing.price,
            (v) => _updateStorePricing(pricing.storeId, price: v),
            isRequired: true,
          ),
          const SizedBox(height: 16),
          _buildMiniField(
            AppLocalizations.of(context)!.specialPrice,
            pricing.specialPrice,
                (v) => _updateStorePricing(pricing.storeId, specialPrice: v),
          ),
          const SizedBox(height: 16),
          _buildMiniField(
            AppLocalizations.of(context)!.cost,
            pricing.cost,
            (v) => _updateStorePricing(pricing.storeId, cost: v),
            isRequired: true,
          ),
          const SizedBox(height: 16),
          _buildMiniField(
            showPrefix: false,
            AppLocalizations.of(context)!.stock,
            pricing.stock,
            (v) => _updateStorePricing(pricing.storeId, stock: v),
            isRequired: true,
          ),
          const SizedBox(height: 16),
          _buildMiniField(
            AppLocalizations.of(context)!.sku,
            pricing.sku,
            (v) => _updateStorePricing(pricing.storeId, sku: v),
            showPrefix: false,
            isRequired: true,
          ),
        ],
      ),
    );
  }

  Widget _buildVariantPricingUI(StorePricing pricing, ProductData productData) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...productData.variants.map((variant) {
            final vPricing = productData.variantStorePricing.firstWhere(
                  (vp) =>
              vp.storeId == pricing.storeId && vp.variantId == variant.id,
              orElse: () => VariantStorePricing(
                storeId: pricing.storeId,
                variantId: variant.id!,
              ),
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Variant chip label
                _buildVariantChip(variant),
                const SizedBox(height: 12),

                // Price fields stacked vertically
                _buildMiniField(
                  AppLocalizations.of(context)!.price,
                  vPricing.price,
                  (v) => _updateVariantStorePricing(
                    pricing.storeId,
                    variant.id!,
                    price: v,
                  ),
                  isRequired: true,
                ),
                const SizedBox(height: 16),
                _buildMiniField(
                  AppLocalizations.of(context)!.specialPrice,
                  vPricing.specialPrice,
                      (v) => _updateVariantStorePricing(
                    pricing.storeId,
                    variant.id!,
                    specialPrice: v,
                  ),
                ),
                const SizedBox(height: 16),
                _buildMiniField(
                  AppLocalizations.of(context)!.cost,
                  vPricing.cost,
                  (v) => _updateVariantStorePricing(
                    pricing.storeId,
                    variant.id!,
                    cost: v,
                  ),
                  isRequired: true,
                ),
                const SizedBox(height: 16),
                _buildMiniField(
                  AppLocalizations.of(context)!.stock,
                  vPricing.stock,
                  (v) => _updateVariantStorePricing(
                    pricing.storeId,
                    variant.id!,
                    stock: v,
                  ),
                  showPrefix: false,
                  isRequired: true,
                ),
                const SizedBox(height: 16),
                _buildMiniField(
                  AppLocalizations.of(context)!.sku,
                  vPricing.sku,
                  (v) => _updateVariantStorePricing(
                    pricing.storeId,
                    variant.id!,
                    sku: v,
                  ),
                  showPrefix: false,
                  isRequired: true,
                ),
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 16),
              ],
            );
          }),
        ],
      ),
    );
  }


  Widget _buildVariantChip(VariantData variant) {
    if (variant.attributes.isEmpty) {
      return Text(variant.title, style: const TextStyle(fontSize: 12));
    }
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: variant.attributes.map((attr) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Text(
            "${attr['attribute_name']}: ${attr['value_name']}",
            style: TextStyle(
              fontSize: 10,
              color: Colors.blue.shade900,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMiniField(
    String? label,
    String? value,
    ValueChanged<String> onChanged, {
    bool showPrefix = true,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          RichText(
            text: TextSpan(
              text: label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.tertiary,
              ),
              children: [
                if (isRequired)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
        ],
        CustomTextField(
          controller: TextEditingController(text: value)
            ..selection = TextSelection.fromPosition(
              TextPosition(offset: value?.length ?? 0),
            ),
          prefixIcon: showPrefix
              ? Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            child: Text(
              HiveStorage.currencySymbol,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
              : null,
          onChanged: onChanged,
          keyboardType: label == AppLocalizations.of(context)!.sku
              ? TextInputType.text
              : TextInputType.number,
        ),
      ],
    );
  }
}

/*
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/bloc/stores_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/tax_group/bloc/tax_group_bloc.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/bloc/add_product_bloc/add_product_bloc.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/widgets/custom_dropdown.dart';
import 'package:hyper_local_seller/widgets/custom/custom_textfield.dart';

class PricingTaxesStep extends StatefulWidget {
  const PricingTaxesStep({super.key});

  @override
  State<PricingTaxesStep> createState() => _PricingTaxesStepState();
}

class _PricingTaxesStepState extends State<PricingTaxesStep> {
  int? _selectedTaxGroupId;
  final TextEditingController _storeSearchController = TextEditingController();
  final Set<int> _expandedStoreIds = {}; // Track expanded stores

  @override
  void initState() {
    super.initState();
    context.read<TaxGroupsBloc>().add(LoadTaxGroupsInitial());
    context.read<StoresBloc>().add(LoadStoresInitial());
    final productData = context.read<AddProductBloc>().state.productData;
    _selectedTaxGroupId = productData.taxGroupId;
  }

  @override
  void dispose() {
    _storeSearchController.dispose();
    super.dispose();
  }

  void _addStorePricing(int storeId, String storeName) {
    final bloc = context.read<AddProductBloc>();
    final data = bloc.state.productData;
    final currentPricing = List<StorePricing>.from(data.storePricing);

    if (currentPricing.any((p) => p.storeId == storeId)) return;

    currentPricing.add(StorePricing(storeId: storeId, storeName: storeName));

    // Initialize variant store pricing entries for this new store
    final currentVariantPricing = List<VariantStorePricing>.from(
      data.variantStorePricing,
    );
    if (data.type == 'variant') {
      for (var variant in data.variants) {
        if (variant.id != null) {
          currentVariantPricing.add(
            VariantStorePricing(storeId: storeId, variantId: variant.id!),
          );
        }
      }
    }

    bloc.add(
      UpdateProductData(
        data.copyWith(
          storePricing: currentPricing,
          variantStorePricing: currentVariantPricing,
        ),
      ),
    );
    setState(() {});
  }

  void _removeStorePricing(int storeId) {
    final bloc = context.read<AddProductBloc>();
    final data = bloc.state.productData;

    final currentPricing = List<StorePricing>.from(data.storePricing);
    currentPricing.removeWhere((p) => p.storeId == storeId);

    final currentVariantPricing = List<VariantStorePricing>.from(
      data.variantStorePricing,
    );
    currentVariantPricing.removeWhere((p) => p.storeId == storeId);

    bloc.add(
      UpdateProductData(
        data.copyWith(
          storePricing: currentPricing,
          variantStorePricing: currentVariantPricing,
        ),
      ),
    );
    setState(() {});
  }

  void _updateStorePricing(
    int storeId, {
    String? price,
    String? specialPrice,
    String? cost,
    String? stock,
    String? sku,
  }) {
    final bloc = context.read<AddProductBloc>();
    final currentPricing = List<StorePricing>.from(
      bloc.state.productData.storePricing,
    );
    final index = currentPricing.indexWhere((p) => p.storeId == storeId);

    if (index != -1) {
      currentPricing[index] = currentPricing[index].copyWith(
        price: price,
        specialPrice: specialPrice,
        cost: cost,
        stock: stock,
        sku: sku,
      );
      bloc.add(
        UpdateProductData(
          bloc.state.productData.copyWith(storePricing: currentPricing),
        ),
      );
    }
  }

  void _updateVariantStorePricing(
    int storeId,
    String variantId, {
    String? price,
    String? specialPrice,
    String? cost,
    String? stock,
    String? sku,
  }) {
    final bloc = context.read<AddProductBloc>();
    final currentPricing = List<VariantStorePricing>.from(
      bloc.state.productData.variantStorePricing,
    );
    int index = currentPricing.indexWhere(
      (p) => p.storeId == storeId && p.variantId == variantId,
    );

    if (index != -1) {
      currentPricing[index] = currentPricing[index].copyWith(
        price: price,
        specialPrice: specialPrice,
        cost: cost,
        stock: stock,
        sku: sku,
      );
    } else {
      currentPricing.add(
        VariantStorePricing(
          storeId: storeId,
          variantId: variantId,
          price: price,
          specialPrice: specialPrice,
          cost: cost,
          stock: stock,
          sku: sku,
        ),
      );
    }
    bloc.add(
      UpdateProductData(
        bloc.state.productData.copyWith(variantStorePricing: currentPricing),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenType = context.screenType;
    final productData = context.watch<AddProductBloc>().state.productData;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlocBuilder<TaxGroupsBloc, TaxGroupsState>(
          builder: (context, state) {
            return CustomDropdown<int>(
              label: "Tax Group",
              isRequired: false,
              hint: "Select Tax Group",
              value: _selectedTaxGroupId,
              items: state.items
                  .map(
                    (tax) =>
                        CustomDropdownItem(label: tax.title, value: tax.id),
                  )
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _selectedTaxGroupId = val;
                });
                final bloc = context.read<AddProductBloc>();
                bloc.add(
                  UpdateProductData(
                    bloc.state.productData.copyWith(taxGroupId: val),
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 10),
        const Text(
          "Leave empty for zero tax",
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 5),
        const Text(
          "You can select multiple tags",
          style: TextStyle(fontSize: 12, color: Colors.blueGrey),
        ),
        const SizedBox(height: 30),

        Text(
          "Store Pricing",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          "Set pricing for each store",
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 15),

        GestureDetector(
          onTap: () => _showMultiStoreSelection(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF0D1117)
                  : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade700
                    : Colors.grey.shade300,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    productData.storePricing.isEmpty
                        ? "Search and select stores"
                        : productData.storePricing
                            .map((p) => p.storeName)
                            .join(", "),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: productData.storePricing.isEmpty
                          ? Colors.grey.shade500
                          : null,
                      fontSize: 15,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),

        if (productData.storePricing.isNotEmpty)
          ...productData.storePricing
              .map(
                (pricing) => _buildStoreCard(pricing, screenType, productData),
              )
              .toList(),

        const SizedBox(height: 20),
      ],
    );
  }

  void _showMultiStoreSelection(BuildContext context) {
    final storesBloc = context.read<StoresBloc>();
    final addProductBloc = context.read<AddProductBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return BlocBuilder<StoresBloc, StoresState>(
              bloc: storesBloc,
              builder: (context, storesState) {
                return Container(
                  height: MediaQuery.of(context).size.height * 0.5,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
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
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Select Stores",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                "Done",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: CustomTextField(
                          controller: _storeSearchController,
                          hint: "Search stores...",
                          prefixIcon: const Icon(Icons.search),
                          onChanged: (v) => setModalState(() {}),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Divider(height: 1),
                      if (storesState.isInitialLoading)
                        const Expanded(
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (storesState.items.isEmpty)
                        const Expanded(
                          child: Center(child: Text("No stores found")),
                        )
                      else
                        Expanded(
                          child: BlocBuilder<AddProductBloc, AddProductState>(
                            bloc: addProductBloc,
                            builder: (context, addProductState) {
                              final currentPricing =
                                  addProductState.productData.storePricing;
                              final filteredStores = storesState.items
                                  .where(
                                    (s) =>
                                        (s.name ?? "").toLowerCase().contains(
                                          _storeSearchController.text
                                              .toLowerCase(),
                                        ),
                                  )
                                  .toList();

                              return ListView.builder(
                                itemCount: filteredStores.length,
                                padding: const EdgeInsets.only(bottom: 20),
                                itemBuilder: (context, index) {
                                  final store = filteredStores[index];
                                  final isSelected = currentPricing.any(
                                    (p) => p.storeId == store.id,
                                  );

                                  return CheckboxListTile(
                                    title: Text(
                                      store.name ?? "Store",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    value: isSelected,
                                    activeColor: AppColors.primaryColor,
                                    controlAffinity:
                                        ListTileControlAffinity.trailing,
                                    onChanged: (bool? value) {
                                      if (value == true) {
                                        _addStorePricing(
                                          store.id!,
                                          store.name ?? "Store",
                                        );
                                      } else {
                                        _removeStorePricing(store.id!);
                                      }
                                      setModalState(
                                        () {},
                                      ); // Force local update for checkbox
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    ).then((_) => _storeSearchController.clear());
  }

  Widget _buildStoreCard(
    StorePricing pricing,
    ScreenType screenType,
    ProductData productData,
  ) {
    final isExpanded = _expandedStoreIds.contains(pricing.storeId);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStoreCardHeader(pricing, isExpanded),
          if (isExpanded) ...[
            const Divider(height: 1),
            if (productData.type == 'simple')
              _buildSimplePricingUI(pricing)
            else
              _buildVariantPricingUI(pricing, productData),
          ],
        ],
      ),
    );
  }

  Widget _buildStoreCardHeader(StorePricing pricing, bool isExpanded) {
    return InkWell(
      onTap: () {
        setState(() {
          if (isExpanded) {
            _expandedStoreIds.remove(pricing.storeId);
          } else {
            _expandedStoreIds.add(pricing.storeId);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha:0.05)
              : Colors.grey.withValues(alpha:0.05),
          borderRadius: BorderRadius.vertical(
            top: const Radius.circular(8),
            bottom: Radius.circular(isExpanded ? 0 : 8),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                pricing.storeName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
            IconButton(
              icon:
                  const Icon(Icons.delete_outline, color: Colors.red, size: 24),
              onPressed: () => _removeStorePricing(pricing.storeId),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
            const SizedBox(width: 8),
            Icon(
              isExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimplePricingUI(StorePricing pricing) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = (constraints.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 16,
            children: [
              _buildMiniField(
                "PRICE",
                pricing.price,
                (v) => _updateStorePricing(pricing.storeId, price: v),
                width: itemWidth,
              ),
              _buildMiniField(
                "SPECIAL PRICE",
                pricing.specialPrice,
                (v) => _updateStorePricing(pricing.storeId, specialPrice: v),
                width: itemWidth,
              ),
              _buildMiniField(
                "COST",
                pricing.cost,
                (v) => _updateStorePricing(pricing.storeId, cost: v),
                width: itemWidth,
              ),
              _buildMiniField(
                "STOCK",
                pricing.stock,
                (v) => _updateStorePricing(pricing.storeId, stock: v),
                width: itemWidth,
              ),
              _buildMiniField(
                "SKU",
                pricing.sku,
                (v) => _updateStorePricing(pricing.storeId, sku: v),
                showPrefix: false,
                width: constraints.maxWidth,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildVariantPricingUI(StorePricing pricing, ProductData productData) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                _buildHeaderCell("VARIANT", width: 150),
                _buildHeaderCell("PRICE", width: 100),
                _buildHeaderCell("SPECIAL PRICE", width: 100),
                _buildHeaderCell("COST", width: 100),
                _buildHeaderCell("STOCK", width: 100),
                _buildHeaderCell("SKU", width: 150),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            // Variant Rows
            ...productData.variants.map((variant) {
              final vPricing = productData.variantStorePricing.firstWhere(
                (vp) =>
                    vp.storeId == pricing.storeId && vp.variantId == variant.id,
                orElse: () => VariantStorePricing(
                  storeId: pricing.storeId,
                  variantId: variant.id!,
                ),
              );

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    SizedBox(width: 150, child: _buildVariantChip(variant)),
                    const SizedBox(width: 8),
                    _buildMiniField(null, vPricing.price,
                        (v) => _updateVariantStorePricing(pricing.storeId, variant.id!, price: v),
                        width: 100),
                    const SizedBox(width: 8),
                    _buildMiniField(null, vPricing.specialPrice,
                        (v) => _updateVariantStorePricing(pricing.storeId, variant.id!, specialPrice: v),
                        width: 100),
                    const SizedBox(width: 8),
                    _buildMiniField(null, vPricing.cost,
                        (v) => _updateVariantStorePricing(pricing.storeId, variant.id!, cost: v),
                        width: 100),
                    const SizedBox(width: 8),
                    _buildMiniField(null, vPricing.stock,
                        (v) => _updateVariantStorePricing(pricing.storeId, variant.id!, stock: v),
                        width: 100),
                    const SizedBox(width: 8),
                    _buildMiniField(null, vPricing.sku,
                        (v) => _updateVariantStorePricing(pricing.storeId, variant.id!, sku: v),
                        showPrefix: false, width: 150),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String label, {double? width}) {
    return SizedBox(
      width: width,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildVariantChip(VariantData variant) {
    if (variant.attributes.isEmpty) {
      return Text(variant.title, style: const TextStyle(fontSize: 12));
    }
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: variant.attributes.map((attr) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Text(
            "${attr['attribute_name']}: ${attr['value_name']}",
            style: TextStyle(fontSize: 10, color: Colors.blue.shade900, fontWeight: FontWeight.w500),
          ),
        );
      }).toList(),
    );
  }

  Widget _vDivider() =>
      Container(width: 1, height: 40, color: Colors.grey.shade200);

  Widget _buildMiniField(
    String? label,
    String? value,
    ValueChanged<String> onChanged, {
    bool showPrefix = true,
    double? width,
  }) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
          ],
          CustomTextField(
            controller: TextEditingController(text: value)
              ..selection = TextSelection.fromPosition(
                TextPosition(offset: value?.length ?? 0),
              ),
            prefixIcon: showPrefix
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 12),
                    child: Text(
                      "\$",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
            onChanged: onChanged,
            keyboardType:
                label == "SKU" ? TextInputType.text : TextInputType.number,
          ),
        ],
      ),
    );
  }
}
*/
