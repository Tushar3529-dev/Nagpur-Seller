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

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage>
    with SingleTickerProviderStateMixin {
  static const _modes = OrderMode.values;

  final ScrollController _scrollController = ScrollController();
  final Debouncer _debouncer = Debouncer(milliseconds: 500);
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
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
    return BlocBuilder<ScreenSizeBloc, ScreenSizeState>(
      builder: (context, screenSizeState) {
        final screenType = screenSizeState.screenType;
        final l10n = AppLocalizations.of(context);

        return CustomScaffold(
          title: l10n?.orders ?? "Orders",
          centerTitle: true,
          showAppbar: true,
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
                                      'image': order.image,
                                      'isRushOrder': order.isRushOrder,
                                      'created_at': order.createdAt,
                                    },
                                    onTap: () {
                                      context.pushNamed(
                                        AppRoutes.orderDetails,
                                        pathParameters: {
                                          'id': order.sellerOrderId.toString(),
                                        },
                                      );
                                    },
                                    onToggleStatus: (status) {
                                      if (status == 'accept') {
                                        OrderDialogs.showAcceptDialog(
                                          context,
                                          () => _updateOrder(order, 'accept'),
                                        );
                                      } else if (status == 'reject') {
                                        OrderDialogs.showRejectDialog(
                                          context,
                                          () => _updateOrder(order, 'reject'),
                                        );
                                      } else {
                                        OrderDialogs.showPreparedDialog(
                                          context,
                                          () =>
                                              _updateOrder(order, 'preparing'),
                                        );
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
