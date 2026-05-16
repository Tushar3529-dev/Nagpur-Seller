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

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final ScrollController _scrollController = ScrollController();
  final Debouncer _debouncer = Debouncer(milliseconds: 500);

  @override
  void initState() {
    super.initState();
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
          body: BlocBuilder<OrdersBloc, OrdersState>(
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
                            "${l10n?.orderItems ?? "Order Items"} ($total ${l10n?.totalOrdersWithCount(total) ?? "Orders"})",
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
                            ((state.isInitialLoading || state.isRefreshing) &&
                                state.items.isEmpty)
                            ? 10
                            : items.length +
                                  (hasMore ? (isPaginating ? 10 : 1) : 0),
                        itemBuilder: (context, index) {
                          if ((state.isInitialLoading || state.isRefreshing) &&
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
                                'id': order.order.id,
                                'title': order.product.title,
                                'quantity': order.quantity,
                                'subtotal': order.subtotal.formatted,
                                'status': order.status,
                                'image': order.order.image,
                                'isRushOrder': order.order.isRushOrder,
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
                                    () async {
                                      await context
                                          .read<OrdersRepo>()
                                          .updateOrderStatus(
                                            order.orderItemId,
                                            'accept',
                                          );
                                      if (context.mounted) {
                                        context.read<OrdersBloc>().add(
                                          RefreshOrders(),
                                        );
                                      }
                                    },
                                  );
                                } else if (status == 'reject') {
                                  OrderDialogs.showRejectDialog(
                                    context,
                                    () async {
                                      await context
                                          .read<OrdersRepo>()
                                          .updateOrderStatus(
                                            order.orderItemId,
                                            'reject',
                                          );
                                      if (context.mounted) {
                                        context.read<OrdersBloc>().add(
                                          RefreshOrders(),
                                        );
                                      }
                                    },
                                  );
                                } else {
                                  OrderDialogs.showPreparedDialog(
                                    context,
                                    () async {
                                      await context
                                          .read<OrdersRepo>()
                                          .updateOrderStatus(
                                            order.orderItemId,
                                            'preparing',
                                          );
                                      if (context.mounted) {
                                        context.read<OrdersBloc>().add(
                                          RefreshOrders(),
                                        );
                                      }
                                    },
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
        );
      },
    );
  }
}
