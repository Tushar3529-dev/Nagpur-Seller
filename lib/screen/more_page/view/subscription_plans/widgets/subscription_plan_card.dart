import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local_seller/config/app_permissions.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/router/app_routes.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/model/subscription_plans_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/service/limit_counter_service.dart';
import 'package:hyper_local_seller/utils/permission_checker.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';

class PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final ScreenType st;
  final AppLocalizations? l10n;

  const PlanCard({
    super.key,
    required this.plan,
    required this.st,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRecommended = plan.isRecommended;
    final isActive = HiveStorage.activePlanId == plan.id;
    final isPending = HiveStorage.pendingPlanId == plan.id;
    final hasActiveSubscription = HiveStorage.subscriptionStatus == 'active';
    final isDark = theme.brightness == Brightness.dark;
    final LimitCounterService limitCounterService = LimitCounterService();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 12),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF151921)
                : (isRecommended || isPending
                      ? Colors.white
                      : Colors.grey.shade50),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isPending
                  ? Colors.orange
                  : isRecommended
                  ? AppColors.primaryColor
                  : AppColors.darkOutlineVariant.withValues(alpha: 0.5),
              width: isRecommended || isPending ? 2.0 : 1.5,
            ),
            boxShadow: (isRecommended || isPending)
                ? [
                    BoxShadow(
                      color:
                          (isPending ? Colors.orange : AppColors.primaryColor)
                              .withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: InkWell(
            onTap: () =>
                context.push(AppRoutes.subscriptionPlanDetails, extra: plan),
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    plan.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        plan.isFree
                            ? '${HiveStorage.currencySymbol}0'
                            : '${HiveStorage.currencySymbol}${plan.price}',
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        limitCounterService.formatDuration(
                          l10n,
                          plan.durationType,
                          plan.durationDays,
                        ),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  if (plan.limits != null) ...[
                    _FeatureRow(
                      label: limitCounterService.getStoresFeatureText(
                        plan.limits?.storeLimit,
                        l10n,
                      ),
                      st: st,
                    ),
                    _FeatureRow(
                      label: limitCounterService.getProductFeatureText(
                        plan.limits?.productLimit,
                        l10n,
                      ),
                      st: st,
                    ),
                    _FeatureRow(
                      label: limitCounterService.getRolesFeatureText(
                        plan.limits!.roleLimit,
                        l10n,
                      ),
                      st: st,
                    ),
                    _FeatureRow(
                      label: limitCounterService.getSystemUserFeatureText(
                        plan.limits!.systemUserLimit,
                        l10n,
                      ),
                      st: st,
                    ),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        if (isActive) {
                          context.push(
                            AppRoutes.subscriptionPlanDetails,
                            extra: plan,
                          );
                        } else if (isPending || !hasActiveSubscription) {
                          // Check for BUY permission
                          if (!PermissionChecker.hasPermission(
                            AppPermissions.subscriptionBuy,
                          )) {
                            showCustomSnackbar(
                              context: context,
                              message:
                                  // l10n?.noPermissionBuySubscription ??
                                  'You do not have permission to buy subscription.',
                              isWarning: true,
                            );
                            return;
                          }
                          context.push(
                            AppRoutes.subscriptionPlanDetails,
                            extra: plan,
                          );
                        } else {
                          // View Details case (has active sub but looking at another)
                          context.push(
                            AppRoutes.subscriptionPlanDetails,
                            extra: plan,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isActive
                            ? Colors.transparent
                            : (isRecommended || isPending)
                            ? AppColors.primaryColor
                            : (isDark
                                  ? const Color(0xFF1E2430)
                                  : Colors.grey.shade200),
                        foregroundColor: isActive
                            ? AppColors.successColor
                            : (isRecommended || isPending)
                            ? Colors.white
                            : theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: isActive
                                ? AppColors.successColor
                                : Colors.transparent,
                            width: isActive ? 1.2 : 0.0,
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        isActive
                            ? l10n?.viewPlan ?? 'View Plan'
                            : isPending
                            ? l10n?.resumePayment ?? 'Resume Payment'
                            : hasActiveSubscription
                            ? l10n?.viewDetails ?? 'View Details'
                            : (l10n?.buttonChoosePlan ?? 'Choose Plan'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isRecommended || isPending)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isPending ? Colors.orange : AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isPending
                      ? l10n?.pending.toUpperCase() ?? 'PENDING'
                      : (l10n?.badgeRecommended ?? 'RECOMMENDED'),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String label;
  final ScreenType st;

  const _FeatureRow({required this.label, required this.st});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: AppColors.primaryColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 12, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
