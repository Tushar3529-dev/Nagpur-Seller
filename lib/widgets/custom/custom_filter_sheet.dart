import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/bloc/stores_bloc.dart';
import 'package:hyper_local_seller/screen/order_page/bloc/order_filters_bloc/order_filters_bloc.dart';
import 'package:hyper_local_seller/screen/order_page/bloc/orders/orders_bloc.dart';
import 'package:hyper_local_seller/screen/products_page/products/bloc/products_bloc/products_bloc.dart';
import 'package:hyper_local_seller/widgets/custom/custom_buttons.dart';
import 'package:hyper_local_seller/widgets/custom/custom_card.dart';
import 'package:hyper_local_seller/extensions/l10n_extensions.dart';
import 'package:hyper_local_seller/widgets/custom/custom_loading_indicator.dart';

enum FilterType { order, product, store }

class FilterSheet extends StatefulWidget {
  final FilterType type;
  const FilterSheet({super.key, this.type = FilterType.order});

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  // Order filters
  String? _selectedDateRange;
  String? _paymentType;
  String? _orderStatus;

  // Product filters
  String? _productType;
  String? _productStatus;
  String? _productVerificationStatus;
  String? _productFilter;

  // Store filters
  String? _storeStatus;
  String? _storeVisibility;
  String? _storeVerification;

  @override
  void initState() {
    super.initState();
    _initializeFilters();
  }

  void _initializeFilters() {
    switch (widget.type) {
      case FilterType.order:
        final state = context.read<OrdersBloc>().state;
        _selectedDateRange = state.range;
        _paymentType = state.paymentType;
        _orderStatus = state.status;
        break;
      case FilterType.product:
        final state = context.read<ProductsBloc>().state;
        _productType = state.selectedType;
        _productStatus = state.selectedStatus;
        _productVerificationStatus = state.selectedVerificationStatus;
        _productFilter = state.selectedProductFilter;
        context.read<ProductsBloc>().add(LoadProductFilters());
        break;
      case FilterType.store:
        final state = context.read<StoresBloc>().state;
        _storeStatus = state.selectedStatus;
        _storeVisibility = state.selectedVisibilityStatus;
        _storeVerification = state.selectedVerificationStatus;
        context.read<StoresBloc>().add(LoadStoreFilters());
        break;
    }
  }

  @override
  Widget build(BuildContext context) {

    final l10n = AppLocalizations.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n?.filters ?? 'Filters',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: _buildFilterSections(l10n),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      text: l10n?.clear ?? 'Clear',
                      onPressed: _onClear,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: PrimaryButton(
                      text: l10n?.apply ?? 'Apply',
                      onPressed: _onApply,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildFilterSections(AppLocalizations? l10n) {
    switch (widget.type) {
      case FilterType.order:
        return _buildOrderFilters(l10n);
      case FilterType.product:
        return _buildProductFilters(l10n);
      case FilterType.store:
        return _buildStoreFilters(l10n);
    }
  }

  List<Widget> _buildOrderFilters(AppLocalizations? l10n) {
    return [
      BlocBuilder<OrderFiltersBloc, OrderFiltersState>(
        builder: (context, state) {
          if (state is OrderFiltersLoading) {
            return const Center(child: CustomLoadingIndicator());
          }
          if (state is OrderFiltersLoaded) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Range Filter
                if (state.filters.range != null &&
                    state.filters.range!.isNotEmpty) ...[
                  _buildSectionTitle(l10n?.dateRange ?? 'Date Range'),
                  Wrap(
                    spacing: 8,
                    children: state.filters.range!.map((range) {
                      final label = l10n?.translateEnum(range) ?? range;
                      return ChoiceChip(
                        label: Text(label),
                        selected: _selectedDateRange == range,
                        onSelected: (selected) => setState(
                          () => _selectedDateRange = selected ? range : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Payment Type Filter
                if (state.filters.paymentType != null &&
                    state.filters.paymentType!.isNotEmpty) ...[
                  _buildSectionTitle(l10n?.paymentType ?? 'Payment Type'),
                  Wrap(
                    spacing: 8,
                    children: state.filters.paymentType!.map((type) {
                      final label = capitalizeWords(type.replaceAll('_', ' '));
                      return ChoiceChip(
                        label: Text(label),
                        selected: _paymentType == type,
                        onSelected: (selected) => setState(
                          () => _paymentType = selected ? type : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Status Filter
                if (state.filters.status != null &&
                    state.filters.status!.isNotEmpty) ...[
                  _buildSectionTitle(l10n?.status ?? 'Status'),
                  Wrap(
                    spacing: 8,
                    children: state.filters.status!.map((status) {
                      final label = l10n?.translateEnum(status) ?? status;
                      return ChoiceChip(
                        label: Text(label),
                        selected: _orderStatus == status,
                        onSelected: (selected) => setState(
                          () => _orderStatus = selected ? status : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            );
          }
          if (state is OrderFiltersError) {
            return const Center(child: CustomLoadingIndicator());
          }
          return const SizedBox.shrink();
        },
      ),
    ];
  }

  List<Widget> _buildProductFilters(AppLocalizations? l10n) {
    return [
      BlocBuilder<ProductsBloc, ProductsState>(
        builder: (context, state) {
          final options = state.filterOptions;
          if (options == null) {
            return const Center(child: CustomLoadingIndicator());
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (options.type != null) ...[
                _buildSectionTitle(l10n?.type ?? 'Type'),
                _buildChipGroup(
                  options.type!,
                  _productType,
                  (val) => setState(() => _productType = val),
                ),
                const SizedBox(height: 16),
              ],
              if (options.status != null) ...[
                _buildSectionTitle(l10n?.status ?? 'Status'),
                _buildChipGroup(
                  options.status!,
                  _productStatus,
                  (val) => setState(() => _productStatus = val),
                ),
                const SizedBox(height: 16),
              ],
              if (options.verificationStatus != null) ...[
                _buildSectionTitle(l10n?.verificationStatus ?? 'Verification Status'),
                _buildChipGroup(
                  options.verificationStatus!,
                  _productVerificationStatus,
                  (val) => setState(() => _productVerificationStatus = val),
                ),
                const SizedBox(height: 16),
              ],
              if (options.productFilter != null) ...[
                _buildSectionTitle(l10n?.productFilterLabel ?? 'Product Filter'),
                _buildChipGroup(
                  options.productFilter!,
                  _productFilter,
                  (val) => setState(() => _productFilter = val),
                ),
                const SizedBox(height: 16),
              ],
            ],
          );
        },
      ),
    ];
  }

  List<Widget> _buildStoreFilters(AppLocalizations? l10n) {
    return [
      BlocBuilder<StoresBloc, StoresState>(
        builder: (context, state) {
          final options = state.filterOptions;
          if (options == null) {
            return const Center(child: CustomLoadingIndicator());
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (options.status != null) ...[
                _buildSectionTitle(l10n?.status ?? 'Status'),
                _buildChipGroup(
                  options.status!,
                  _storeStatus,
                  (val) => setState(() => _storeStatus = val),
                ),
                const SizedBox(height: 16),
              ],
              if (options.visibilityStatus != null) ...[
                _buildSectionTitle(l10n?.visibility ?? 'Visibility'),
                _buildChipGroup(
                  options.visibilityStatus!,
                  _storeVisibility,
                  (val) => setState(() => _storeVisibility = val),
                ),
                const SizedBox(height: 16),
              ],
              if (options.verificationStatus != null) ...[
                _buildSectionTitle(l10n?.verificationStatus ?? 'Verification Status'),
                _buildChipGroup(
                  options.verificationStatus!,
                  _storeVerification,
                  (val) => setState(() => _storeVerification = val),
                ),
              ],
            ],
          );
        },
      ),
    ];
  }

  Widget _buildChipGroup(
    List<String> items,
    String? selectedValue,
    ValueChanged<String?> onSelected,
  ) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      children: items.map((item) {
        return ChoiceChip(
          label: Text(l10n?.translateEnum(item) ?? item),
          selected: selectedValue == item,
          onSelected: (selected) => onSelected(selected ? item : null),
        );
      }).toList(),
    );
  }

  void _onClear() {
    switch (widget.type) {
      case FilterType.order:
        context.read<OrdersBloc>().add(ClearFilters());
        break;
      case FilterType.product:
        context.read<ProductsBloc>().add(ApplyProductFilter());
        break;
      case FilterType.store:
        context.read<StoresBloc>().add(ApplyStoreFilter());
        break;
    }
    Navigator.pop(context);
  }

  void _onApply() {
    switch (widget.type) {
      case FilterType.order:
        context.read<OrdersBloc>().add(
          ApplyFilter(
            range: _selectedDateRange,
            paymentType: _paymentType,
            status: _orderStatus,
          ),
        );
        break;
      case FilterType.product:
        context.read<ProductsBloc>().add(
          ApplyProductFilter(
            type: _productType,
            status: _productStatus,
            verificationStatus: _productVerificationStatus,
            productFilter: _productFilter,
          ),
        );
        break;
      case FilterType.store:
        context.read<StoresBloc>().add(
          ApplyStoreFilter(
            status: _storeStatus,
            visibilityStatus: _storeVisibility,
            verificationStatus: _storeVerification,
          ),
        );
        break;
    }
    Navigator.pop(context);
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
