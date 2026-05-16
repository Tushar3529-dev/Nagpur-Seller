import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/utils/time_utils.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/card_shimmers.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';

import 'package:hyper_local_seller/utils/image_path.dart';
import 'package:hyper_local_seller/widgets/ui/empty_state_widget.dart';

import '../bloc/transactions_bloc/transactions_history_bloc.dart';

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<TransactionsHistoryBloc>().add(LoadTransactionsInitial());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<TransactionsHistoryBloc>().add(LoadMoreTransactions());
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
    final screenType = context.screenType;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return CustomScaffold(
      title: l10n?.transactions ?? 'Transactions',
      showAppbar: true,
      centerTitle: true,
      body: BlocBuilder<TransactionsHistoryBloc, TransactionsHistoryState>(
        builder: (context, state) {
          if ((state.isInitialLoading || state.isRefreshing) && state.items.isEmpty) {
            return ListView.separated(
              padding: UIUtils.pagePadding(screenType),
              separatorBuilder: (context, index) =>
                  SizedBox(height: UIUtils.gapMD(screenType)),
              itemCount: 10,
              itemBuilder: (context, index) =>
                  CardShimmer(type: 'walletHistory', screenType: screenType),
            );
          }

          if (state.error != null && state.items.isEmpty) {
            return EmptyStateWidget(
              svgPath: ImagesPath.noOrderFoundSvg,
              title:
                  l10n?.somethingWentWrong ??
                  'Seems like there is some issue',
              subtitle: l10n?.tryAgainLater ?? 'Please try again later',
              actionText: l10n?.tryAgain ?? 'Try Again',
              onAction: () {
                context.read<TransactionsHistoryBloc>().add(
                  RefreshTransactionsHistory(),
                );
              },
            );
          }

          final history = state.items;
          if (history.isEmpty) {
            return EmptyStateWidget(
              svgPath: ImagesPath.noOrderFoundSvg,
              title: l10n?.noTransactionsFound ?? 'No transactions found',
              subtitle:
                  l10n?.noTransactionsSubtitle ??
                  'You have not performed any transactions yet',
              actionText: l10n?.refresh ?? 'Refresh',
              onAction: () {
                context.read<TransactionsHistoryBloc>().add(
                  RefreshTransactionsHistory(),
                );
              },
            );
          }

          return RefreshIndicator(
            color: AppColors.primaryColor,
            onRefresh: () async {
              context.read<TransactionsHistoryBloc>().add(
                RefreshTransactionsHistory(),
              );
            },
            child: ListView.separated(
              controller: _scrollController,
              padding: UIUtils.pagePadding(screenType),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: history.length + (state.isPaginating ? 1 : 0),
              separatorBuilder: (context, index) =>
                  SizedBox(height: UIUtils.gapMD(screenType)),
              itemBuilder: (context, index) {
                if (index >= history.length) {
                  return CardShimmer(
                    type: 'walletHistory',
                    screenType: screenType,
                  );
                }

                final item = history[index];
                final isCredit =
                    item.type.toLowerCase() == 'deposit' ||
                    item.type.toLowerCase() == 'credit';

                return Container(
                  padding: UIUtils.tilePadding(screenType),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(
                      UIUtils.radiusMD(screenType),
                    ),
                    border: Border.all(
                      color: theme.dividerColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: UIUtils.gapSM(screenType),
                              vertical: UIUtils.gapXS(screenType),
                            ),
                            decoration: BoxDecoration(
                              color: isCredit
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                UIUtils.radiusSM(screenType),
                              ),
                            ),
                            child: Text(
                              item.type.toUpperCase(),
                              style: TextStyle(
                                color: isCredit ? Colors.green : Colors.red,
                                fontSize: UIUtils.caption(screenType),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '${isCredit ? "+" : "-"}${HiveStorage.currencySymbol}${item.amount}',
                            style: TextStyle(
                              fontSize: UIUtils.tileTitle(screenType),
                              fontWeight: FontWeight.bold,
                              color: isCredit ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: UIUtils.gapSM(screenType)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.message ?? '',
                              style: TextStyle(
                                fontSize: UIUtils.body(screenType),
                                color: theme.textTheme.bodyMedium?.color,
                              ),
                            ),
                          ),
                          Text(
                            TimeUtils.formatTimeAgo(
                              item.createdAt,
                              context,
                              type: TimeFormatType.transactions,
                            ),
                            style: TextStyle(
                              fontSize: UIUtils.caption(screenType),
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
