import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/screen/more_page/view/brands/bloc/brands_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/brands/model/brands_model.dart';
import 'package:hyper_local_seller/utils/image_path.dart';
import 'package:hyper_local_seller/widgets/custom/custom_textfield.dart';
import 'package:hyper_local_seller/widgets/custom/custom_loading_indicator.dart';
import 'package:hyper_local_seller/widgets/ui/empty_state_widget.dart';

class BrandSelectionSheet extends StatefulWidget {
  final int? selectedBrandId;
  final Function(Brand) onSelected;

  const BrandSelectionSheet({
    super.key,
    this.selectedBrandId,
    required this.onSelected,
  });

  @override
  State<BrandSelectionSheet> createState() => _BrandSelectionSheetState();
}

class _BrandSelectionSheetState extends State<BrandSelectionSheet> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Use smaller perPage if requested, but BLoC is already providing brands.
    // We'll just use the BLoC's current state.
    context.read<BrandsBloc>().add(LoadBrandsInitial());
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<BrandsBloc>().add(LoadMoreBrands());
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<BrandsBloc>().add(SearchBrands(query));
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.selectBrand,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: CustomTextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              hint: AppLocalizations.of(context)!.searchBrand,
              prefixIcon: const Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          Expanded(
            child: BlocBuilder<BrandsBloc, BrandsState>(
              builder: (context, state) {
                if (state.isInitialLoading) {
                  return const Center(child: CustomLoadingIndicator());
                }

                if (state.items.isEmpty) {
                  return Center(
                    child: EmptyStateWidget(
                      svgPath: ImagesPath.noProductFoundSvg,
                      title: 'No Brands Found',
                      subtitle: 'There is not any brand available.',
                      actionText: 'Refresh',
                      onAction: () {
                        context.read<BrandsBloc>().add(LoadBrandsInitial());
                      },
                    ),
                  );
                }

                return ListView.separated(
                  controller: _scrollController,
                  itemCount: state.items.length + (state.hasMore ? 1 : 0),
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    if (index == state.items.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CustomLoadingIndicator(
                            size: 20,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    }

                    final brand = state.items[index];
                    final isSelected = brand.id == widget.selectedBrandId;

                    return ListTile(
                      title: Text(
                        brand.title,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected ? AppColors.primaryColor : null,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check,
                              color: AppColors.primaryColor,
                            )
                          : null,
                      onTap: () {
                        widget.onSelected(brand);
                        Navigator.pop(context);
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
  }
}
