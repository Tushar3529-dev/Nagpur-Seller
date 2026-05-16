import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/screen/more_page/view/categories/bloc/categories_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/categories/repo/categories_repo.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/widgets/steps/category_node_widget.dart';
import 'package:hyper_local_seller/utils/image_path.dart';
import 'package:hyper_local_seller/widgets/custom/custom_loading_indicator.dart';
import 'package:hyper_local_seller/widgets/ui/empty_state_widget.dart';

class CategoryListWidget extends StatefulWidget {
  final String? parentSlug;
  final String? search;
  final int level;

  const CategoryListWidget({
    super.key,
    this.parentSlug,
    this.search,
    required this.level,
  });

  @override
  State<CategoryListWidget> createState() => _CategoryListWidgetState();
}

class _CategoryListWidgetState extends State<CategoryListWidget> {
  late CategoriesBloc _categoriesBloc;

  @override
  void initState() {
    super.initState();
    _categoriesBloc = CategoriesBloc(CategoriesRepo())
      ..add(
        LoadCategoriesInitial(slug: widget.parentSlug, search: widget.search),
      );
  }

  @override
  void didUpdateWidget(CategoryListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.search != widget.search ||
        oldWidget.parentSlug != widget.parentSlug) {
      _categoriesBloc.add(
        LoadCategoriesInitial(slug: widget.parentSlug, search: widget.search),
      );
    }
  }

  @override
  void dispose() {
    _categoriesBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _categoriesBloc,
      child: BlocBuilder<CategoriesBloc, CategoriesState>(
        builder: (context, state) {
          if (state.isInitialLoading) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CustomLoadingIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryColor,
                ),
              ),
            );
          }

          if (state.items.isEmpty) {
            return EmptyStateWidget(
              svgPath: ImagesPath.noProductFoundSvg,
              title: 'No Categories Found',
              subtitle: 'There is not any category available.',
              actionText: 'Refresh',
              onAction: () {
                _categoriesBloc.add(
                  LoadCategoriesInitial(
                    slug: widget.parentSlug,
                    search: widget.search,
                  ),
                );
              },
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.items.length + (state.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= state.items.length) {
                _categoriesBloc.add(LoadMoreCategories());
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CustomLoadingIndicator(size: 20, strokeWidth: 2),
                  ),
                );
              }
              return CategoryNodeWidget(
                category: state.items[index],
                level: widget.level,
              );
            },
          );
        },
      ),
    );
  }
}
