import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local_seller/config/app_permissions.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/config/constant.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/bloc/check_eligibility/check_eligibility_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/model/plan_eligibility_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/repo/subscription_plans_repo.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/service/limit_counter_service.dart';
import 'package:hyper_local_seller/utils/permission_checker.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_buttons.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/bloc/settings/settings_cubit.dart';
import 'package:hyper_local_seller/router/app_routes.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/bloc/buy_subscription/buy_subscription_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/bloc/buy_subscription/buy_subscription_event.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/bloc/buy_subscription/buy_subscription_state.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/bloc/current_subscription/current_subscription_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/widgets/payment_selection_bottom_sheet.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';
import '../model/subscription_plans_model.dart';

class SubscriptionPlanDetailsPage extends StatefulWidget {
  final SubscriptionPlan plan;

  const SubscriptionPlanDetailsPage({super.key, required this.plan});

  @override
  State<SubscriptionPlanDetailsPage> createState() =>
      _SubscriptionPlanDetailsPageState();
}

class _SubscriptionPlanDetailsPageState
    extends State<SubscriptionPlanDetailsPage> {
  bool _isEligible = false;
  late final CheckEligibilityBloc _eligibilityBloc;
  final LimitCounterService limitCounterService = LimitCounterService();

  @override
  void initState() {
    super.initState();
    _eligibilityBloc = CheckEligibilityBloc(SubscriptionPlansRepo());
  }

  @override
  void dispose() {
    _eligibilityBloc.close();
    super.dispose();
  }

  void _checkEligibility() {
    if (!PermissionChecker.hasPermission(AppPermissions.subscriptionBuy)) {
      showCustomSnackbar(
        context: context,
        message:
            // l10n?.noPermissionBuySubscription ??
            'You do not have permission to buy subscription.',
        isWarning: true,
      );
      return;
    }
    context.read<SettingsCubit>().fetchAndSaveSettings();
    _eligibilityBloc.add(CheckSubscriptionAvailability(planId: widget.plan.id));
  }

  void _showEligibilityDialog(EligibilityData data) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final details = data.details;
    final failing = data.failingKeys ?? [];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                data.eligible
                    ? (l10n?.eligibleTitle ?? 'You are eligible!')
                    : (l10n?.notEligibleTitle ?? 'Not eligible for this plan'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: data.eligible
                      ? AppColors.successColor
                      : AppColors.errorColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                data.eligible
                    ? (l10n?.eligibleSubtitle ??
                          'Your account meets all requirements for this plan upgrade.')
                    : (l10n?.notEligibleSubtitle ??
                          'Some requirements are not met for this plan.'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                if (details?.storeLimit != null)
                  _buildLimitRow(
                    l10n?.stores ?? 'Stores',
                    details!.storeLimit!,
                    failing.contains('store_limit'),
                  ),
                if (details?.productLimit != null)
                  _buildLimitRow(
                    l10n?.products ?? 'Products',
                    details!.productLimit!,
                    failing.contains('product_limit'),
                  ),
                if (details?.roleLimit != null)
                  _buildLimitRow(
                    l10n?.roles ?? 'Roles',
                    details!.roleLimit!,
                    failing.contains('role_limit'),
                  ),
                if (details?.systemUserLimit != null)
                  _buildLimitRow(
                    l10n?.systemUsers ?? 'System Users',
                    details!.systemUserLimit!,
                    failing.contains('system_user_limit'),
                  ),
                if (!data.eligible &&
                    (data.failingKeys?.isNotEmpty ?? false)) ...[
                  const SizedBox(height: 16),
                  Text(
                    l10n?.someLimitsExceeded ??
                        'Some limits have been exceeded.',
                    style: TextStyle(
                      color: AppColors.errorColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 8),
              child: data.eligible
                  ? PrimaryButton(
                      text: l10n?.buyPlan ?? 'Buy Plan',
                      borderRadius: 12,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 12,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _startPurchaseFlow();
                      },
                    )
                  : SecondaryButton(
                      text: l10n?.ok ?? 'OK',
                      borderRadius: 12,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 12,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
            ),
          ],
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() {
          _isEligible = data.eligible;
        });
      }
    });
  }

  String? _getPreviousPaymentGateway(BuildContext context) {
    final state = context.read<CurrentSubscriptionBloc>().state;
    if (state is CurrentSubscriptionPending) {
      final transactions = state.data.transactions;
      if (transactions != null && transactions.isNotEmpty) {
        return transactions.first.paymentGateway;
      }
    } else if (state is CurrentSubscriptionLoaded) {
      if (state.data.status == 'pending') {
        final transactions = state.data.transactions;
        if (transactions != null && transactions.isNotEmpty) {
          return transactions.first.paymentGateway;
        }
      }
    }
    return null;
  }

  void _startPurchaseFlow({String? defaultPaymentMethod}) {
    if (!PermissionChecker.hasPermission(AppPermissions.subscriptionBuy)) {
      showCustomSnackbar(
        context: context,
        message:
            // l10n?.noPermissionBuySubscription ??
            'You do not have permission to buy subscription.',
        isWarning: true,
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            if (state is SettingsLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is SettingsLoaded && state.paymentSettings != null) {
              return PaymentSelectionBottomSheet(
                paymentSettings: state.paymentSettings!,
                defaultPaymentMethod: defaultPaymentMethod,
                onPaymentMethodSelected: (method) {
                  context.read<BuySubscriptionBloc>().add(
                    PurchasePlan(planId: widget.plan.id, paymentType: method),
                  );
                },
              );
            }
            if (state is SettingsError) {
              return Center(child: Text(state.message));
            }
            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  Widget _buildLimitRow(String label, LimitCheck limit, bool isFailing) {
    final statusColor = limit.ok && !isFailing
        ? AppColors.successColor
        : AppColors.errorColor;

    final double progress = limit.limit > 0 ? (limit.used / limit.limit) : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                limit.ok && !isFailing
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                color: statusColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${limit.used} / ${limit.limit}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: statusColor.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final st = context.screenType;
    final l10n = AppLocalizations.of(context);
    final isActive = HiveStorage.activePlanId == widget.plan.id;
    final isPending = HiveStorage.pendingPlanId == widget.plan.id;
    final hasActiveSubscription = HiveStorage.subscriptionStatus == 'active';

    return BlocListener<CheckEligibilityBloc, CheckEligibilityState>(
      bloc: _eligibilityBloc,
      listener: (context, state) {
        if (state is CheckEligibilitySuccess) {
          _showEligibilityDialog(state.data);
        } else if (state is CheckEligibilityFailure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: BlocListener<BuySubscriptionBloc, BuySubscriptionState>(
        listener: (context, state) {
          if (state is BuySubscriptionSuccess) {
            showCustomSnackbar(context: context, message: state.message);
            // Sync limits and status from current subscription API
            context.read<CurrentSubscriptionBloc>().add(
              FetchCurrentSubscription(),
            );
            // Optionally navigate back to plans list or handle success UI
            // close details page
            if (Navigator.canPop(context)) {
              Navigator.pop(context, true);
            }
          } else if (state is BuySubscriptionPending) {
            context
                .push(
                  AppRoutes.subscriptionPaymentWebView,
                  extra: state.paymentUrl,
                )
                .then((_) {
                  if (context.mounted) {
                    context.read<BuySubscriptionBloc>().add(
                      const StopPaymentPolling(),
                    );
                  }
                });
          } else if (state is BuySubscriptionFailure) {
            showCustomSnackbar(
              context: context,
              message: state.message,
              isError: true,
            );
          }
        },
        child: CustomScaffold(
          title: l10n?.planDetailsTitle ?? 'Plan Details',
          showAppbar: true,
          centerTitle: true,
          body: SingleChildScrollView(
            padding: UIUtils.pagePadding(st),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Center(
                  child: Column(
                    children: [
                      Text(
                        widget.plan.name,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      if (isActive || isPending) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.successColor
                                : Colors.orange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isActive
                                ? l10n?.active.toUpperCase() ?? 'ACTIVE'
                                : l10n?.pending.toUpperCase() ?? 'PENDING',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      if (widget.plan.description != null &&
                          widget.plan.description!.isNotEmpty) ...[
                        Text(
                          widget.plan.description ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            widget.plan.isFree
                                ? '${HiveStorage.currencySymbol}0'
                                : '${HiveStorage.currencySymbol}${widget.plan.price}',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            limitCounterService.formatDuration(
                              l10n,
                              widget.plan.durationType,
                              widget.plan.durationDays,
                            ),
                            // _formatDuration(l10n),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  l10n?.whatsIncluded ?? 'What\'s Included',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),

                _buildFeatureList(context, st, l10n),

                const SizedBox(height: 20),

                BlocBuilder<CheckEligibilityBloc, CheckEligibilityState>(
                  bloc: _eligibilityBloc,
                  builder: (context, state) {
                    final isLoading =
                        state is CheckEligibilityLoading ||
                        context.watch<BuySubscriptionBloc>().state
                            is BuySubscriptionLoading;

                    if (isActive || isPending) {
                      return SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          onPressed: isPending
                              ? () {
                                  final previousGateway =
                                      _getPreviousPaymentGateway(context);
                                  _startPurchaseFlow(
                                    defaultPaymentMethod: previousGateway,
                                  );
                                }
                              : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: isPending
                                ? AppColors.primaryColor
                                : null,
                            disabledBackgroundColor: isActive
                                ? AppColors.successColor.withValues(alpha: 0.8)
                                : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            isActive
                                ? l10n?.currentPlan ?? 'CURRENT PLAN'
                                : l10n?.resumePayment ?? 'RESUME PAYMENT',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    }

                    if (hasActiveSubscription) {
                      return SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          onPressed: null,
                          style: FilledButton.styleFrom(
                            disabledBackgroundColor: AppColors.successColor
                                .withValues(alpha: 0.8),
                            disabledForegroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            l10n?.anotherPlanActive ?? 'ANOTHER PLAN ACTIVE',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    }

                    if (_isEligible) {
                      return SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  _startPurchaseFlow();
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  l10n?.buttonActivateThisPlan ??
                                      'Activate This Plan',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      );
                    }

                    return SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed: isLoading ? null : () => _checkEligibility(),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                l10n?.checkAvailability ?? 'Check Availability',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isFeatureIncluded(int? limit) {
    if (limit == null) return false; // key missing in limits map → not included
    if (limit == 0) return false; // explicitly 0 → not included
    return true; // -1 (unlimited) or > 0 → included
  }

  Widget _buildFeatureList(
    BuildContext context,
    ScreenType st,
    AppLocalizations? l10n,
  ) {
    if (widget.plan.limits == null) return const SizedBox.shrink();

    final limits = widget.plan.limits!;
    return Column(
      children: [
        _DetailFeatureRow(
          icon: Icons.store_rounded,
          title: l10n?.featureStoreManagement ?? 'Store Management',
          subtitle: limitCounterService.getStoresFeatureText(
            limits.storeLimit,
            l10n,
          ),
          isIncluded: _isFeatureIncluded(limits.storeLimit),
        ),
        _DetailFeatureRow(
          icon: Icons.inventory_2_rounded,
          title: l10n?.featureProductCatalog ?? 'Product Catalog',
          subtitle: limitCounterService.getProductFeatureText(
            limits.productLimit,
            l10n,
          ),
          isIncluded: _isFeatureIncluded(limits.productLimit),
        ),
        _DetailFeatureRow(
          icon: Icons.badge_rounded,
          title: l10n?.featureRolesPermissions ?? 'Roles & Permissions',
          subtitle: limitCounterService.getRolesFeatureText(
            limits.roleLimit,
            l10n,
          ),
          isIncluded: _isFeatureIncluded(limits.roleLimit),
        ),
        _DetailFeatureRow(
          icon: Icons.people_alt_rounded,
          title: l10n?.featureSystemUsers ?? 'System Users',
          subtitle: limitCounterService.getSystemUserFeatureText(
            limits.systemUserLimit,
            l10n,
          ),
          isIncluded: _isFeatureIncluded(limits.systemUserLimit),
        ),
      ],
    );
  }
}

class _DetailFeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isIncluded;

  const _DetailFeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isIncluded,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2430) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white10
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primaryColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isIncluded ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: isIncluded
                  ? AppColors.successColor.withValues(alpha: 0.8)
                  : AppColors.errorColor.withValues(alpha: 0.7),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
