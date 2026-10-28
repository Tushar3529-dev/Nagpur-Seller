import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/screen/order_page/bloc/orders/orders_bloc.dart';
import 'package:hyper_local_seller/widgets/custom/custom_card.dart';
import 'package:hyper_local_seller/utils/debouncer.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/card_shimmers.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/bloc/screen_size/screen_size_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local_seller/router/app_routes.dart';
import 'package:hyper_local_seller/screen/order_page/widgets/order_dialogs.dart';
import 'package:hyper_local_seller/widgets/custom/custom_shimmer.dart';
import 'package:hyper_local_seller/widgets/ui/empty_state_widget.dart';
import 'package:hyper_local_seller/utils/image_path.dart';
import 'package:hyper_local_seller/screen/order_page/repo/order_repo.dart';
import 'package:hyper_local_seller/screen/order_page/model/order_model.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/config/app_permissions.dart';
import 'package:hyper_local_seller/screen/order_page/incoming_orders/cubit/incoming_orders_cubit.dart';
import 'package:hyper_local_seller/utils/permission_checker.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';
import 'package:hyper_local_seller/screen/order_page/dispatch/cubit/dispatch_cubit.dart';
import 'package:hyper_local_seller/screen/order_page/dispatch/model/dispatch_model.dart';
import 'package:hyper_local_seller/screen/order_page/dispatch/view/dispatch_visibility.dart';
import 'package:hyper_local_seller/screen/order_page/dispatch/cubit/rider_availability_cubit.dart';
import 'package:hyper_local_seller/screen/order_page/dispatch/widgets/dispatch_alert_banner.dart';
import 'package:hyper_local_seller/screen/order_page/dispatch/widgets/rider_availability_section.dart';
import 'package:hyper_local_seller/screen/order_page/incoming_orders/widgets/order_alerts_banner.dart';
import 'package:hyper_local_seller/screen/order_page/popup_users/cubit/popup_users_cubit.dart';
import 'package:hyper_local_seller/service/popup_presence_service.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage>
    with
        SingleTickerProviderStateMixin,
        WidgetsBindingObserver,
        DispatchVisibility<OrderPage> {
  static const _modes = OrderMode.values;
  late final DispatchCubit _dispatch;
  late final RiderAvailabilityCubit _availability;
  @override
  Set<String> get dispatchVisiblePaths => {
    AppRoutes.orders,
    AppRoutes.ordersFull,
  };
  @override
  void dispatchVisibilityChanged(bool visible) {
    if (visible && _dispatch.state.dashboard == null) _dispatch.load();
    _dispatch.setPollingOwner(this, visible: visible);
    // Rider availability refreshes every 30s while Orders is on screen.
    _availability.setPollingOwner(this, visible: visible);
    // Only the main seller owner may open system user availability; the
    // first load tells (a 403 hides the button). Owners have every
    // permission, so other roles without system-user access skip the call.
    if (visible &&
        (PermissionChecker.isDefaultSeller ||
            PermissionChecker.hasPermission(AppPermissions.systemUserView))) {
      context.read<PopupUsersCubit>().checkAccess();
    }
  }

  void _openDispatch({bool needsAction = false}) {
    if (needsAction) _dispatch.setFilter(DispatchFilter.needsAction);
    context.pushNamed(AppRoutes.dispatchCenter);
  }

  final ScrollController _scrollController = ScrollController();
  final Debouncer _debouncer = Debouncer(milliseconds: 500);
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _dispatch = context.read<DispatchCubit>();
    _availability = context.read<RiderAvailabilityCubit>();
    _scrollController.addListener(_onScroll);
    final mode = context.read<OrdersBloc>().state.orderMode;
    _tabController = TabController(
      length: _modes.length,
      vsync: this,
      initialIndex: _modes.indexOf(mode).clamp(0, _modes.length - 1),
    );
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    context.read<OrdersBloc>().add(
      ChangeOrderMode(_modes[_tabController.index]),
    );
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  /// Order-level action → one call per item that is still in the right state.
  Future<void> _updateOrder(SellerOrder order, String action) async {
    final ids = order.itemsFor(action).map((item) => item.id);
    await context.read<OrdersRepo>().updateOrderItemsStatus(ids, action);
    if (mounted) context.read<OrdersBloc>().add(RefreshOrders());
  }

  /// Accepted orders are scanned, bagged and dispatched in the scan popup.
  Future<void> _openScan(SellerOrder order) async {
    final error = await context.read<IncomingOrdersCubit>().openForScan(
      order.sellerOrderId,
      mode: order.orderMode,
    );
    if (error != null && mounted) {
      showCustomSnackbar(context: context, message: error, isError: true);
    }
  }

  /// "Process order": opens [order] in the order popup. The main seller
  /// owner first takes the pending offer over from whoever holds it; other
  /// users can only open an order offered to them.
  Future<void> _processOrder(SellerOrder order) async {
    final cubit = context.read<IncomingOrdersCubit>();
    final error = await OrderDialogs.withLoading(context, () async {
      final asOwner = await PopupPresenceService().resolveOwner();
      return cubit.processOrder(
        order.sellerOrderId,
        mode: order.orderMode,
        asOwner: asOwner,
      );
    });
    if (!mounted) return;
    // The offer or the order's status may have changed either way.
    context.read<OrdersBloc>().add(RefreshOrders());
    if (error != null) await OrderDialogs.showProcessError(context, error);
  }

  Widget _buildTabBar(AppLocalizations? l10n) {
    return TabBar(
      controller: _tabController,
      labelColor: AppColors.primaryColor,
      indicatorColor: AppColors.primaryColor,
      unselectedLabelColor: Colors.grey.shade600,
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      tabs: [
        Tab(text: l10n?.regularOrders ?? 'Regular'),
        Tab(text: l10n?.wholesaleOrders ?? 'Wholesale'),
      ],
    );
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<OrdersBloc>().add(LoadMoreOrders());
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
    final dispatchState = context.watch<DispatchCubit>().state;
    final dispatchByNumber = <String, DispatchOrder>{
      for (final order in dispatchState.dashboard?.orders ?? <DispatchOrder>[])
        order.orderNumber: order,
    };
    final canViewDispatch = PermissionChecker.hasPermission(
      AppPermissions.orderView,
    );
    return BlocBuilder<ScreenSizeBloc, ScreenSizeState>(
      builder: (context, screenSizeState) {
        final screenType = screenSizeState.screenType;
        final l10n = AppLocalizations.of(context);

        return CustomScaffold(
          title: l10n?.orders ?? "Orders",
          centerTitle: true,
          showAppbar: true,
          appBarActions: [
            if (canViewDispatch)
              TextButton.icon(
                onPressed: _openDispatch,
                icon: Badge(
                  isLabelVisible:
                      (dispatchState.dashboard?.summary.noNearbyRiders ?? 0) >
                      0,
                  label: Text(
                    '${dispatchState.dashboard?.summary.noNearbyRiders ?? 0}',
                  ),
                  child: const Icon(Icons.delivery_dining_outlined),
                ),
                label: Text(l10n?.dispatchEntry ?? 'Dispatch'),
              ),
            BlocBuilder<PopupUsersCubit, PopupUsersState>(
              builder: (context, popupUsers) {
                if (!popupUsers.hasAccess) return const SizedBox.shrink();
                return IconButton(
                  onPressed: () => context.pushNamed(AppRoutes.popupUsers),
                  tooltip:
                      l10n?.popupUsersTitle ?? 'System user availability',
                  icon: Badge(
                    // Nobody can take a new order: owner is the fallback.
                    isLabelVisible:
                        popupUsers.data!.summary.totalSystemUsers > 0 &&
                        popupUsers.data!.summary.eligibleUsers == 0,
                    smallSize: 8,
                    child: const Icon(Icons.groups_outlined),
                  ),
                );
              },
            ),
          ],
          isHaveSearch: true,
          searchHint: l10n?.search ?? 'Search',
          showFilters: true,
          showStore: true,
          onSearchChanged: (value) {
            _debouncer.run(() {
              context.read<OrdersBloc>().add(SearchOrders(value));
            });
          },
          body: Column(
            children: [
              if (canViewDispatch &&
                  dispatchState.dashboard?.summary.hasAlert == true)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: DispatchAlertBanner(
                    count: dispatchState.dashboard!.summary.noNearbyRiders,
                    compact: true,
                    onTap: () => _openDispatch(needsAction: true),
                  ),
                ),
              if (canViewDispatch)
                ConstrainedBox(
                  // Expanded rider details scroll here rather than pushing
                  // the order list off screen.
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.35,
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: RiderAvailabilitySection(
                      hasDispatchAlert:
                          dispatchState.dashboard?.summary.hasAlert ?? false,
                    ),
                  ),
                ),
              const OrderAlertsBanner(),
              _buildTabBar(l10n),
              Expanded(
                child: BlocConsumer<OrdersBloc, OrdersState>(
                  // Keep the tab in sync when the mode changes elsewhere (e.g. reset on logout).
                  listenWhen: (prev, curr) => prev.orderMode != curr.orderMode,
                  listener: (context, state) {
                    final index = _modes.indexOf(state.orderMode);
                    if (index >= 0 && index != _tabController.index) {
                      _tabController.index = index;
                    }
                  },
                  builder: (context, state) {
                    // Show empty state when not loading and no items
                    if (!state.isInitialLoading &&
                        !state.isRefreshing &&
                        state.items.isEmpty) {
                      return EmptyStateWidget(
                        svgPath: ImagesPath.noOrderFoundSvg,
                        title:
                            AppLocalizations.of(context)?.noOrdersFound ??
                            "No Orders Found",
                        subtitle:
                            AppLocalizations.of(context)?.noOrdersMessage ??
                            "You don't have any orders yet.",
                        actionText:
                            AppLocalizations.of(context)?.refresh ?? "Refresh",
                        onAction: () {
                          context.read<OrdersBloc>().add(RefreshOrders());
                        },
                      );
                    }

                    final items = state.items;
                    final hasMore = state.hasMore;
                    final total = state.total ?? 0;
                    final isPaginating = state.isPaginating;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child:
                              (state.isInitialLoading || state.isRefreshing) &&
                                  state.items.isEmpty
                              ? CustomShimmer(
                                  width: 150,
                                  height: UIUtils.sectionTitle(screenType),
                                )
                              : Text(
                                  "$total ${l10n?.totalOrdersWithCount(total) ?? "Orders"}",
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                        ),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: () async {
                              context.read<OrdersBloc>().add(RefreshOrders());
                            },
                            color: AppColors.primaryColor,
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              controller: _scrollController,
                              padding: UIUtils.cardsPadding(screenType),
                              itemCount:
                                  ((state.isInitialLoading ||
                                          state.isRefreshing) &&
                                      state.items.isEmpty)
                                  ? 10
                                  : items.length +
                                        (hasMore ? (isPaginating ? 10 : 1) : 0),
                              itemBuilder: (context, index) {
                                if ((state.isInitialLoading ||
                                        state.isRefreshing) &&
                                    state.items.isEmpty) {
                                  return CardShimmer(
                                    type: 'order',
                                    screenType: screenType,
                                  );
                                }

                                if (index >= items.length) {
                                  return CardShimmer(
                                    type: 'order',
                                    screenType: screenType,
                                  );
                                }

                                final order = items[index];
                                final canUpdateStatus =
                                    PermissionChecker.hasPermission(
                                      AppPermissions.orderUpdateStatus,
                                    );
                                // Popup users process orders in the popup
                                // instead of accepting from the list.
                                final canProcess =
                                    PermissionChecker.canShowOrderPopup &&
                                    order.canProcess;
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: UIUtils.gapMD(screenType),
                                  ),
                                  child: CustomCard(
                                    type: CardType.order,
                                    screenType: screenType,
                                    data: {
                                      'id': order.orderNumber.isNotEmpty
                                          ? order.orderNumber
                                          : order.id,
                                      'title': order.title,
                                      'quantity': order.totalQuantity,
                                      'subtotal': order.displayTotal(
                                        HiveStorage.currencySymbol,
                                      ),
                                      'status': order.status,
                                      'dispatch_status':
                                          dispatchByNumber[order.orderNumber],
                                      'image': order.image,
                                      'isRushOrder': order.isRushOrder,
                                      'created_at': order.createdAt,
                                      'can_process': canProcess,
                                      'can_reject': canUpdateStatus,
                                      'can_update_status': canUpdateStatus,
                                    },
                                    onTap: () {
                                      context.pushNamed(
                                        AppRoutes.orderDetails,
                                        pathParameters: {
                                          'id': order.sellerOrderId.toString(),
                                        },
                                      );
                                    },
                                    onToggleStatus:
                                        !canUpdateStatus && !canProcess
                                        ? null
                                        : (status) {
                                            if (status == 'process') {
                                              _processOrder(order);
                                            } else if (status == 'accept') {
                                              OrderDialogs.showAcceptDialog(
                                                context,
                                                () async {
                                                  await _updateOrder(
                                                    order,
                                                    'accept',
                                                  );
                                                  if (mounted) {
                                                    await _openScan(order);
                                                  }
                                                },
                                              );
                                            } else if (status == 'reject') {
                                              OrderDialogs.showRejectDialog(
                                                context,
                                                () => _updateOrder(
                                                  order,
                                                  'reject',
                                                ),
                                              );
                                            } else if (status == 'scan') {
                                              _openScan(order);
                                            }
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
            ],
          ),
        );
      },
    );
  }
}
