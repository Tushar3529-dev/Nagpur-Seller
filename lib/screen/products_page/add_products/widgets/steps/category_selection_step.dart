import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/bloc/add_product_bloc/add_product_bloc.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/bloc/selected_categories/category_expansion_cubit.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/bloc/selected_categories/selected_categories_cubit.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/widgets/steps/category_list_widget.dart';
import 'package:hyper_local_seller/widgets/custom/custom_search_field.dart';

class CategorySelectionStep extends StatefulWidget {
  const CategorySelectionStep({super.key});

  @override
  State<CategorySelectionStep> createState() => _CategorySelectionStepState();
}

class _CategorySelectionStepState extends State<CategorySelectionStep> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _searchQuery = "";
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final bloc = context.read<AddProductBloc>();
    final categoryId = bloc.state.productData.categoryId;
    if (categoryId != null) {
      context.read<SelectedCategoriesCubit>().select(categoryId);
    }
    final lineage = bloc.state.productData.categoryLineage;
    if (lineage.isNotEmpty) {
      context.read<CategoryExpansionCubit>().expandMany(lineage);
    }
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _searchQuery = value;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddProductBloc, AddProductState>(
      listenWhen: (previous, current) {
        return previous.productData.categoryLineage != current.productData.categoryLineage;
      },
      listener: (context, state) {
        if (state.productData.categoryLineage.isNotEmpty) {
          context.read<CategoryExpansionCubit>().expandMany(state.productData.categoryLineage);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomSearchField(
            hint: "Search Category",
            fillColor: Colors.transparent,
            focusNode: _searchFocus,
            controller: _searchController,
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 15),
          CategoryListWidget(
            level: 0,
            search: _searchQuery.isEmpty ? null : _searchQuery,
          ),
        ],
      ),
    );
  }
}

