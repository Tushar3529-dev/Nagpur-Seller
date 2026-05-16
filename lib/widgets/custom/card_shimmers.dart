// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_shimmer.dart';

class CardShimmer extends StatelessWidget {
  final String type;
  final ScreenType screenType;

  const CardShimmer({super.key, required this.type, required this.screenType});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(UIUtils.radiusLG(screenType)),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Shimmer
          Padding(
            padding: UIUtils.cardPadding(screenType),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomShimmer(width: 60, height: UIUtils.body(screenType)),
                CustomShimmer(
                  width: 24,
                  height: 24,
                  borderRadius: BorderRadius.circular(12),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          Padding(
            padding: UIUtils.cardPadding(screenType),
            child: _buildShimmerBody(),
          ),
          if (type == 'store') ...[
            Divider(
              height: 1,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            Padding(
              padding: UIUtils.cardPadding(screenType),
              child: CustomShimmer(
                width: double.infinity,
                height: 48,
                borderRadius: BorderRadius.circular(
                  UIUtils.radiusLG(screenType),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShimmerBody() {
    switch (type) {
      case 'brand':
      case 'product':
      case 'category':
        return _buildRowShimmer();
      case 'taxGroup':
        return _buildTaxGroupShimmer();
      case 'store':
        return _buildStoreShimmer();
      case 'attribute':
        return _buildAttributeShimmer();
      case 'attributeValue':
        return _buildAttributeValueShimmer();
      case 'order':
        return _buildOrderShimmer();
      case 'earning':
        return _buildEarningShimmer();
      case 'walletBalance':
        return _buildWalletBalanceShimmer();
      case 'walletChip':
        return _buildWalletChipShimmer();
      case 'walletHistory':
        return _buildWalletHistoryShimmer();
      case 'faq':
        return _buildFaqShimmer();
      case 'roles':
        return _buildRolesShimmer();
      case 'permission':
        return _buildPermissionShimmer();
      case 'system_user':
        return _buildSystemUserShimmer();
      case 'notification':
        return _buildNotificationShimmer();
      case 'subscription_history':
        return _buildSubscriptionHistoryShimmer();
      default:
        return _buildRowShimmer();
    }
  }

  Widget _buildRolesShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomShimmer(width: 150, height: UIUtils.tileTitle(screenType)),
        SizedBox(height: UIUtils.gapXS(screenType)),
        CustomShimmer(width: 100, height: UIUtils.caption(screenType)),
        SizedBox(height: UIUtils.gapSM(screenType)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CustomShimmer(width: 20, height: 20),
                SizedBox(width: 8),
                CustomShimmer(width: 80, height: UIUtils.caption(screenType)),
              ],
            ),
            CustomShimmer(width: 80, height: UIUtils.caption(screenType)),
          ],
        ),
      ],
    );
  }

  Widget _buildPermissionShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomShimmer(width: 120, height: UIUtils.body(screenType)),
        SizedBox(height: UIUtils.gapMD(screenType)),
        for (int i = 0; i < 3; i++) ...[
          Row(
            children: [
              CustomShimmer(
                width: 24,
                height: 24,
                borderRadius: BorderRadius.circular(4),
              ),
              SizedBox(width: 12),
              CustomShimmer(width: 100, height: 16),
            ],
          ),
          SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildSystemUserShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomShimmer(width: 180, height: UIUtils.tileTitle(screenType)),
        SizedBox(height: UIUtils.gapSM(screenType)),
        CustomShimmer(width: 120, height: UIUtils.caption(screenType)),
        SizedBox(height: UIUtils.gapMD(screenType)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomShimmer(width: 140, height: UIUtils.body(screenType)),
            CustomShimmer(width: 100, height: UIUtils.body(screenType)),
          ],
        ),
        SizedBox(height: UIUtils.gapSM(screenType)),
        CustomShimmer(width: 100, height: UIUtils.caption(screenType)),
      ],
    );
  }

  Widget _buildRowShimmer() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomShimmer(
          width: UIUtils.avatarXL(screenType),
          height: UIUtils.avatarXL(screenType),
          borderRadius: BorderRadius.circular(UIUtils.radiusSM(screenType)),
        ),
        SizedBox(width: UIUtils.gapMD(screenType)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomShimmer(width: 120, height: UIUtils.tileTitle(screenType)),
              SizedBox(height: UIUtils.gapXS(screenType)),
              CustomShimmer(width: 80, height: UIUtils.caption(screenType)),
              SizedBox(height: UIUtils.gapSM(screenType)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomShimmer(width: 60, height: 16),
                  CustomShimmer(width: 40, height: 16),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTaxGroupShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomShimmer(width: 150, height: UIUtils.tileTitle(screenType)),
        SizedBox(height: UIUtils.gapSM(screenType)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomShimmer(width: 60, height: UIUtils.body(screenType)),
            CustomShimmer(width: 100, height: UIUtils.body(screenType)),
          ],
        ),
      ],
    );
  }

  Widget _buildStoreShimmer() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomShimmer(
              width: UIUtils.avatarXL(screenType),
              height: UIUtils.avatarXL(screenType),
              borderRadius: BorderRadius.circular(UIUtils.radiusSM(screenType)),
            ),
            SizedBox(width: UIUtils.gapMD(screenType)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomShimmer(
                    width: 150,
                    height: UIUtils.tileTitle(screenType),
                  ),
                  SizedBox(height: UIUtils.gapXS(screenType)),
                  Row(
                    children: [
                      CustomShimmer(width: 60, height: 18),
                      SizedBox(width: 8),
                      CustomShimmer(width: 60, height: 18),
                      SizedBox(width: 8),
                      CustomShimmer(width: 50, height: 18),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: UIUtils.gapMD(screenType)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CustomShimmer(
                  width: 20,
                  height: 20,
                  borderRadius: BorderRadius.circular(10),
                ),
                SizedBox(width: 8),
                CustomShimmer(width: 100, height: 16),
              ],
            ),
            CustomShimmer(width: 40, height: 14),
          ],
        ),
        SizedBox(height: UIUtils.gapMD(screenType)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CustomShimmer(
                  width: 20,
                  height: 20,
                  borderRadius: BorderRadius.circular(10),
                ),
                SizedBox(width: 8),
                CustomShimmer(width: 100, height: 16),
              ],
            ),
            CustomShimmer(width: 40, height: 16),
          ],
        ),
      ],
    );
  }

  Widget _buildAttributeValueShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomShimmer(width: 150, height: UIUtils.tileTitle(screenType)),
            CustomShimmer(
              width: 32,
              height: 32,
              borderRadius: BorderRadius.circular(16),
            ),
          ],
        ),
        SizedBox(height: UIUtils.gapMD(screenType)),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            CustomShimmer(width: 80, height: UIUtils.caption(screenType)),
          ],
        ),
      ],
    );
  }

  Widget _buildAttributeShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomShimmer(width: 180, height: UIUtils.tileTitle(screenType)),
            CustomShimmer(
              width: 60,
              height: 24,
              borderRadius: BorderRadius.circular(6),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomShimmer(width: 100, height: 16),
            CustomShimmer(width: 40, height: 16),
          ],
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomShimmer(width: 100, height: 16),
            CustomShimmer(width: 100, height: 16),
          ],
        ),
      ],
    );
  }

  Widget _buildOrderShimmer() {
    return Padding(
      padding: UIUtils.cardPadding(screenType),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomShimmer(
                width: UIUtils.avatarXL(screenType),
                height: UIUtils.avatarXL(screenType),
                borderRadius: BorderRadius.circular(
                  UIUtils.radiusSM(screenType),
                ),
              ),
              SizedBox(width: UIUtils.gapMD(screenType)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomShimmer(
                          width: 150,
                          height: UIUtils.body(screenType),
                        ),
                        CustomShimmer(
                          width: 70,
                          height: 20,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    CustomShimmer(
                      width: 100,
                      height: UIUtils.caption(screenType),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomShimmer(width: 100, height: 14),
              CustomShimmer(width: 120, height: 14),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [CustomShimmer(width: 80, height: 14)],
          ),
        ],
      ),
    );
  }

  Widget _buildEarningShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomShimmer(width: 80, height: UIUtils.tileTitle(screenType)),
            CustomShimmer(width: 60, height: UIUtils.caption(screenType)),
          ],
        ),
        SizedBox(height: UIUtils.gapSM(screenType)),
        CustomShimmer(width: 200, height: UIUtils.body(screenType)),
        SizedBox(height: UIUtils.gapXS(screenType)),
        Row(
          children: [
            CustomShimmer(
              width: 16,
              height: 16,
              borderRadius: BorderRadius.circular(8),
            ),
            SizedBox(width: UIUtils.gapXS(screenType)),
            CustomShimmer(width: 120, height: UIUtils.caption(screenType)),
          ],
        ),
        SizedBox(height: UIUtils.gapMD(screenType)),
        Divider(height: 1, color: Colors.grey.withValues(alpha: 0.1)),
        SizedBox(height: UIUtils.gapMD(screenType)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomShimmer(
              width: 50,
              height: 18,
              borderRadius: BorderRadius.circular(4),
            ),
            CustomShimmer(width: 80, height: 24),
          ],
        ),
      ],
    );
  }

  Widget _buildWalletBalanceShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomShimmer(width: 120, height: UIUtils.body(screenType)),
        SizedBox(height: UIUtils.gapSM(screenType)),
        CustomShimmer(width: 180, height: 40),
        SizedBox(height: UIUtils.gapXS(screenType)),
        CustomShimmer(width: 220, height: UIUtils.caption(screenType)),
        SizedBox(height: UIUtils.gapLG(screenType)),
        CustomShimmer(
          width: double.infinity,
          height: 48,
          borderRadius: BorderRadius.circular(UIUtils.radiusMD(screenType)),
        ),
      ],
    );
  }

  Widget _buildWalletChipShimmer() {
    return Row(
      children: [
        CustomShimmer(
          width: 12,
          height: 12,
          borderRadius: BorderRadius.circular(6),
        ),
        SizedBox(width: UIUtils.gapSM(screenType)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomShimmer(width: 60, height: UIUtils.caption(screenType)),
              SizedBox(height: 4),
              CustomShimmer(width: 80, height: UIUtils.tileTitle(screenType)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWalletHistoryShimmer() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomShimmer(
              width: 70,
              height: 22,
              borderRadius: BorderRadius.circular(UIUtils.radiusSM(screenType)),
            ),
            CustomShimmer(width: 80, height: UIUtils.tileTitle(screenType)),
          ],
        ),
        SizedBox(height: UIUtils.gapSM(screenType)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomShimmer(width: 150, height: UIUtils.body(screenType)),
            CustomShimmer(width: 60, height: UIUtils.caption(screenType)),
          ],
        ),
        SizedBox(height: UIUtils.gapSM(screenType)),
        Row(
          children: [
            CustomShimmer(width: 100, height: UIUtils.caption(screenType)),
          ],
        ),
      ],
    );
  }

  Widget _buildFaqShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomShimmer(
                    width: 200,
                    height: UIUtils.tileTitle(screenType),
                  ),
                  SizedBox(height: 4),
                  CustomShimmer(
                    width: 150,
                    height: UIUtils.tileTitle(screenType),
                  ),
                ],
              ),
            ),
            CustomShimmer(
              width: 60,
              height: 20,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
        SizedBox(height: UIUtils.gapMD(screenType)),
        CustomShimmer(width: 80, height: UIUtils.body(screenType)),
        SizedBox(height: UIUtils.gapXS(screenType)),
        CustomShimmer(width: double.infinity, height: 16),
        SizedBox(height: 4),
        CustomShimmer(width: double.infinity, height: 16),
        SizedBox(height: 4),
        CustomShimmer(width: 180, height: 16),
      ],
    );
  }

  Widget _buildNotificationShimmer() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon placeholder
        CustomShimmer(
          width: 40,
          height: 40,
          borderRadius: BorderRadius.circular(10),
        ),
        SizedBox(width: 12),

        // Main content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: CustomShimmer(width: 160, height: 16), // title
                  ),
                  SizedBox(width: 8),
                  CustomShimmer(width: 44, height: 12), // time
                ],
              ),
              SizedBox(height: 6),
              CustomShimmer(
                width: double.infinity,
                height: 14,
              ), // message line 1
              SizedBox(height: 4),
              CustomShimmer(
                width: double.infinity * 0.85,
                height: 14,
              ), // message line 2
            ],
          ),
        ),

        SizedBox(width: 8),

        // Unread dot placeholder
        CustomShimmer(
          width: 8,
          height: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildSubscriptionHistoryShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Plan name + status chip row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Plan name
                  CustomShimmer(
                    width: 180,
                    height: UIUtils.sectionTitle(screenType),
                  ),
                  SizedBox(height: UIUtils.gapXS(screenType)),
                  // Purchased on date
                  CustomShimmer(
                    width: 140,
                    height: UIUtils.tileSubtitle(screenType),
                  ),
                ],
              ),
            ),
            // Status badge
            CustomShimmer(
              width: 70,
              height: 28,
              borderRadius: BorderRadius.circular(UIUtils.radiusXL(screenType)),
            ),
          ],
        ),

        SizedBox(height: UIUtils.gapMD(screenType)),
        Divider(height: 1, color: Colors.grey[100]),

        SizedBox(height: UIUtils.gapMD(screenType)),

        // Price + View Details row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Price
            CustomShimmer(width: 100, height: UIUtils.sectionTitle(screenType)),
            // View Details link + icon
            Row(
              children: [
                CustomShimmer(width: 90, height: UIUtils.body(screenType)),
                SizedBox(width: 4),
                CustomShimmer(
                  width: 20,
                  height: 20,
                  borderRadius: BorderRadius.circular(10),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
