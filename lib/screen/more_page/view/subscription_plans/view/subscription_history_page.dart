import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/bloc/screen_size/screen_size_bloc.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/bloc/current_subscription/current_subscription_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/bloc/my_subscriptions/subscription_history_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/widgets/current_subscription_header.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/widgets/subscription_history_card.dart';
import 'package:hyper_local_seller/utils/image_path.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/card_shimmers.dart';
import 'package:hyper_local_seller/widgets/custom/custom_loading_indicator.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/widgets/custom/custom_shimmer.dart';
import 'package:hyper_local_seller/widgets/ui/empty_state_widget.dart';

class SubscriptionHistoryPage extends StatefulWidget {
  const SubscriptionHistoryPage({super.key});

  @override
  State<SubscriptionHistoryPage> createState() =>
      _SubscriptionHistoryPageState();
}

class _SubscriptionHistoryPageState extends State<SubscriptionHistoryPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<SubscriptionHistoryBloc>().add(
      LoadSubscriptionHistoryInitial(),
    );
    context.read<CurrentSubscriptionBloc>().add(FetchCurrentSubscription());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<SubscriptionHistoryBloc>().add(
        LoadMoreSubscriptionHistory(),
      );
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
    return BlocBuilder<ScreenSizeBloc, ScreenSizeState>(
      builder: (context, screenSizeState) {
        final screenType = screenSizeState.screenType;
        return CustomScaffold(
          showAppbar: true,
          title:
              // l10n?.mySubscription ??
              'My Subscription',
          centerTitle: true,
          body: BlocBuilder<CurrentSubscriptionBloc, CurrentSubscriptionState>(
            builder: (context, currentSubState) {
              return BlocBuilder<
                SubscriptionHistoryBloc,
                SubscriptionHistoryState
              >(
                builder: (context, historyState) {
                  if (historyState.error != null &&
                      historyState.items.isEmpty) {
                    return EmptyStateWidget(
                      svgPath: ImagesPath.noOrderFoundSvg,
                      title:
                          l10n?.somethingWentWrong ??
                          'Seems like there is some issue',
                      subtitle: l10n?.tryAgainLater ?? 'Please try again later',
                      actionText: l10n?.tryAgain ?? 'Try Again',
                      onAction: () {
                        context.read<SubscriptionHistoryBloc>().add(
                          RefreshSubscriptionHistory(),
                        );
                        context.read<CurrentSubscriptionBloc>().add(
                          FetchCurrentSubscription(),
                        );
                      },
                    );
                  }

                  final items = historyState.items;
                  final hasMore = historyState.hasMore;
                  final isPaginating = historyState.isPaginating;

                  return RefreshIndicator(
                    color: AppColors.primaryColor,
                    onRefresh: () async {
                      context.read<SubscriptionHistoryBloc>().add(
                        RefreshSubscriptionHistory(),
                      );
                      context.read<CurrentSubscriptionBloc>().add(
                        FetchCurrentSubscription(),
                      );
                    },
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      controller: _scrollController,
                      slivers: [
                        // Current Plan Section
                        if (currentSubState is CurrentSubscriptionLoading)
                          SliverToBoxAdapter(
                            child: CurrentSubscriptionHeaderShimmer(
                              screenType: screenType,
                            ),
                          )
                        else if (currentSubState is CurrentSubscriptionLoaded ||
                            currentSubState is CurrentSubscriptionPending)
                          SliverToBoxAdapter(
                            child: CurrentSubscriptionHeader(
                              planData:
                                  currentSubState is CurrentSubscriptionLoaded
                                      ? currentSubState.data
                                      : (currentSubState
                                              as CurrentSubscriptionPending)
                                          .data,
                              screenType: screenType,
                            ),
                          ),

                        // Section Title
                        if (items.isNotEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                UIUtils.gapMD(screenType),
                                UIUtils.gapSM(screenType),
                                UIUtils.gapMD(screenType),
                                UIUtils.gapSM(screenType),
                              ),
                              child: Text(
                                l10n?.subHistory ?? 'Subscription History',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                        // History List
                        SliverPadding(
                          padding: UIUtils.cardsPadding(screenType),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if ((historyState.isInitialLoading ||
                                        historyState.isRefreshing)) {
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom: UIUtils.gapMD(screenType),
                                    ),
                                    child: CardShimmer(
                                      type: 'subscription_history',
                                      screenType: screenType,
                                    ),
                                  );
                                }

                                if (index >= items.length) {
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom: UIUtils.gapMD(screenType),
                                    ),
                                    child: CardShimmer(
                                      type: 'subscription_history',
                                      screenType: screenType,
                                    ),
                                  );
                                }

                                final subscriptionEntry = items[index];
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: UIUtils.gapMD(screenType),
                                  ),
                                  child: SubscriptionHistoryCard(
                                    subscriptionHistoryEntry: subscriptionEntry,
                                    screenType: screenType,
                                  ),
                                );
                              },
                              childCount:
                                  (historyState.isInitialLoading ||
                                           historyState.isRefreshing)
                                  ? 10
                                  : items.length +
                                        (hasMore ? (isPaginating ? 10 : 1) : 0),
                            ),
                          ),
                        ),

                        // No history empty state (only if no active plan either)
                        if (items.isEmpty &&
                            !historyState.isInitialLoading &&
                            !historyState.isRefreshing &&
                            currentSubState is! CurrentSubscriptionLoaded &&
                            currentSubState is! CurrentSubscriptionPending)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: EmptyStateWidget(
                              svgPath: ImagesPath.noProductFoundSvg,
                              title:
                                  l10n?.noSubHistory ??
                                  'No subscription history found',
                              subtitle:
                                  l10n?.noSubHistorySubtitle ??
                                  "Seems like you haven't subscribed to any subscription yet",
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
