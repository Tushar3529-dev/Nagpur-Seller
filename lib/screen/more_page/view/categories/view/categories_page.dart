import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/router/app_routes.dart';
import 'package:hyper_local_seller/utils/debouncer.dart';
import 'package:hyper_local_seller/utils/image_path.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_buttons.dart';
import 'package:hyper_local_seller/widgets/custom/custom_card.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/bloc/screen_size/screen_size_bloc.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/screen/more_page/view/categories/bloc/categories_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/categories/model/categories_model.dart';
import 'package:hyper_local_seller/widgets/custom/card_shimmers.dart';
import 'package:hyper_local_seller/widgets/custom/custom_shimmer.dart';
import 'package:hyper_local_seller/widgets/custom/custom_loading_indicator.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/config/api_routes.dart';
import 'package:hyper_local_seller/service/external_link.dart';
import 'package:hyper_local_seller/widgets/ui/empty_state_widget.dart';

class CategoriesPage extends StatefulWidget {
  final String? categorySlug;
  const CategoriesPage({super.key, this.categorySlug});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final ScrollController _scrollController = ScrollController();

  final Debouncer _debouncer = Debouncer(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    context.read<CategoriesBloc>().add(
      LoadCategoriesInitial(slug: widget.categorySlug, search: null),
    );
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<CategoriesBloc>().add(LoadMoreCategories());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bool isSubcategories =
        widget.categorySlug != null && widget.categorySlug!.isNotEmpty;

    return BlocBuilder<ScreenSizeBloc, ScreenSizeState>(
      builder: (context, screenSizeState) {
        final screenType = screenSizeState.screenType;

        return CustomScaffold(
          centerTitle: true,
          showAppbar: true,
          isHaveSearch: true,
          onSearchChanged: (value) {
            _debouncer.run(() {
              context.read<CategoriesBloc>().add(SearchCategories(value));
            });
          },
          title: isSubcategories
              ? l10n?.subcategories ?? "Subcategories"
              : l10n?.categories ?? "Categories",
          body: BlocBuilder<CategoriesBloc, CategoriesState>(
            builder: (context, state) {
              if (state.error != null && state.items.isEmpty) {
                return EmptyStateWidget(
                  svgPath: ImagesPath.noOrderFoundSvg,
                  title:
                      l10n?.somethingWentWrong ??
                      'Seems like there is some issue',
                  subtitle: l10n?.tryAgainLater ?? 'Please try again later',
                  actionText: l10n?.tryAgain ?? 'Try Again',
                  onAction: () {
                    context.read<CategoriesBloc>().add(RefreshCategories());
                  },
                );
              }

              final items = state.items;
              final hasMore = state.hasMore;
              final total = state.total ?? 0;
              final isPaginating = state.isPaginating;

              return Column(
                children: [
                  Padding(
                    padding: UIUtils.pagePadding(screenType),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        (state.isInitialLoading || state.isRefreshing) &&
                                state.items.isEmpty
                            ? CustomShimmer(
                                width: 150,
                                height: UIUtils.body(screenType),
                              )
                            : Text(
                                "${l10n?.total ?? "Total"} ${l10n?.categories ?? "Categories"} ($total)",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: UIUtils.body(screenType),
                                ),
                              ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      color: AppColors.primaryColor,
                      onRefresh: () async {
                        context.read<CategoriesBloc>().add(RefreshCategories());
                      },
                      child: ListView.separated(
                        controller: _scrollController,
                        padding: UIUtils.cardsPadding(screenType),
                        separatorBuilder: (context, index) =>
                            SizedBox(height: UIUtils.gapMD(screenType)),
                        itemCount: (state.isInitialLoading || state.isRefreshing) &&
                                state.items.isEmpty
                            ? 10
                            : items.length +
                                  (hasMore ? (isPaginating ? 10 : 1) : 0),
                        itemBuilder: (context, index) {
                          if ((state.isInitialLoading || state.isRefreshing) &&
                              state.items.isEmpty) {
                            return CardShimmer(
                              type: 'category',
                              screenType: screenType,
                            );
                          }
                          if (index >= items.length) {
                            return CardShimmer(
                              type: 'category',
                              screenType: screenType,
                            );
                          }

                          final category = items[index];
                          return CustomCard(
                            type: CardType.category,
                            data: _mapCategoryToData(category),
                            screenType: screenType,
                            onTap: () {
                              // Optional: handle tap
                            },
                            extraWidgets: category.subcategoryCount > 0
                                ? Padding(
                                    padding: UIUtils.tilePadding2(screenType),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: PrimaryButton(
                                        text:
                                            l10n?.subcategories ??
                                            "Subcategories",
                                        // icon: Icons.build_outlined,
                                        onPressed: () {
                                          context.pushNamed(
                                            AppRoutes.categories,
                                            queryParameters: {
                                              'slug': category.slug,
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  )
                                : null,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Map<String, dynamic> _mapCategoryToData(Category category) {
    return {
      "id": category.id.toString(),
      "name": category.title,
      "image": category.image,
      "status": category.status,
      "optional_status": category.requiresApproval
          ? "Required"
          : "Not Required",
      "parent": category.parentSlug ?? 'N/A',
      "subcategory_count": category.subcategoryCount,
      "commission": category.commission,
    };
  }
}
