import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/categories/model/categories_model.dart';
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
                    padding: EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 8.0 + (widget.level * 20.0),
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
                          child: Text(
                            widget.category.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.black : Theme.of(context).colorScheme.tertiary,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle, color: Colors.blue, size: 18),
                      ],
                    ),
                  ),
                ),
                if (isExpanded && hasChildren)
                  CategoryListWidget(
                    parentSlug: widget.category.slug,
                    level: widget.level + 1,
                  ),
              ],
            );
          },
        );
      },
    );
  }

}
