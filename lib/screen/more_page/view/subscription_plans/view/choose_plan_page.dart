import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/router/app_routes.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/bloc/subscription_plans_bloc/subscription_plan_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/bloc/current_subscription/current_subscription_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/model/subscription_plans_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/repo/subscription_plans_repo.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/service/limit_counter_service.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_buttons.dart';
import 'package:hyper_local_seller/widgets/custom/custom_loading_indicator.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';

class ChoosePlanPage extends StatefulWidget {
  const ChoosePlanPage({super.key});

  @override
  State<ChoosePlanPage> createState() => _ChoosePlanPageState();
}

class _ChoosePlanPageState extends State<ChoosePlanPage> {
  late PageController _pageController;
  int _currentIndex = 0;
  final int _initialPage = 1000;
  final LimitCounterService limitCounterService = LimitCounterService();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.75,
      initialPage: _initialPage,
    );
    _pageController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        final screenType = context.screenType;

        return CustomScaffold(
          showAppbar: false,
          body: Stack(
            children: [
              // Background Gradient & Pattern
              _buildBackground(context),

              // Main Content
              SafeArea(
                child: Column(
                  children: [
                    // Top Bar
                    _buildTopBar(context, l10n),

                    const SizedBox(height: 20),

                    // Header
                    _buildHeader(l10n, screenType),

                    const Expanded(child: SizedBox()),

                    // Card Swiper
                    _buildSwiper(context, screenType, l10n),

                    const Expanded(child: SizedBox()),

                    // Bottom Section
                    _buildBottomSection(context, l10n, screenType),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBackground(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryColor,
            AppColors.primaryColor.withValues(alpha: 0.8),
            AppColors.primaryColor.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Subtle Pattern (using transparent doodle if available, or just colors)
          Opacity(
            opacity: 0.1,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                    'assets/images/png/doodle.png',
                  ), // Adjust path if needed
                  fit: BoxFit.cover,
                  repeat: ImageRepeat.repeat,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, AppLocalizations? l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              if (context.mounted) {
                context.go(AppRoutes.home);
              }
            },
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          TextButton(
            onPressed: () => _onSkip(context),
            child: Text(
              l10n?.remindMeLater ?? 'Remind me later',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations? l10n, ScreenType screenType) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Text(
            // l10n?.chooseYourPlan ??
            'Choose Your Plan',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            // l10n?.choosePlanSubtitle ??
            'Select a plan to start managing your stores and products.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwiper(
    BuildContext context,
    ScreenType screenType,
    AppLocalizations? l10n,
  ) {
    return BlocBuilder<SubscriptionPlanBloc, SubscriptionPlanState>(
      builder: (context, state) {
        if (state.isInitialLoading) {
          return const Center(
            child: CustomLoadingIndicator(color: Colors.white),
          );
        }

        final plans = state.items;
        if (plans.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 480,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index % plans.length;
              });
            },
            itemBuilder: (context, index) {
              final plan = plans[index % plans.length];
              return _buildPlanCard(plan, index, screenType, l10n);
            },
          ),
        );
      },
    );
  }

  Widget _buildPlanCard(
    SubscriptionPlan plan,
    int index,
    ScreenType screenType,
    AppLocalizations? l10n,
  ) {
    final isActive = plan.id == HiveStorage.activePlanId;
    double value = 1.0;
    if (_pageController.position.hasContentDimensions) {
      value = _pageController.page! - index;
    } else {
      value = (_initialPage - index).toDouble();
    }

    double scale = (1 - (value.abs() * 0.08)).clamp(0.85, 1.0);
    double opacity = (1 - (value.abs() * 0.4)).clamp(0.6, 1.0);

    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: opacity,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            color: Colors.white.withValues(alpha: 0.95),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Stack(
              children: [
                // Top accent gradient
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 100,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primaryColor.withValues(alpha: 0.05),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              plan.name,
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.fade,
                            ),
                          ),
                          if (isActive) const SizedBox(width: 8),
                          if (isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primaryColor.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              child: const Text(
                                'ACTIVE',
                                style: TextStyle(
                                  color: AppColors.primaryColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            plan.isFree
                                ? 'Free'
                                : '${HiveStorage.currencySymbol}${plan.price}',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            limitCounterService.formatDuration(
                              l10n,
                              plan.durationType,
                              plan.durationDays,
                            ),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 24),

                      // Features
                      _buildFeatureItem(
                        limitCounterService.getStoresFeatureText(
                          plan.limits?.storeLimit,
                          l10n,
                        ),
                      ),
                      _buildFeatureItem(
                        limitCounterService.getProductFeatureText(
                          plan.limits?.productLimit,
                          l10n,
                        ),
                      ),
                      _buildFeatureItem(
                        limitCounterService.getRolesFeatureText(
                          plan.limits?.roleLimit,
                          l10n,
                        ),
                      ),
                      _buildFeatureItem(
                        limitCounterService.getSystemUserFeatureText(
                          plan.limits?.systemUserLimit,
                          l10n,
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
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryColor,
            ),
            child: const Icon(Icons.check, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(
    BuildContext context,
    AppLocalizations? l10n,
    ScreenType screenType,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        children: [
          PrimaryButton(
            text:
                // l10n?.continueBtn ??
                'Continue',
            onPressed: () => _onContinue(context),
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
            borderRadius: 20,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _footerLink(
                // l10n?.termsOfService ??
                'Terms of Service',
              ),
              Text(
                ' and ',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
              _footerLink(l10n?.privacyPolicy ?? 'Privacy Policy'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _footerLink(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        decoration: TextDecoration.underline,
        decorationColor: Colors.white,
      ),
    );
  }

  void _onContinue(BuildContext context) {
    // Get the current plan and navigate to details
    final plansState = context.read<SubscriptionPlanBloc>().state;
    final plans = plansState.items;
    if (plans.isNotEmpty) {
      final selectedPlan = plans[_currentIndex];
      context.pushNamed(AppRoutes.subscriptionPlanDetails, extra: selectedPlan);
    }
  }

  void _onSkip(BuildContext context) async {
    await HiveStorage.setChoosePlanRemindTime(DateTime.now().toIso8601String());
    await HiveStorage.setIsFirstTimeSubscriptionVisit(false);
    if (context.mounted) {
      context.go(AppRoutes.home);
    }
  }
}
