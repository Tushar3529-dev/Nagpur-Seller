// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/bloc/settings/settings_cubit.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/router/app_routes.dart';
import 'package:hyper_local_seller/screen/more_page/view/profile/bloc/profile_bloc.dart';
import 'package:hyper_local_seller/service/notification_service.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/bloc/current_subscription/current_subscription_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/service/subscription_limit_service.dart';
import 'package:hyper_local_seller/utils/image_path.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    // Minimal visible splash time (better UX than fixed 2s if init is fast)
    final splashMinDuration = Future.delayed(const Duration(milliseconds: 1400));

    // ── Parallel operations ───────────────────────────────────────
    final futures = <Future>[
      // 1. Load & fetch settings (cached + fresh from server)
      _initSettings(),

      // 2. Just ensure Hive is ready (already opened in main.dart)
      Future.value(),
    ];

    // Wait for minimum splash time + initialization
    await Future.wait([
      splashMinDuration,
      ...futures,
    ]);

    if (!mounted) return;

    // ── Navigation decision ───────────────────────────────────────
    final isFirstTime = HiveStorage.isFirstTime;

    if (isFirstTime) {
      context.go(AppRoutes.introSlider);
      await HiveStorage.setIsFirstTime(false);
    } else {
      final token = HiveStorage.userToken;
      if (token != null && token.trim().isNotEmpty) {
        // Fetch user profile and store in UserHelper before navigating
        await ProfileBloc.fetchAndStoreProfile();

        // Sync subscription limits
        await SubscriptionLimitService().syncSubscription();
        if (mounted) {
          context.read<CurrentSubscriptionBloc>().add(FetchCurrentSubscription());
        }

        // Check for pending notifications
        final notificationService = NotificationService();
        if (notificationService.hasPendingNotification) {
          debugPrint('Splash: Handling pending notification');
          notificationService.handlePendingNotification(context);
          
          // Fallback timer: if the app is still on splash screen after 3 seconds,
          // something likely went wrong with the notification navigation.
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted && GoRouterState.of(context).uri.toString() == AppRoutes.splashScreen) {
              debugPrint('Splash: Fallback navigation triggered');
              context.go(AppRoutes.home);
            }
          });
        } else {
          if ((HiveStorage.isFirstTimeSubscriptionVisit || kDebugMode) &&
              HiveStorage.isSubscriptionAvailable &&
              (HiveStorage.activePlanId == null || HiveStorage.activePlanId == 0) &&
              HiveStorage.pendingSubscriptionId == null) {
            debugPrint("Splash: Navigating to subscription choose plan");
            context.go(AppRoutes.subscriptionChoosePlan);
          } else {
            context.go(AppRoutes.home);
          }
        }
      } else {
        context.go(AppRoutes.login);
      }
    }
  }

  Future<void> _initSettings() async {
    final settingsCubit = context.read<SettingsCubit>();

    // First: immediately use cached values (if exist)
    await settingsCubit.loadCachedSettings();

    // If settings are not in cache (first time or cleared), we must wait for them
    // to ensure the app has critical config like currency/maintenance status.
    final needsFetch = HiveStorage.systemSettings == null;

    try {
      if (needsFetch) {
        debugPrint('First-run or empty cache: fetching settings synchronously...');
        await settingsCubit.fetchAndSaveSettings();
      } else {
        // Non-blocking refresh if we already have cache
        settingsCubit.fetchAndSaveSettings().catchError((e) {
          debugPrint('Settings background refresh failed: $e');
        });
      }
    } catch (e) {
      debugPrint('Settings fetch failed: $e');
      // On first run, a failure here might be problematic, but we continue 
      // to avoid blocking the user indefinitely if the server is down.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.tertiary,
      body: Stack(
        fit: StackFit.expand,
        children: [
          SvgPicture.asset(
            ImagesPath.doodle,
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              AppColors.primaryColor.withValues(alpha:0.75),
              BlendMode.srcATop,
            ),
          ),
          Center(
            child: Image.asset(
              ImagesPath.darkLogo,
              width: 300,
              height: 300,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}