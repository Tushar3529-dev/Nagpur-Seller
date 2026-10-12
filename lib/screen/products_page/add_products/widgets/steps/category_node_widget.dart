import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/screen/more_page/view/categories/model/categories_model.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/bloc/category_product_counts/category_product_counts_cubit.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/bloc/add_product_bloc/add_product_bloc.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/bloc/selected_categories/selected_categories_cubit.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/bloc/selected_categories/category_expansion_cubit.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/widgets/steps/category_list_widget.dart';

class CategoryNodeWidget extends StatefulWidget {
  final Category category;
  final int level;

  const CategoryNodeWidget({
    super.key,
    required this.category,
    required this.level,
  });

  @override
  State<CategoryNodeWidget> createState() => _CategoryNodeWidgetState();
}

class _CategoryNodeWidgetState extends State<CategoryNodeWidget> {
  // We'll manage local expansion but sync with cubit if needed.
  // Actually, for auto-expansion, we should prefer the cubit state.

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoryExpansionCubit, Set<int>>(
      builder: (context, expandedIds) {
        final isExpanded = expandedIds.contains(widget.category.id);

        return BlocBuilder<SelectedCategoriesCubit, Set<int>>(
          builder: (context, selectedIds) {
            final isSelected = selectedIds.contains(widget.category.id);
            final hasChildren = widget.category.subcategoryCount > 0;

            return Column(
              children: [
                InkWell(
                  onTap: () {
                    final cubit = context.read<SelectedCategoriesCubit>();
                    cubit.toggleSelection(widget.category.id);

                    log('User toggled selection for category: ${widget.category.id} (${widget.category.title})');
                    
                    // Sync with AddProductBloc
                    final isCurrentlySelected = cubit.isSelected(widget.category.id);
                    final addProductBloc = context.read<AddProductBloc>();
                    final currentData = addProductBloc.state.productData;
                    
                    final nextSelectedId = isCurrentlySelected ? widget.category.id : null;
                    addProductBloc.add(UpdateProductData(currentData.copyWith(categoryId: nextSelectedId)));
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFF0FBFF) : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    // Only the left side is indented so the count pills line up.
                    padding: EdgeInsets.fromLTRB(
                      8.0 + (widget.level * 20.0),
                      10,
                      8,
                      10,
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: hasChildren
                              ? () {
                                  log('Toggling expansion for category: ${widget.category.id}');
                                  if (isExpanded) {
                                    context.read<CategoryExpansionCubit>().collapse(widget.category.id);
                                  } else {
                                    context.read<CategoryExpansionCubit>().expand(widget.category.id);
                                  }
                                }
                              : null,
                          child: Opacity(
                            opacity: hasChildren ? 1.0 : 0.0,
                            child: Icon(
                              isExpanded ? Icons.arrow_drop_down : Icons.arrow_right_outlined,
                              size: 24,
                              color: const Color(0xFFC4C4C4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.folder,
                          color: Color(0xFFFFD54F),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.category.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? Colors.black : Theme.of(context).colorScheme.tertiary,
                                ),
                              ),
                              if (hasChildren)
                                Text(
                                  AppLocalizations.of(context)?.productSubcategoryCount(
                                        widget.category.subcategoryCount,
                                      ) ??
                                      '${widget.category.subcategoryCount} subcategories',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF8A8A8A),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        _ProductCountPill(
                          categoryId: widget.category.id,
                          isSelected: isSelected,
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.check_circle, color: Colors.blue, size: 18),
                        ],
                      ],
                    ),
                  ),
                ),
                if (isExpanded && hasChildren)
                  // Guide line tying the opened subcategories to this row.
                  Stack(
                    children: [
                      CategoryListWidget(
                        parentSlug: widget.category.slug,
                        level: widget.level + 1,
                      ),
                      // Lines up under this row's expand arrow.
                      Positioned(
                        left: 20.0 + (widget.level * 20.0),
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 1,
                          color: const Color(0xFFE0E0E0),
                        ),
                      ),
                    ],
                  ),
              ],
            );
          },
        );
      },
    );
  }

}

/// The seller's product count for a category; hidden until counts load.
class _ProductCountPill extends StatelessWidget {
  final int categoryId;
  final bool isSelected;

  const _ProductCountPill({required this.categoryId, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final count = context.select<CategoryProductCountsCubit, int?>(
      (cubit) => cubit.state == null ? null : (cubit.state![categoryId] ?? 0),
    );
    if (count == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryColor : const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        AppLocalizations.of(context)?.productCategoryProductCount(count) ??
            '$count products',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isSelected ? Colors.white : const Color(0xFF6B6B6B),
        ),
      ),
    );
  }
}
