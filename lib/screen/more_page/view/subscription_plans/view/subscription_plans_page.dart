import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/config/constant.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/router/app_routes.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/widgets/subscription_plan_card.dart';
import 'package:hyper_local_seller/utils/image_path.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_loading_indicator.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/widgets/custom/custom_shimmer.dart';
import 'package:hyper_local_seller/bloc/screen_size/screen_size_bloc.dart';
import 'package:hyper_local_seller/widgets/custom/custom_svg.dart';
import 'package:hyper_local_seller/widgets/ui/empty_state_widget.dart';
import '../bloc/subscription_plans_bloc/subscription_plan_bloc.dart';
import '../bloc/current_subscription/current_subscription_bloc.dart';
import '../bloc/buy_subscription/buy_subscription_bloc.dart';
import '../model/subscription_plans_model.dart';

class SubscriptionPlansPage extends StatefulWidget {
  const SubscriptionPlansPage({super.key});

  @override
  State<SubscriptionPlansPage> createState() => _SubscriptionPlansPageState();
}

class _SubscriptionPlansPageState extends State<SubscriptionPlansPage> {
  @override
  void initState() {
    super.initState();
    context.read<SubscriptionPlanBloc>().add(LoadSubscriptionPlansInitial());
  }

  @override
  Widget build(BuildContext context) {
    context.watch<CurrentSubscriptionBloc>();
    context.watch<BuySubscriptionBloc>();

    final l10n = AppLocalizations.of(context);
    return BlocBuilder<ScreenSizeBloc, ScreenSizeState>(
      builder: (context, screenSizeState) {
        final screenType = screenSizeState.screenType;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return CustomScaffold(
          showAppbar: true,
          centerTitle: true,
          title: l10n?.subscriptionPlansTitle ?? 'Subscription Plans',
          body: Container(
            color: isDark
                ? Theme.of(context).colorScheme.surface
                : const Color(0xFFE3F2FD).withValues(alpha: 0.5),
            child: BlocBuilder<SubscriptionPlanBloc, SubscriptionPlanState>(
              builder: (context, state) {
                if (state.error != null && state.items.isEmpty) {
                  return EmptyStateWidget(
                    svgPath: ImagesPath.noOrderFoundSvg,
                    title:
                        l10n?.somethingWentWrong ??
                        'Seems like there is some issue',
                    subtitle: l10n?.tryAgainLater ?? 'Please try again later',
                    actionText: l10n?.tryAgain ?? 'Try Again',
                    onAction: () {
                      context.read<SubscriptionPlanBloc>().add(
                        RefreshSubscriptionPlans(),
                      );
                    },
                  );
                }

                if (state.items.isEmpty &&
                    !state.isInitialLoading &&
                    !state.isRefreshing) {
                  return EmptyStateWidget(
                    svgPath: ImagesPath.noProductFoundSvg,
                    title:
                        l10n?.noSubscriptionPlansFound ??
                        'No Subscription Plans Found!',
                    actionText: l10n?.refresh ?? 'Refresh',
                    onAction: () {
                      context.read<SubscriptionPlanBloc>().add(
                        RefreshSubscriptionPlans(),
                      );
                    },
                  );
                }

                final plans = state.items;

                return SafeArea(
                  top: true,
                  bottom: Platform.isIOS ? false : true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Plan cards list
                      Expanded(
                        child: RefreshIndicator(
                          color: AppColors.primaryColor,
                          onRefresh: () async {
                            context.read<SubscriptionPlanBloc>().add(
                              RefreshSubscriptionPlans(),
                            );
                            context.read<CurrentSubscriptionBloc>().add(
                              FetchCurrentSubscription(),
                            );
                          },
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.symmetric(
                              horizontal: UIUtils.gapMD(screenType),
                              vertical: UIUtils.gapLG(screenType),
                            ),
                            separatorBuilder: (_, __) =>
                                SizedBox(height: UIUtils.gapLG(screenType)),
                            itemCount:
                                (state.isInitialLoading ||
                                        state.isRefreshing) &&
                                    state.items.isEmpty
                                ? 4
                                : plans.length,
                            itemBuilder: (context, index) {
                              if (state.isInitialLoading ||
                                  state.isRefreshing) {
                                return const PlanCardShimmer();
                              }
                              return BlocBuilder<
                                CurrentSubscriptionBloc,
                                CurrentSubscriptionState
                              >(
                                builder: (context, currentSubState) {
                                  return PlanCard(
                                    plan: plans[index],
                                    st: screenType,
                                    l10n: l10n,
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
