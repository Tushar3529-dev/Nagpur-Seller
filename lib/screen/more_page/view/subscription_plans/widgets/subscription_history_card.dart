import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/router/app_routes.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/model/subscription_history_model.dart';
import 'package:hyper_local_seller/utils/time_utils.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';

class SubscriptionHistoryCard extends StatelessWidget {
  final SubscriptionHistoryEntry subscriptionHistoryEntry;
  final ScreenType screenType;
  const SubscriptionHistoryCard({
    super.key,
    required this.subscriptionHistoryEntry,
    required this.screenType,
  });

  @override
  Widget build(BuildContext context) {
    final status = subscriptionHistoryEntry.status.toUpperCase();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bgColor;
    Color textColor;

    switch (status) {
      case 'ACTIVE':
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF4CAF50);
        break;
      case 'PENDING':
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFF57C00);
        break;
      case 'EXPIRED':
        bgColor = const Color(0xFFF5F5F5);
        textColor = const Color(0xFF616161);
        break;
      case 'CANCELLED':
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFD32F2F);
        break;
      default:
        bgColor = const Color(0xFFF1F3F4);
        textColor = Colors.grey[600]!;
    }

    return Container(
      margin: EdgeInsets.only(top: UIUtils.gapLG(screenType)),
      padding: UIUtils.cardPadding(screenType),
      decoration: BoxDecoration(
        color: isDark
            ? Theme.of(context).colorScheme.surfaceContainer
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(UIUtils.radiusLG(screenType)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subscriptionHistoryEntry.plan?.name ?? 'Plan Name',
                      style: TextStyle(
                        fontSize: UIUtils.sectionTitle(screenType),
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: UIUtils.gapXS(screenType)),
                    Text(
                      TimeUtils.formatTimeAgo(
                        subscriptionHistoryEntry.startDate,
                        context,
                      ),
                      style: TextStyle(
                        fontSize: UIUtils.tileSubtitle(screenType),
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(
                    UIUtils.radiusXL(screenType),
                  ),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: UIUtils.caption(screenType),
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: UIUtils.gapMD(screenType)),
            child: Divider(height: 1, color: Colors.grey[100]),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${HiveStorage.currencySymbol}${subscriptionHistoryEntry.pricePaid}",
                style: TextStyle(
                  fontSize: UIUtils.sectionTitle(screenType),
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              InkWell(
                onTap: () => context.pushNamed(
                  AppRoutes.subscriptionPlanDetails,
                  extra: subscriptionHistoryEntry.plan,
                ),

                child: Row(
                  children: [
                    Text(
                      AppLocalizations.of(context)?.viewDetails ??
                          "View Details",
                      style: TextStyle(
                        fontSize: UIUtils.body(screenType),
                        color: const Color(0xFF2196F3),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: const Color(0xFF2196F3),
                      size: UIUtils.chevronIcon(screenType),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
