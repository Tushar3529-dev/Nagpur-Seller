import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local_seller/bloc/store_switcher/store_switcher_cubit.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/router/app_routes.dart';
import 'package:hyper_local_seller/screen/home_page/bloc/home_page/home_page_bloc.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/bloc/add_product_bloc/add_product_bloc.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/bloc/selected_categories/selected_categories_cubit.dart';
import 'package:hyper_local_seller/screen/products_page/products/bloc/products_bloc/products_bloc.dart';
import 'package:hyper_local_seller/widgets/custom/custom_alert_dialog.dart';
import 'package:hyper_local_seller/widgets/custom/custom_card.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/widgets/custom/custom_buttons.dart';
import 'package:hyper_local_seller/widgets/custom/card_shimmers.dart';
import 'package:hyper_local_seller/widgets/custom/custom_shimmer.dart';
import 'package:hyper_local_seller/utils/debouncer.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';
import 'package:hyper_local_seller/widgets/ui/empty_state_widget.dart';
import 'package:hyper_local_seller/utils/image_path.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/config/app_permissions.dart';
import 'package:hyper_local_seller/service/demo_guard.dart';
import 'package:hyper_local_seller/utils/permission_checker.dart';

import 'package:hyper_local_seller/widgets/custom/custom_filter_sheet.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/service/subscription_limit_service.dart';

class ProductsPage extends StatefulWidget {
  final bool isFromBottomNav;
  const ProductsPage({super.key, this.isFromBottomNav = false});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final Debouncer _debouncer = Debouncer(milliseconds: 500);
  final SubscriptionLimitService _limitService = SubscriptionLimitService();

  @override
  void initState() {
    super.initState();
    context.read<ProductsBloc>().add(LoadProductsInitial());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<ProductsBloc>().add(LoadMoreProducts());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    final screenType = context.screenType;
    final l10n = AppLocalizations.of(context);
    return CustomScaffold(
      title: l10n?.products ?? "Products",
      showAppbar: true,
      centerTitle: true,
      isHaveSearch: true,
      searchController: _searchController,
      searchHint: l10n?.searchProduct ?? "Search Products",
      onSearchChanged: (value) {
        _debouncer.run(() {
          context.read<ProductsBloc>().add(SearchProducts(value));
        });
      },
      showFilters: true,
      filterType: FilterType.product,
      body: MultiBlocListener(
        listeners: [
          BlocListener<ProductsBloc, ProductsState>(
            listenWhen: (prev, curr) =>
                prev.operationSuccess != curr.operationSuccess &&
                curr.operationSuccess != null,
            listener: (context, state) {
              /*showCustomSnackbar(
                context: context,
                message:
                    state.operationMessage ??
                    AppLocalizations.of(
                      context,
                    )!.operationCompletedSuccessfully,
              );

              // Refresh Products List
              context.read<ProductsBloc>().add(RefreshProducts());

              // Refresh HomePage Data (This is what you asked for)
              final selectedStore = context
                  .read<StoreSwitcherCubit>()
                  .state
                  .selectedStore;
              if (selectedStore != null) {
                context.read<HomePageBloc>().add(
                  FetchHomePageData(storeId: selectedStore.id),
                );
              }*/

              final l10n = AppLocalizations.of(context);

              if (state.operationSuccess == true) {
                // Success case
                showCustomSnackbar(
                  context: context,
                  message:
                      state.operationMessage ??
                      l10n?.operationCompletedSuccessfully ??
                      "Operation completed successfully",
                );

                // Refresh both lists
                context.read<ProductsBloc>().add(RefreshProducts());

                final selectedStore = context
                    .read<StoreSwitcherCubit>()
                    .state
                    .selectedStore;
                if (selectedStore != null) {
                  context.read<HomePageBloc>().add(
                    FetchHomePageData(storeId: selectedStore.id),
                  );
                }
              } else if (state.operationSuccess == false) {
                showCustomSnackbar(
                  context: context,
                  message:
                      state.operationMessage ??
                      "Something went wrong. Please try again.",
                  isError: true,
                );
              }
            },
          ),
        ],
        child: BlocBuilder<ProductsBloc, ProductsState>(
          builder: (context, state) {
            if (!state.isInitialLoading && state.items.isEmpty) {
              return EmptyStateWidget(
                svgPath: ImagesPath.noProductFoundSvg,
                title: AppLocalizations.of(context)!.noProductsFound,
                subtitle: AppLocalizations.of(context)!.noProductsMessage,
                actionText: l10n?.addProduct ?? "Add Product",
                onAction: () {
                  if (!PermissionChecker.hasPermission(
                    AppPermissions.productCreate,
                  )) {
                    showCustomSnackbar(
                      context: context,
                      message:
                          l10n?.noPermissionAddProduct ??
                          "You don't have permission to add product",
                      isWarning: true,
                    );
                    return;
                  }
                  if (!DemoGuard.shouldProceed(context)) return;

                  _limitService.canCreateProduct().then((canCreate) {
                    if (!context.mounted) return;
                    if (!canCreate) {
                      if (HiveStorage.activePlanId == null) {
                        showCustomSnackbar(
                          context: context,
                          message:
                              "you don't have any active plan please buy one",
                          isWarning: true,
                          actionLabel: 'View',
                          onAction: () {
                            context.push(AppRoutes.subscriptionPlans);
                          },
                        );
                      } else {
                        showCustomSnackbar(
                          context: context,
                          message:
                              l10n?.limitReached ??
                              "You have reached your plan limit",
                          isWarning: true,
                        );
                      }
                      return;
                    }
                    context.read<AddProductBloc>().add(AddProductReset());
                    context.read<SelectedCategoriesCubit>().clear();
                    context.push(
                      AppRoutes.addProduct,
                      extra: {'is_edit': false},
                    );
                  });
                },
              );
            }

            final products = state.items;
            return Column(
              children: [
                // heading
                Padding(
                  padding: UIUtils.pagePadding(screenType),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      (state.isInitialLoading || state.isRefreshing) &&
                              state.items.isEmpty
                          ? CustomShimmer(
                              width: 150,
                              height: UIUtils.sectionTitle(screenType),
                            )
                          : Text(
                              '${l10n?.totalProducts ?? 'Total Products'} (${state.total ?? products.length})',
                              style: TextStyle(
                                fontSize: UIUtils.sectionTitle(screenType),
                                fontWeight: UIUtils.bold,
                              ),
                            ),

                      (state.isInitialLoading || state.isRefreshing) &&
                              state.items.isEmpty
                          ? CustomShimmer(
                              width: 120,
                              height: 40,
                              borderRadius: BorderRadius.circular(
                                UIUtils.radiusMD(screenType),
                              ),
                            )
                          : SecondaryButton(
                              text: l10n?.addNewProduct ?? 'Add New Product',
                              onPressed: () async {
                                if (!PermissionChecker.hasPermission(
                                  AppPermissions.productCreate,
                                )) {
                                  showCustomSnackbar(
                                    context: context,
                                    message:
                                        l10n?.noPermissionAddProduct ??
                                        "You don't have permission to add product",
                                    isWarning: true,
                                  );
                                  return;
                                }
                                if (!DemoGuard.shouldProceed(context)) return;
                                _limitService.fetchUsageCounts();
                                final canCreate = await _limitService
                                    .canCreateProduct();
                                if (!context.mounted) return;

                                if (!canCreate) {
                                  if (HiveStorage.activePlanId == null) {
                                    showCustomSnackbar(
                                      context: context,
                                      message:
                                          "you don't have any active plan please buy one",
                                      isWarning: true,
                                      actionLabel: 'View',
                                      onAction: () {
                                        context.push(
                                          AppRoutes.subscriptionPlans,
                                        );
                                      },
                                    );
                                  } else {
                                    showCustomSnackbar(
                                      context: context,
                                      message:
                                          l10n?.limitReached ??
                                          "You have reached your plan limit",
                                      isWarning: true,
                                    );
                                  }
                                  return;
                                }

                                context.read<AddProductBloc>().add(
                                  AddProductReset(),
                                );
                                context.read<SelectedCategoriesCubit>().clear();
                                await context.push(
                                  AppRoutes.addProduct,
                                  extra: {'is_edit': false},
                                );

                                if (context.mounted) {
                                  _searchController.clear();
                                  context.read<ProductsBloc>().add(
                                    LoadProductsInitial(),
                                  );

                                  // Refresh HomePage Data
                                  final selectedStore = context
                                      .read<StoreSwitcherCubit>()
                                      .state
                                      .selectedStore;
                                  if (selectedStore != null) {
                                    context.read<HomePageBloc>().add(
                                      FetchHomePageData(
                                        storeId: selectedStore.id,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                    ],
                  ),
                ),

                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primaryColor,
                    onRefresh: () async {
                      context.read<ProductsBloc>().add(RefreshProducts());
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: UIUtils.cardsPadding(screenType),
                      itemCount:
                          (state.isInitialLoading || state.isRefreshing) &&
                              state.items.isEmpty
                          ? 10
                          : products.length +
                                (state.hasMore
                                    ? (state.isPaginating ? 10 : 1)
                                    : 0),
                      itemBuilder: (context, index) {
                        if ((state.isInitialLoading || state.isRefreshing) &&
                            state.items.isEmpty) {
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: UIUtils.gapMD(screenType),
                            ),
                            child: CardShimmer(
                              type: 'product',
                              screenType: screenType,
                            ),
                          );
                        }

                        if (index >= products.length) {
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: UIUtils.gapMD(screenType),
                            ),
                            child: CardShimmer(
                              type: 'product',
                              screenType: screenType,
                            ),
                          );
                        }

                        final product = products[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: UIUtils.gapMD(screenType),
                          ),
                          child: CustomCard(
                            type: CardType.product,
                            screenType: screenType,
                            data: {
                              'id': product.id,
                              'name': product.title,
                              'image': product.mainImage,
                              'category': product.categoryName,
                              'rating': product.ratings,
                              'price': product.variants?.isNotEmpty == true
                                  ? product.variants![0].price
                                  : '0',
                              'special_price':
                                  product.variants?.isNotEmpty == true
                                  ? product.variants![0].specialPrice
                                  : '0',
                              'status': product.status,
                            },
                            onTap: () {
                              context.push(
                                AppRoutes.productDetails,
                                extra: product,
                              );
                            },
                            onEdit: () async {
                              if (!PermissionChecker.hasPermission(
                                AppPermissions.productEdit,
                              )) {
                                showCustomSnackbar(
                                  context: context,
                                  message:
                                      l10n?.noPermissionEditProduct ??
                                      "You do not have permission to edit products.",
                                  isWarning: true,
                                );
                                return;
                              }
                              if (!DemoGuard.shouldProceed(context)) return;

                              if (product.categoryId != null) {
                                context.read<SelectedCategoriesCubit>().select(
                                  product.categoryId!,
                                );
                              }
                              context.read<AddProductBloc>().add(
                                LoadProductForEdit(product.id),
                              );
                              await context.push(
                                AppRoutes.addProduct,
                                extra: {'is_edit': true},
                              );

                              if (context.mounted) {
                                _searchController.clear();
                                context.read<ProductsBloc>().add(
                                  LoadProductsInitial(),
                                );

                                // Refresh HomePage Data
                                final selectedStore = context
                                    .read<StoreSwitcherCubit>()
                                    .state
                                    .selectedStore;
                                if (selectedStore != null) {
                                  context.read<HomePageBloc>().add(
                                    FetchHomePageData(
                                      storeId: selectedStore.id,
                                    ),
                                  );
                                }
                              }
                            },
                            onDelete: () {
                              if (!PermissionChecker.hasPermission(
                                AppPermissions.productDelete,
                              )) {
                                showCustomSnackbar(
                                  context: context,
                                  message:
                                      l10n?.noPermissionDeleteProduct ??
                                      "You do not have permission to delete product.",
                                  isWarning: true,
                                );
                                return;
                              }
                              if (!DemoGuard.shouldProceed(context)) return;

                              showAppAlertDialog(
                                context: context,
                                title: l10n?.deleteProduct ?? "Delete Product",
                                message:
                                    l10n?.deleteProductConfirmation ??
                                    "Are you sure you want to delete this product?",
                                onConfirm: () {
                                  context.read<ProductsBloc>().add(
                                    DeleteProduct(product.id),
                                  );

                                  if (context.mounted) {
                                    context.read<ProductsBloc>().add(
                                      RefreshProducts(),
                                    );

                                    // Also refresh HomePage
                                    final selectedStore = context
                                        .read<StoreSwitcherCubit>()
                                        .state
                                        .selectedStore;
                                    if (selectedStore != null) {
                                      context.read<HomePageBloc>().add(
                                        FetchHomePageData(
                                          storeId: selectedStore.id,
                                        ),
                                      );
                                    }
                                  }
                                },
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
