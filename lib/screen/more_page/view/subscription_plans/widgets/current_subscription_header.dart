import 'package:flutter/material.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/model/current_plan_model.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local_seller/router/app_routes.dart';
import 'package:hyper_local_seller/widgets/custom/custom_shimmer.dart';

class CurrentSubscriptionHeader extends StatelessWidget {
  final CurrentPlanData planData;
  final ScreenType screenType;

  const CurrentSubscriptionHeader({
    super.key,
    required this.planData,
    required this.screenType,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isPending = planData.status == 'pending';
    final planName =
        planData.plan?.name ?? planData.snapshot?.planName ?? 'Active Plan';

    return InkWell(
      onTap: () => context.pushNamed(
        AppRoutes.subscriptionPlanDetails,
        extra: planData.plan,
      ),
      child: Container(
        margin: UIUtils.cardsPadding(screenType),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isPending
                ? [Colors.orange.shade400, Colors.orange.shade700]
                : [
                    AppColors.primaryColor,
                    AppColors.primaryColor.withValues(alpha: 0.8),
                  ],
          ),
          // boxShadow: [
          //   BoxShadow(
          //     color: (isPending ? Colors.orange : AppColors.primaryColor)
          //         .withValues(alpha: 0.3),
          //     blurRadius: 15,
          //     offset: const Offset(0, 8),
          //   ),
          // ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Decorative background circles
              Positioned(
                right: -50,
                top: -50,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isPending
                                ? (l10n?.pending.toUpperCase() ?? 'PENDING')
                                : (l10n?.active.toUpperCase() ?? 'ACTIVE'),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        Icon(
                          isPending
                              ? Icons.pending_actions_rounded
                              : Icons.verified_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      planName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _infoTile(
                              context,
                              l10n?.price ?? 'Price',
                              '${HiveStorage.currencySymbol}${planData.pricePaid ?? planData.snapshot?.price ?? 0}',
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 30,
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: _infoTile(
                                context,
                                planData.endDate != null
                                    ? 'Expires On'
                                    : 'Started On',
                                planData.endDate ?? planData.startDate,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isPending) ...[
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          // onPressed: () =>
                          //     context.push(AppRoutes.subscriptionPlans),
                          onPressed: () => context.pushNamed(
                            AppRoutes.subscriptionPlanDetails,
                            extra: planData.plan,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.orange.shade700,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            l10n?.resumePayment ?? 'Resume Payment',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoTile(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.7),
            letterSpacing: 0.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class CurrentSubscriptionHeaderShimmer extends StatelessWidget {
  final ScreenType screenType;
  const CurrentSubscriptionHeaderShimmer({super.key, required this.screenType});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: UIUtils.cardsPadding(screenType),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade900
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomShimmer(
                  width: 80,
                  height: 24,
                  borderRadius: BorderRadius.circular(10),
                ),
                CustomShimmer(
                  width: 28,
                  height: 28,
                  borderRadius: BorderRadius.circular(14),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const CustomShimmer(width: 200, height: 24),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomShimmer(width: 40, height: 10),
                        SizedBox(height: 4),
                        CustomShimmer(width: 60, height: 16),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: Colors.grey.withValues(alpha: 0.2),
                  ),
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomShimmer(width: 70, height: 10),
                          SizedBox(height: 4),
                          CustomShimmer(width: 80, height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
