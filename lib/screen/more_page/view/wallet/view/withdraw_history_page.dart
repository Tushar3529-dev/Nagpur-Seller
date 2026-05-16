import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/utils/image_path.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/utils/time_utils.dart';
import 'package:hyper_local_seller/widgets/custom/card_shimmers.dart';
import 'package:hyper_local_seller/config/app_permissions.dart';
import 'package:hyper_local_seller/utils/permission_checker.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';
import 'package:hyper_local_seller/widgets/ui/empty_state_widget.dart';

import '../bloc/withdraw_history_bloc/withdraw_history_bloc.dart';

class WithdrawHistoryPage extends StatefulWidget {
  const WithdrawHistoryPage({super.key});

  @override
  State<WithdrawHistoryPage> createState() => _WithdrawHistoryPageState();
}

class _WithdrawHistoryPageState extends State<WithdrawHistoryPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<WithdrawHistoryBloc>().add(LoadHistoryInitial());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<WithdrawHistoryBloc>().add(LoadMoreHistory());
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
    final screenType = context.screenType;
    final theme = Theme.of(context);

    return CustomScaffold(
      title: l10n?.withdrawalHistory ?? 'Withdrawal History',
      showAppbar: true,
      centerTitle: true,
      body: BlocBuilder<WithdrawHistoryBloc, WithdrawHistoryState>(
        builder: (context, state) {
          if (!PermissionChecker.hasPermission(AppPermissions.withdrawalView)) {
            return Center(
              child: Text(
                l10n?.noPermissionViewWithdrawals ??
                    "You don't have permission to view withdrawal history",
              ),
            );
          }
          if ((state.isInitialLoading || state.isRefreshing) &&
              state.items.isEmpty) {
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
                  l10n?.somethingWentWrong ?? 'Seems like there is some issue',
              subtitle: l10n?.tryAgainLater ?? 'Please try again later',
              actionText: l10n?.tryAgain ?? 'Try Again',
              onAction: () {
                context.read<WithdrawHistoryBloc>().add(RefreshHistory());
              },
            );
          }

          if (state.items.isEmpty) {
            return EmptyStateWidget(
              svgPath: ImagesPath.noOrderFoundSvg,
              title: l10n?.noWithdrawHistory ?? 'No withdraw history found',
              subtitle:
                  l10n?.noWithdrawHistoryMessage ??
                  'You have not made any withdrawal requests yet.',
              actionText: l10n?.refresh ?? 'Refresh',
              onAction: () {
                context.read<WithdrawHistoryBloc>().add(RefreshHistory());
              },
            );
          }
          final history = state.items;

          return RefreshIndicator(
            color: AppColors.primaryColor,
            onRefresh: () async {
              context.read<WithdrawHistoryBloc>().add(RefreshHistory());
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
                final isPending = item.status.toLowerCase() == 'pending';
                final isApproved =
                    item.status.toLowerCase() == 'approved' ||
                    item.status.toLowerCase() == 'completed';

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
                              color: isPending
                                  ? Colors.orange.withValues(alpha: 0.1)
                                  : isApproved
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                UIUtils.radiusSM(screenType),
                              ),
                            ),
                            child: Text(
                              item.status.toUpperCase(),
                              style: TextStyle(
                                color: isPending
                                    ? Colors.orange
                                    : isApproved
                                    ? Colors.green
                                    : Colors.red,
                                fontSize: UIUtils.caption(screenType),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '${HiveStorage.currencySymbol}${item.amount}',
                            style: TextStyle(
                              fontSize: UIUtils.tileTitle(screenType),
                              fontWeight: FontWeight.bold,
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
                              type: TimeFormatType.wallet,
                            ),
                            style: TextStyle(
                              fontSize: UIUtils.caption(screenType),
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      if (item.transactionId != null) ...[
                        SizedBox(height: UIUtils.gapMD(screenType)),
                        Row(
                          children: [
                            Text(
                              'ID: ${item.id}',
                              style: TextStyle(
                                fontSize: UIUtils.caption(screenType),
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
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
