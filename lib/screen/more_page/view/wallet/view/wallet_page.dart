// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/screen/more_page/view/wallet/bloc/wallet_bloc/wallet_bloc.dart';
import 'package:hyper_local_seller/utils/image_path.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/router/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local_seller/utils/time_utils.dart';
import 'package:hyper_local_seller/widgets/custom/card_shimmers.dart';
import 'package:hyper_local_seller/widgets/custom/custom_svg.dart';
import 'package:hyper_local_seller/config/app_permissions.dart';
import 'package:hyper_local_seller/utils/permission_checker.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  @override
  void initState() {
    super.initState();
    context.read<WalletBloc>().add(FetchWallet());
    context.read<WalletBloc>().add(LoadWithdrawalHistoryInitial());
    context.read<WalletBloc>().add(FetchTransactions());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screenType = context.screenType;
    final theme = Theme.of(context);

    return CustomScaffold(
      title: l10n?.wallet ?? "Wallet",
      showAppbar: true,
      centerTitle: true,
      body: RefreshIndicator(
        color: AppColors.primaryColor,
        onRefresh: () async {
          context.read<WalletBloc>().add(FetchWallet());
          context.read<WalletBloc>().add(LoadWithdrawalHistoryInitial());
          context.read<WalletBloc>().add(FetchTransactions());
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: UIUtils.pagePadding(screenType),
          child: BlocBuilder<WalletBloc, WalletState>(
            builder: (context, state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Available Balance Card
                  _buildBalanceCard(context, l10n, screenType, state),

                  SizedBox(height: UIUtils.gapLG(screenType)),

                  // Status Chips Row
                  _buildStatusChips(context, l10n, screenType, state),

                  SizedBox(height: UIUtils.gapXL(screenType)),

                  // Withdrawal History Header with "View All"
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n?.withdrawalHistory ?? 'Withdrawal History',
                        style: TextStyle(
                          fontSize: UIUtils.sectionTitle(screenType),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          if (!PermissionChecker.hasPermission(
                            AppPermissions.withdrawalView,
                          )) {
                            showCustomSnackbar(
                              context: context,
                              message:
                                  l10n?.noPermissionViewWithdrawals ??
                                  'You do not have permission to view withdrawal history.',
                              isWarning: true,
                            );
                            return;
                          }
                          context.pushNamed('/withdraw-history');
                        },
                        child: Text(
                          l10n?.viewAll ?? 'View All',
                          style: TextStyle(
                            fontSize: UIUtils.caption(screenType),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: UIUtils.gapMD(screenType)),

                  // Withdrawal History List (Preview)
                  _buildWithdrawalHistoryList(
                    context,
                    l10n,
                    screenType,
                    theme,
                    state,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(
    BuildContext context,
    AppLocalizations? l10n,
    ScreenType screenType,
    WalletState state,
  ) {
    if (state.walletStatus == WalletStatus.loading &&
        state.walletData == null) {
      return CardShimmer(type: 'walletBalance', screenType: screenType);
    }
    String balance = state.walletData?.balance ?? '0.00';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(UIUtils.gapLG(screenType)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0066FF), Color(0xFF0052CC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(UIUtils.radiusLG(screenType)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.availableBalance ?? 'Available Balance',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: UIUtils.body(screenType),
            ),
          ),
          SizedBox(height: UIUtils.gapSM(screenType)),
          Text(
            '${HiveStorage.currencySymbol}$balance',
            style: TextStyle(
              color: Colors.white,
              fontSize: UIUtils.pageTitle(screenType) * 1.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: UIUtils.gapXS(screenType)),
          Text(
            l10n?.addForAccountAndEarnedPayments ??
                'Add for Account & Earned Payments',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: UIUtils.caption(screenType),
            ),
          ),
          SizedBox(height: UIUtils.gapLG(screenType)),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (!PermissionChecker.hasPermission(
                  AppPermissions.withdrawalRequest,
                )) {
                  showCustomSnackbar(
                    context: context,
                    message:
                        l10n?.noPermissionRequestWithdrawal ??
                        'You do not have permission to request withdrawal.',
                    isWarning: true,
                  );
                  return;
                }
                context.pushNamed('/withdraw-request');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  vertical: UIUtils.gapMD(screenType),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    UIUtils.radiusMD(screenType),
                  ),
                ),
              ),
              child: Text(
                l10n?.requestWithdraw ?? 'Request Withdraw',
                style: TextStyle(
                  fontSize: UIUtils.tileTitle(screenType),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChips(
    BuildContext context,
    AppLocalizations? l10n,
    ScreenType screenType,
    WalletState state,
  ) {
    if (state.walletStatus == WalletStatus.loading &&
        state.walletData == null) {
      return Row(
        children: [
          Expanded(
            child: CardShimmer(type: 'walletChip', screenType: screenType),
          ),
          SizedBox(width: UIUtils.gapMD(screenType)),
          Expanded(
            child: CardShimmer(type: 'walletChip', screenType: screenType),
          ),
        ],
      );
    }
    String blockedBalance = state.walletData?.blockedBalance ?? '0.00';

    return Row(
      children: [
        Expanded(
          flex: 9,
          child: _buildStatusChip(
            context,
            label: l10n?.blocked ?? "Blocked",
            amount: '${HiveStorage.currencySymbol}$blockedBalance',
            color: Colors.red,
            screenType: screenType,
          ),
        ),
        SizedBox(width: UIUtils.gapMD(screenType)),
        Expanded(
          flex: 10,
          child: InkWell(
            onTap: () {
              context.pushNamed(AppRoutes.transactionHistory);
            },
            borderRadius: BorderRadius.circular(UIUtils.radiusMD(screenType)),
            child: Container(
              padding: UIUtils.tilePadding2(screenType),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(
                  UIUtils.radiusMD(screenType),
                ),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    padding: UIUtils.tilePadding(screenType),

                    child: Icon(
                      Icons.history_rounded,
                      color: Colors.blue,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: UIUtils.gapXS(screenType)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n?.transactions ?? 'Transactions',
                          style: TextStyle(
                            fontSize: UIUtils.tileSubtitle(screenType),
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          l10n?.viewAll ?? 'View All',
                          style: TextStyle(
                            fontSize: UIUtils.tileTitle(screenType),
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWithdrawalHistoryList(
    BuildContext context,
    AppLocalizations? l10n,
    ScreenType screenType,
    ThemeData theme,
    WalletState state,
  ) {
    if (state.historyStatus == WalletStatus.loading &&
        state.withdrawalHistory.isEmpty) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        separatorBuilder: (context, index) =>
            SizedBox(height: UIUtils.gapMD(screenType)),
        itemBuilder: (context, index) =>
            CardShimmer(type: 'walletHistory', screenType: screenType),
      );
    }

    final history = state.withdrawalHistory;
    if (history.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(UIUtils.gapLG(screenType)),
          child: Text('No Data'),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length,
      separatorBuilder: (context, index) =>
          SizedBox(height: UIUtils.gapMD(screenType)),
      itemBuilder: (context, index) {
        final item = history[index];
        final isPending = item.status.toLowerCase() == 'pending';
        final isApproved =
            item.status.toLowerCase() == 'approved' ||
            item.status.toLowerCase() == 'completed';

        return Container(
          padding: UIUtils.tilePadding(screenType),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(UIUtils.radiusMD(screenType)),
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
              ...[
                SizedBox(height: UIUtils.gapSM(screenType)),
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
    );
  }

  Widget _buildStatusChip(
    BuildContext context, {
    required String label,
    required String amount,
    required Color? color,
    required ScreenType screenType,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: UIUtils.tilePadding2(screenType),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(UIUtils.radiusMD(screenType)),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            padding: UIUtils.tilePadding(screenType),
            child: CustomSvg(
              svgPath: ImagesPath.blockedSvg,
              color: AppColors.errorColor,
              height: 16,
              width: 16,
            ),
          ),
          SizedBox(width: UIUtils.gapSM(screenType)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: UIUtils.tileSubtitle(screenType),
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  amount,
                  style: TextStyle(
                    fontSize: UIUtils.tileTitle(screenType),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
