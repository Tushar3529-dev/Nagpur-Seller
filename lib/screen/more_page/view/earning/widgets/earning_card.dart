import 'package:flutter/material.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/utils/time_utils.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import '../model/earnings_model.dart';

class EarningCard extends StatelessWidget {
  final EarningData earning;
  final ScreenType screenType;

  const EarningCard({
    super.key,
    required this.earning,
    required this.screenType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: UIUtils.tilePadding(screenType),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(UIUtils.radiusMD(screenType)),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Order ID and Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order ID: ${earning.orderId}',
                style: TextStyle(
                  fontSize: UIUtils.tileTitle(screenType),
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.tertiary,
                ),
              ),
              Text(
                TimeUtils.formatTimeAgo(
                  earning.postedAt,
                  context,
                  type: TimeFormatType.earnings,
                ),
                style: TextStyle(
                  fontSize: UIUtils.caption(screenType),
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          SizedBox(height: UIUtils.gapMD(screenType)),

          // Row 2: Store Name
          Row(
            children: [
              Icon(
                Icons.storefront_outlined,
                size: 18,
                color: Colors.grey.shade600,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  earning.storeName,
                  style: TextStyle(
                    fontSize: UIUtils.tileSubtitle(screenType),
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),

          // Row 3: Product Title
          Row(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 18,
                color: Colors.grey.shade600,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  earning.productTitle,
                  style: TextStyle(
                    fontSize: UIUtils.tileSubtitle(screenType),
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: UIUtils.gapMD(screenType)),

          // Row 4: Seller Earning
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Seller Earning',
                        style: TextStyle(
                          fontSize: UIUtils.tileTitle(screenType),
                          color: Colors.grey.shade500,
                        ),
                      ),
                      Text(
                        earning.amountFormatted,
                        style: TextStyle(
                          fontSize: UIUtils.tileSubtitle(screenType),
                          fontWeight: FontWeight.bold,
                          color: earning.settlementStatus == 'settled'
                              ? Colors.green.shade600
                              : Colors.orangeAccent,
                        ),
                      ),
                    ],
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
