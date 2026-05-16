// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/router/app_routes.dart';
import 'package:hyper_local_seller/utils/debouncer.dart';
import 'package:hyper_local_seller/utils/image_path.dart';
import 'package:hyper_local_seller/utils/time_utils.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/card_shimmers.dart';
import 'package:hyper_local_seller/widgets/custom/custom_dropdown.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/widgets/ui/empty_state_widget.dart';
import '../bloc/settled_earnings_bloc.dart';
import '../bloc/unsettled_earnings_bloc.dart';
import '../model/earnings_model.dart';
import '../widgets/earning_card.dart';

class EarningPage extends StatefulWidget {
  const EarningPage({super.key});

  @override
  State<EarningPage> createState() => _EarningPageState();
}

class _EarningPageState extends State<EarningPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _settledScrollController = ScrollController();
  final ScrollController _unsettledScrollController = ScrollController();
  EarningType _selectedUnsettledType = EarningType.credit;
  final Debouncer _debouncer = Debouncer(milliseconds: 500);
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<SettledEarningsBloc>().add(const LoadSettledEarningsInitial());
    context.read<UnsettledEarningsBloc>().add(
      const LoadUnsettledEarningsInitial(),
    );
    _settledScrollController.addListener(_onSettledScroll);
    _unsettledScrollController.addListener(_onUnsettledScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _settledScrollController.dispose();
    _unsettledScrollController.dispose();
    _debouncer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSettledScroll() {
    if (_isSettledBottom) {
      context.read<SettledEarningsBloc>().add(LoadMoreSettledEarnings());
    }
  }

  void _onUnsettledScroll() {
    if (_isUnsettledBottom) {
      context.read<UnsettledEarningsBloc>().add(LoadMoreUnsettledEarnings());
    }
  }

  bool get _isSettledBottom {
    if (!_settledScrollController.hasClients) return false;
    final maxScroll = _settledScrollController.position.maxScrollExtent;
    final currentScroll = _settledScrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  bool get _isUnsettledBottom {
    if (!_unsettledScrollController.hasClients) return false;
    final maxScroll = _unsettledScrollController.position.maxScrollExtent;
    final currentScroll = _unsettledScrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screenType = context.screenType;
    final theme = Theme.of(context);

    return CustomScaffold(
      title: l10n?.earnings ?? "Earnings",
      showAppbar: true,
      centerTitle: true,
      isHaveSearch: true,
      searchHint: l10n?.searchLabel ?? "Search...",
      searchController: _searchController,
      onSearchChanged: (value) {
        _debouncer.run(() {
          if (_tabController.index == 0) {
            context.read<SettledEarningsBloc>().add(
              SearchSettledEarnings(value),
            );
          } else {
            context.read<UnsettledEarningsBloc>().add(
              SearchUnsettledEarnings(value),
            );
          }
        });
      },
      body: Column(
        children: [
          // Tab Bar
          TabBar(
            controller: _tabController,
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(width: 3.0, color: AppColors.primaryColor),
              insets: EdgeInsets.symmetric(horizontal: 16.0),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: theme.dividerColor.withValues(alpha: 0.1),
            labelColor: theme.textTheme.titleMedium?.color,
            unselectedLabelColor: Colors.grey,
            labelStyle: TextStyle(
              fontSize: UIUtils.tileTitle(screenType),
              fontWeight: FontWeight.bold,
            ),
            tabs: [
              Tab(text: l10n?.settled ?? 'Settled'),
              Tab(text: l10n?.unsettled ?? 'Unsettled'),
            ],
          ),

          SizedBox(height: UIUtils.gapMD(screenType)),

          // Tab Bar View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Settled Tab
                BlocBuilder<SettledEarningsBloc, SettledEarningsState>(
                  builder: (context, state) {
                    if ((state.isInitialLoading || state.isRefreshing) &&
                        state.items.isEmpty) {
                      return ListView.separated(
                        padding: UIUtils.cardsPadding(screenType),
                        separatorBuilder: (context, index) =>
                            SizedBox(height: UIUtils.gapMD(screenType)),
                        itemCount: 10,
                        itemBuilder: (context, index) => CardShimmer(
                          type: 'earning',
                          screenType: screenType,
                        ),
                      );
                    }

                    if (state.error != null && state.items.isEmpty) {
                      return EmptyStateWidget(
                        svgPath: ImagesPath.noOrderFoundSvg,
                        title:
                            l10n?.somethingWentWrong ??
                            'Seems like there is some issue',
                        subtitle:
                            l10n?.tryAgainLater ?? 'Please try again later',
                        actionText: l10n?.tryAgain ?? 'Try Again',
                        onAction: () {
                          context.read<SettledEarningsBloc>().add(
                            const LoadSettledEarningsInitial(),
                          );
                        },
                      );
                    }

                    return _buildPaginatedEarningsList(
                      context,
                      state.items,
                      l10n,
                      isPaginating: state.isPaginating,
                      scrollController: _settledScrollController,
                      onRefresh: () async {
                        _searchController.clear();
                        context.read<SettledEarningsBloc>().add(
                          const LoadSettledEarningsInitial(),
                        );
                      },
                      isSettled: true,
                      screenType: screenType,
                      isInitialLoading: state.isInitialLoading,
                    );
                  },
                ),
                Column(
                  children: [
                    // Credit/Debit Toggles (Payouts / Return & deductions)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: UIUtils.gapMD(screenType),
                        vertical: UIUtils.gapSM(screenType),
                      ),
                      child: CustomDropdown<EarningType>(
                        value: _selectedUnsettledType,
                        items: [
                          CustomDropdownItem(
                            label: 'Payouts',
                            value: EarningType.credit,
                          ),
                          CustomDropdownItem(
                            label: 'Return & deductions',
                            value: EarningType.debit,
                          ),
                        ],
                        onChanged: (type) {
                          if (type != null && _selectedUnsettledType != type) {
                            setState(() {
                              _selectedUnsettledType = type;
                            });
                            context.read<UnsettledEarningsBloc>().add(
                              ChangeUnsettledType(type),
                            );
                          }
                        },
                        hint: 'Select Filter',
                      ),
                    ),
                    Expanded(
                      child:
                          BlocBuilder<
                            UnsettledEarningsBloc,
                            UnsettledEarningsState
                          >(
                            builder: (context, state) {
                              if ((state.isInitialLoading ||
                                      state.isRefreshing) &&
                                  state.items.isEmpty) {
                                return ListView.separated(
                                  padding: UIUtils.cardsPadding(screenType),
                                  separatorBuilder: (context, index) =>
                                      SizedBox(
                                        height: UIUtils.gapMD(screenType),
                                      ),
                                  itemCount: 10,
                                  itemBuilder: (context, index) => CardShimmer(
                                    type: 'earning',
                                    screenType: screenType,
                                  ),
                                );
                              }

                              if (state.error != null && state.items.isEmpty) {
                                return EmptyStateWidget(
                                  svgPath: ImagesPath.noOrderFoundSvg,
                                  title:
                                      l10n?.somethingWentWrong ??
                                      'Seems like there is some issue',
                                  subtitle:
                                      l10n?.tryAgainLater ??
                                      'Please try again later',
                                  actionText: l10n?.tryAgain ?? 'Try Again',
                                  onAction: () {
                                    context.read<UnsettledEarningsBloc>().add(
                                      const LoadUnsettledEarningsInitial(),
                                    );
                                  },
                                );
                              }

                              return _buildPaginatedEarningsList(
                                context,
                                state.items,
                                l10n,
                                isPaginating: state.isPaginating,
                                scrollController: _unsettledScrollController,
                                onRefresh: () async {
                                  _searchController.clear();
                                  context.read<UnsettledEarningsBloc>().add(
                                    LoadUnsettledEarningsInitial(
                                      type: _selectedUnsettledType,
                                    ),
                                  );
                                },
                                isSettled: false,
                                screenType: screenType,
                                isInitialLoading: state.isInitialLoading,
                              );
                            },
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginatedEarningsList(
    BuildContext context,
    List<EarningData> earnings,
    AppLocalizations? l10n, {
    required bool isPaginating,
    required ScrollController scrollController,
    required Future<void> Function() onRefresh,
    required bool isSettled,
    required ScreenType screenType,
    required bool isInitialLoading,
  }) {
    if (earnings.isEmpty) {
      return EmptyStateWidget(
        svgPath: ImagesPath.noProductFoundSvg,
        title: l10n?.noEarningsFound ?? 'No earnings found',
        subtitle: l10n?.noEarningsYet ?? 'You have not any earnings yet',
        actionText: l10n?.refresh ?? 'Refresh',
        onAction: onRefresh,
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryColor,
      onRefresh: onRefresh,
      child: ListView.separated(
        controller: scrollController,
        padding: UIUtils.cardsPadding(screenType),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: earnings.isEmpty && isInitialLoading
            ? 10
            : earnings.length + (isPaginating ? 10 : 0),
        separatorBuilder: (context, index) =>
            SizedBox(height: UIUtils.gapMD(screenType)),
        itemBuilder: (context, index) {
          if (index >= earnings.length) {
            return CardShimmer(type: 'earning', screenType: screenType);
          }

          final earning = earnings[index];

          return GestureDetector(
            onTap: () {
              final orderId = earning.sellerOrderId;

              if (orderId > 0) {
                context.push('${AppRoutes.orderDetails}/$orderId');
              }
              debugPrint('Redirecting to order details');
            },
            child: EarningCard(earning: earning, screenType: screenType),
          );
        },
      ),
    );
  }
}
