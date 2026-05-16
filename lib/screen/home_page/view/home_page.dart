// ignore_for_file: deprecated_member_use

import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/bloc/screen_size/screen_size_bloc.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/model/store_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/service/subscription_limit_service.dart';
import 'package:hyper_local_seller/screen/order_page/bloc/orders/orders_bloc.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/bloc/add_product_bloc/add_product_bloc.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/bloc/selected_categories/selected_categories_cubit.dart';
import 'package:hyper_local_seller/service/demo_guard.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_network_image.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/utils/image_path.dart';
import 'package:hyper_local_seller/bloc/store_switcher/store_switcher_cubit.dart';
import 'package:hyper_local_seller/screen/home_page/widgets/analysis_card.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local_seller/router/app_routes.dart';
import 'package:hyper_local_seller/widgets/custom/custom_selection_sheet.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hyper_local_seller/screen/home_page/bloc/home_page/home_page_bloc.dart';
import 'package:hyper_local_seller/screen/home_page/model/home_page_model.dart';
import 'package:hyper_local_seller/widgets/custom/custom_shimmer.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';
import 'package:hyper_local_seller/widgets/ui/empty_state_widget.dart';
import 'package:hyper_local_seller/utils/permission_checker.dart';
import 'package:hyper_local_seller/config/app_permissions.dart';
import 'package:hyper_local_seller/screen/home_page/bloc/notification/notification_list_bloc.dart';
import 'package:hyper_local_seller/screen/home_page/widgets/membership_tooltip_icon.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/bloc/current_subscription/current_subscription_bloc.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedPeriod = 'Week';
  final SubscriptionLimitService _limitService = SubscriptionLimitService();

  @override
  void initState() {
    super.initState();
    if (HiveStorage.isSubscriptionAvailable) {
      context.read<CurrentSubscriptionBloc>().add(FetchCurrentSubscription());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<ScreenSizeBloc, ScreenSizeState>(
      builder: (context, screenSizeState) {
        final screenType = screenSizeState.screenType;
        return CustomScaffold(
          showAppbar: false,
          body: MultiBlocListener(
            listeners: [
              BlocListener<StoreSwitcherCubit, StoreSwitcherState>(
                listenWhen: (previous, current) =>
                previous.selectedStore?.id != current.selectedStore?.id,
                listener: (context, state) {
                  if (state.selectedStore != null) {
                    context.read<HomePageBloc>().add(
                      FetchHomePageData(storeId: state.selectedStore!.id),
                    );
                    context.read<OrdersBloc>().add(
                      LoadOrdersInitial(storeId: state.selectedStore!.id),
                    );
                    if (HiveStorage.isSubscriptionAvailable) {
                      context.read<CurrentSubscriptionBloc>().add(
                        FetchCurrentSubscription(),
                      );
                    }
                  }
                },
              ),
            ],
            child: SafeArea(
              top: true,
              bottom: false,
              child: SingleChildScrollView(
                // padding: EdgeInsets.only(bottom: UIUtils.gapLG(screenType)),
                child: BlocBuilder<StoreSwitcherCubit, StoreSwitcherState>(
                  builder: (context, switcherState) {
                    return BlocBuilder<HomePageBloc, HomePageState>(
                      builder: (context, state) {
                        HomePageData? data;
                        if (state is HomePageLoaded) {
                          data = state.data;
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(context, screenType, l10n),
                            SizedBox(height: UIUtils.gapLG(screenType)),
                            if (state is HomePageLoading ||
                                switcherState.isLoading)
                              _buildShimmer(screenType)
                            else ...[
                              _buildAnalysisGrid(screenType, data, l10n),
                              _buildQuickActions(context, screenType, l10n),
                              _buildEarningsChart(
                                context,
                                screenType,
                                data,
                                l10n,
                              ),
                              // _buildTopSellingProducts(screenType, l10n: l10n),
                            ],
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
      BuildContext context,
      ScreenType screenType,
      AppLocalizations? l10n,
      ) {
    return BlocBuilder<StoreSwitcherCubit, StoreSwitcherState>(
      builder: (context, state) {
        final store = state.selectedStore;
        return SafeArea(
          child: Padding(
            padding: UIUtils.pagePadding(screenType),
            child: Row(
              children: [
                state.isLoading
                    ? CustomShimmer(
                  width: UIUtils.profileAvatarRadius(screenType) * 2 - 20,
                  height:
                  UIUtils.profileAvatarRadius(screenType) * 2 - 20,
                  borderRadius: BorderRadius.circular(100),
                )
                    : ClipOval(
                  child: SizedBox(
                    width:
                    (UIUtils.profileAvatarRadius(screenType) - 10) *
                        2,
                    height:
                    (UIUtils.profileAvatarRadius(screenType) - 10) *
                        2,
                    child:
                    store != null && (store.logo?.isNotEmpty ?? false)
                        ? CustomNetworkImage(
                      imageUrl: store.logo ?? '',
                      fit: BoxFit.cover,
                      // isCircle: true,
                      placeholderAsset: ImagesPath.sellerLogoPng,
                    )
                        : Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.store, size: 36),
                    ),
                  ),
                ),
                SizedBox(width: UIUtils.gapMD(screenType)),
                Expanded(
                  child: state.isLoading
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomShimmer(
                        width: UIUtils.getScreenWidth(context) * 0.5,
                        height: UIUtils.tileTitle(screenType),
                      ),
                      SizedBox(height: UIUtils.gapSM(screenType)),
                      CustomShimmer(
                        width: UIUtils.getScreenWidth(context) * 0.7,
                        height: UIUtils.caption(screenType),
                      ),
                    ],
                  )
                      : state.stores.isEmpty
                  // No stores: show 'Add Store' call-to-action
                      ? GestureDetector(
                    onTap: () async {
                      if (!PermissionChecker.hasPermission(
                        AppPermissions.storeCreate,
                      )) {
                        showCustomSnackbar(
                          context: context,
                          message:
                          l10n?.noPermissionCreateStore ??
                              "You don't have permission to create stores",
                          isWarning: true,
                        );
                        return;
                      }
                      if (!DemoGuard.shouldProceed(context)) return;
                      final limitService = SubscriptionLimitService();
                      final canCreate = await limitService
                          .canCreateStore();
                      if (!context.mounted) return;
                      if (!canCreate) {
                        if (HiveStorage.activePlanId == null) {
                          showCustomSnackbar(
                            context: context,
                            message:
                            "You don't have any active plan. Please buy one.",
                            isError: true,
                            actionLabel: 'View Plans',
                            onAction: () {
                              if (!PermissionChecker.hasPermission(
                                AppPermissions.subscriptionView,
                              )) {
                                showCustomSnackbar(
                                  context: context,
                                  message:
                                  // l10n?.noPermissionViewSubscriptionPlans ??
                                  'You do not have permission to view subscription plans.',
                                  isWarning: true,
                                );
                                return;
                              }
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
                      final result = await context.push<bool>(
                        AppRoutes.addStore,
                      );
                      if (result == true && context.mounted) {
                        context.read<StoreSwitcherCubit>().loadStores();
                      }
                    },
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_business_rounded,
                                size: UIUtils.tileIcon(screenType),
                                color: Theme.of(context).primaryColor,
                              ),
                              SizedBox(width: UIUtils.gapXS(screenType)),
                              Text(
                                l10n?.addStore ?? 'Add Store',
                                style: TextStyle(
                                  fontSize: UIUtils.body(screenType),
                                  fontWeight: UIUtils.semiBold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                  // Has stores: show store name + switcher
                      : GestureDetector(
                    onTap: () {
                      CustomSelectionSheet.show<Store>(
                        context: context,
                        title: l10n?.switchStore ?? "Switch Store",
                        selectedValue: state.selectedStore,
                        items: state.stores.map((s) {
                          final bool isNotApproved =
                              s.verificationStatus == 'not_approved';
                          final bool isDraft =
                              s.visibilityStatus == 'draft';
                          return SelectionItem<Store>(
                            label: s.name,
                            sublabel: s.address,
                            value: s,
                            image: s.logo,
                            isDisabled: isNotApproved || isDraft,
                            onDisabledTapMessage: isNotApproved
                                ? "your store hasn't been approved by admin"
                                : (isDraft
                                ? "your store is not visible to public yet wait for some time"
                                : null),
                          );
                        }).toList(),
                        onSelected: (selected) {
                          context.read<StoreSwitcherCubit>().selectStore(
                            selected,
                          );
                        },
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      store?.name ?? (l10n?.noActiveStore ?? 'No Active Store'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: UIUtils.tileTitle(
                                          screenType,
                                        ),
                                        fontWeight: UIUtils.bold,
                                      ),
                                    ),
                                  ),
                                  if (store?.name != null &&
                                      store!.name.length > 25)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 4),
                                      child: Icon(
                                        Icons.more_horiz,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(width: UIUtils.gapSM(screenType)),
                            InkWell(
                              onTap: () {
                                CustomSelectionSheet.show<Store>(
                                  context: context,
                                  title:
                                  l10n?.switchStore ?? "Switch Store",
                                  selectedValue: state.selectedStore,
                                  items: state.stores.map((s) {
                                    final bool isNotApproved =
                                        s.verificationStatus ==
                                            'not_approved';
                                    final bool isDraft =
                                        s.visibilityStatus == 'draft';
                                    return SelectionItem<Store>(
                                      label: s.name,
                                      sublabel: s.address,
                                      value: s,
                                      image: s.logo,
                                      isDisabled:
                                      isNotApproved || isDraft,
                                      onDisabledTapMessage: isNotApproved
                                          ? "your store hasn't been approved by admin"
                                          : (isDraft
                                          ? "your store is not visible to public yet wait for some time"
                                          : null),
                                    );
                                  }).toList(),
                                  onSelected: (selected) {
                                    context
                                        .read<StoreSwitcherCubit>()
                                        .selectStore(selected);
                                  },
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: UIUtils.tileIcon(screenType) + 4,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: UIUtils.gapSM(screenType)),
                        Text(
                          store?.address ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: UIUtils.caption(screenType),
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: UIUtils.gapSM(screenType)),
                if (HiveStorage.isSubscriptionAvailable &&
                    PermissionChecker.hasPermission(
                      AppPermissions.subscriptionView,
                    ))
                  MembershipTooltipIcon(screenType: screenType),
                BlocBuilder<NotificationListBloc, NotificationListState>(
                  builder: (context, notifState) {
                    return GestureDetector(
                      onTap: () {
                        if (!PermissionChecker.hasPermission(
                          AppPermissions.notificationView,
                        )) {
                          showCustomSnackbar(
                            context: context,
                            message:
                            l10n?.noPermissionViewNotification ??
                                'You do not have permission to view notifications.',
                            isWarning: true,
                          );
                          return;
                        }
                        context.push(AppRoutes.notifications);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              Icons.notifications_none_rounded,
                              size: UIUtils.appBarIcon(screenType) + 4,
                              color: Theme.of(context).colorScheme.tertiary,
                            ),
                            if (notifState.unreadCount > 0)
                              Positioned(
                                right: -10,
                                top: -15,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  child: Text(
                                    notifState.unreadCount > 99
                                        ? '99+'
                                        : '${notifState.unreadCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnalysisGrid(
      ScreenType screenType,
      HomePageData? data,
      AppLocalizations? l10n,
      ) {
    final summary = data?.summary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalGap = UIUtils.gapMD(screenType);
        final verticalGap = UIUtils.gapMD(screenType);
        final padding = UIUtils.gapLG(screenType);
        final availableWidth = constraints.maxWidth - (padding * 2);

        // 2 columns on mobile, 4 columns on tablet
        final int crossAxisCount = screenType == ScreenType.tablet ? 4 : 2;
        final double itemWidth =
            (availableWidth - (horizontalGap * (crossAxisCount - 1))) /
                crossAxisCount;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: Wrap(
            spacing: horizontalGap,
            runSpacing: verticalGap,
            children: [
              SizedBox(
                width: itemWidth,
                child: AnalysisCard(
                  label:
                  summary?.todaysRevenue?.title ??
                      l10n?.earnings ??
                      "Earnings",
                  value: summary?.todaysRevenue?.value ?? "₹0",
                  trend: summary?.todaysRevenue?.message ?? "0% from yesterday",
                  trendColor: Colors.green,
                  svgPath: ImagesPath.salesSvg,
                  iconBgColor: Colors.green,
                  screenType: screenType,
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: AnalysisCard(
                  label:
                  summary?.totalOrders?.title ??
                      l10n?.pendingOrders ??
                      "Pending Orders",
                  value: summary?.totalOrders?.value ?? "0",
                  trend: summary?.totalOrders?.message ?? "0 New",
                  trendColor: Colors.orange,
                  svgPath: ImagesPath.pendingOrdersSvg,
                  iconBgColor: Colors.orange,
                  screenType: screenType,
                  onTap: () => context.go(AppRoutes.orders),
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: AnalysisCard(
                  label:
                  summary?.totalProducts?.title ??
                      l10n?.totalProducts ??
                      "Total Products",
                  value: summary?.totalProducts?.value ?? "0",
                  trend: summary?.totalProducts?.message ?? "0 Low Stocks",
                  trendColor: Colors.red,
                  svgPath: ImagesPath.productsActive,
                  iconBgColor: Colors.amber,
                  screenType: screenType,
                  onTap: () => context.go(AppRoutes.products),
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: AnalysisCard(
                  label: summary?.sales?.title ?? l10n?.orders ?? "Orders",
                  value: summary?.sales?.value ?? "0",
                  trend: summary?.sales?.message ?? "",
                  trendColor: Colors.green,
                  svgPath: ImagesPath.thisMonthSvg,
                  iconBgColor: Colors.blue,
                  screenType: screenType,
                  onTap: () => context.push(AppRoutes.earnings),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(
      BuildContext context,
      ScreenType screenType,
      AppLocalizations? l10n,
      ) {
    return Padding(
      padding: UIUtils.pagePadding(screenType),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.quickActions ?? "Quick Actions",
            style: TextStyle(
              fontSize: UIUtils.tileTitle(screenType),
              fontWeight: UIUtils.bold,
            ),
          ),
          SizedBox(height: UIUtils.gapMD(screenType)),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  context,
                  screenType,
                  label: l10n?.addProduct ?? "Add Product",
                  icon: Icons.add,
                  color: Colors.blue.shade700,
                  onTap: () {
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
                            "You don't have any active plan please buy one",
                            isWarning: true,
                            actionLabel: 'View',
                            onAction: () {
                              if (!PermissionChecker.hasPermission(
                                AppPermissions.subscriptionView,
                              )) {
                                showCustomSnackbar(
                                  context: context,
                                  message:
                                  // l10n?.noPermissionViewSubscriptionPlans ??
                                  'You do not have permission to view subscription plans.',
                                  isWarning: true,
                                );
                                return;
                              }
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
                      final selectedStore = context
                          .read<StoreSwitcherCubit>()
                          .state
                          .selectedStore;
                      if (selectedStore != null) {
                        context.read<HomePageBloc>().add(
                          FetchHomePageData(storeId: selectedStore.id),
                        );
                      }
                    });
                  },
                ),
              ),
              SizedBox(width: UIUtils.gapMD(screenType)),
              Expanded(
                child: _buildActionButton(
                  context,
                  screenType,
                  label: l10n?.viewOrders ?? "View Orders",
                  icon: Icons.list_alt_outlined,
                  color: Colors.orange.shade700,
                  onTap: () {
                    if (!PermissionChecker.hasPermission(
                      AppPermissions.orderView,
                    )) {
                      showCustomSnackbar(
                        context: context,
                        message:
                        l10n?.noPermissionViewOrders ??
                            'You do not have permission to view orders.',
                        isWarning: true,
                      );
                      return;
                    }
                    context.go(AppRoutes.orders);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      BuildContext context,
      ScreenType screenType, {
        required String label,
        required IconData icon,
        required Color color,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(UIUtils.radiusMD(screenType)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            SizedBox(height: UIUtils.gapXS(screenType)),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: UIUtils.bold,
                fontSize: UIUtils.body(screenType),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsChart(
      BuildContext context,
      ScreenType screenType,
      HomePageData? data,
      AppLocalizations? l10n,
      ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Get filtered data
    final points = _getChartData(data);

    // Creating spots
    List<FlSpot> spots = [];
    double maxY = 5;
    if (points.isNotEmpty) {
      for (int i = 0; i < points.length; i++) {
        final point = points[i];
        final yVal = point.value;
        if (yVal > maxY) maxY = yVal;
        spots.add(FlSpot(i.toDouble(), yVal));
      }
    }

    // Add some buffer to maxY
    maxY = maxY * 1.2;

    return Padding(
      padding: UIUtils.pagePadding(screenType),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n?.earnings ?? "Earnings",
                style: TextStyle(
                  fontSize: UIUtils.tileTitle(screenType),
                  fontWeight: UIUtils.bold,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: ["Week", "Month", "3 Months"].map((period) {
                    final isSelected = _selectedPeriod == period;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedPeriod = period;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: isSelected
                            ? BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(6),
                        )
                            : null,
                        child: Text(
                          period,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          SizedBox(height: UIUtils.gapMD(screenType)),
          Container(
            height: 250,
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              UIUtils.gapSM(screenType),
              UIUtils.gapLG(screenType),
              UIUtils.gapLG(screenType),
              UIUtils.gapSM(screenType),
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? Theme.of(context).colorScheme.surfaceContainer
                  : Colors.white,
              borderRadius: BorderRadius.circular(UIUtils.radiusLG(screenType)),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 0.5,
              ),
            ),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withValues(alpha: 0.2),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withValues(alpha: 0.2),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < points.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              points[index].label,
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: maxY / 4,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(1),
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 10,
                          ),
                        );
                      },
                      reservedSize: 42,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (points.length - 1).toDouble(),
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: Colors.blue.shade400,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    // belowBarData: BarAreaData(
                    //   show: true,
                    //   gradient: LinearGradient(
                    //     colors: [
                    //       Colors.blue.shade400.withValues(alpha:0.3),
                    //       Colors.blue.shade400.withValues(alpha:0.0),
                    //     ],
                    //     begin: Alignment.topCenter,
                    //     end: Alignment.bottomCenter,
                    //   ),
                    // ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer(ScreenType screenType) {
    return Padding(
      padding: UIUtils.pagePadding(screenType),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: CustomShimmer(width: double.infinity, height: 100),
              ),
              SizedBox(width: 16),
              Expanded(
                child: CustomShimmer(width: double.infinity, height: 100),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomShimmer(width: double.infinity, height: 100),
              ),
              SizedBox(width: 16),
              Expanded(
                child: CustomShimmer(width: double.infinity, height: 100),
              ),
            ],
          ),
          SizedBox(height: 24),
          CustomShimmer(width: double.infinity, height: 80),
          SizedBox(height: 24),
          CustomShimmer(width: double.infinity, height: 250),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: CustomShimmer(width: double.infinity, height: 180),
              ),
              SizedBox(width: 16),
              Expanded(
                child: CustomShimmer(width: double.infinity, height: 180),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<_ChartPoint> _getChartData(HomePageData? data) {
    if (data == null || data.chart == null) return [];

    if (_selectedPeriod == 'Week') {
      return data.chart!.weekly?.entries
          ?.map((e) => _ChartPoint(e.day, e.earnings.toDouble()))
          .toList() ??
          [];
    } else if (_selectedPeriod == 'Month') {
      return data.chart!.monthly?.entries
          ?.map((e) => _ChartPoint(e.week, e.earnings.toDouble()))
          .toList() ??
          [];
    } else if (_selectedPeriod == '3 Months') {
      final yearlyEntries = data.chart!.yearly?.entries ?? [];
      final currentMonth = DateTime.now().month;

      List<_ChartPoint> points = [];

      for (int i = 2; i >= 0; i--) {
        int targetMonthIndex = currentMonth - 1 - i;
        if (targetMonthIndex >= 0 && targetMonthIndex < yearlyEntries.length) {
          final entry = yearlyEntries[targetMonthIndex];
          points.add(_ChartPoint(entry.month, entry.earnings));
        }
      }
      return points;
    }
    return [];
  }
}

class _ChartPoint {
  final String label;
  final double value;

  _ChartPoint(this.label, this.value);
}
