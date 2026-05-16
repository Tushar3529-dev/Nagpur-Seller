import 'dart:io';
import 'dart:io' as io;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hyper_local_seller/bloc/screen_size/screen_size_bloc.dart';
import 'package:hyper_local_seller/bloc/settings/settings_cubit.dart';
import 'package:hyper_local_seller/bloc/theme/theme_cubit.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/config/theme.dart';
import 'package:hyper_local_seller/router/app_routes.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hyper_local_seller/bloc/language/language_cubit.dart';
import 'package:hyper_local_seller/screen/auth/bloc/auth/auth_bloc.dart';
import 'package:hyper_local_seller/screen/auth/repo/auth_repo.dart';
import 'package:hyper_local_seller/screen/more_page/view/categories/bloc/categories_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/bloc/my_subscriptions/subscription_history_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/repo/subscription_history_repo.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/bloc/buy_subscription/buy_subscription_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/bloc/check_eligibility/check_eligibility_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/bloc/current_subscription/current_subscription_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/bloc/subscription_plans_bloc/subscription_plan_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/repo/subscription_plans_repo.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/widgets/subscription_reminder_wrapper.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/bloc/system_user_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/repo/system_users_repo.dart';
import 'package:hyper_local_seller/service/phone_auth.dart';
import 'package:hyper_local_seller/screen/more_page/view/attributes/repo/attributes_repo.dart';
import 'package:hyper_local_seller/screen/more_page/view/brands/bloc/brands_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/brands/repo/brands_repo.dart';
import 'package:hyper_local_seller/screen/more_page/view/categories/repo/categories_repo.dart';
import 'package:hyper_local_seller/screen/more_page/view/attributes/bloc/attributes_bloc/attributes_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/attributes/bloc/attribute_values_bloc/attribute_values_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/earning/bloc/settled_earnings_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/earning/bloc/unsettled_earnings_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/earning/repo/earning_repo.dart';
import 'package:hyper_local_seller/screen/more_page/view/roles_and_permissions/bloc/roles_bloc/roles_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/roles_and_permissions/repo/roles_repo.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/bloc/stores_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/repo/store_repo.dart';
import 'package:hyper_local_seller/screen/more_page/view/wallet/bloc/transactions_bloc/transactions_history_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/wallet/bloc/wallet_bloc/wallet_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/wallet/bloc/withdraw_history_bloc/withdraw_history_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/wallet/repo/wallet_repo.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/bloc/add_product_bloc/add_product_bloc.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/repo/add_product_repo.dart';
import 'package:hyper_local_seller/screen/products_page/products/bloc/products_bloc/products_bloc.dart';
import 'package:hyper_local_seller/screen/products_page/products/repo/products_repo.dart';
import 'package:hyper_local_seller/screen/products_page/products/repo/product_faq_repo.dart';
import 'package:hyper_local_seller/screen/products_page/products/bloc/product_faq_bloc/product_faq_bloc.dart';
import 'package:hyper_local_seller/screen/auth/bloc/forget-password/forgot_password_bloc.dart';
import 'package:hyper_local_seller/screen/auth/bloc/verify-user/verify_user_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/tax_group/bloc/tax_group_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/tax_group/repo/tax_group_repo.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/bloc/selected_categories/selected_categories_cubit.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/bloc/selected_categories/category_expansion_cubit.dart';
import 'l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hyper_local_seller/service/notification_service.dart';
import 'package:hyper_local_seller/bloc/store_switcher/store_switcher_cubit.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/add_store/bloc/add_store_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/add_store/repo/add_store_repo.dart';
import 'package:hyper_local_seller/screen/home_page/bloc/home_page/home_page_bloc.dart';
import 'package:hyper_local_seller/screen/home_page/repo/home_data_repo.dart';
import 'package:hyper_local_seller/screen/order_page/bloc/orders/orders_bloc.dart';
import 'package:hyper_local_seller/screen/order_page/bloc/order_filters_bloc/order_filters_bloc.dart';
import 'package:hyper_local_seller/screen/order_page/bloc/order_details_bloc/order_details_bloc.dart';
import 'package:hyper_local_seller/screen/order_page/repo/order_repo.dart';
import 'package:hyper_local_seller/screen/more_page/view/profile/bloc/profile_bloc.dart';
import 'package:hyper_local_seller/bloc/connectivity/connectivity_cubit.dart';
import 'package:hyper_local_seller/screen/more_page/view/delivery_zone/bloc/delivery_zone_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/delivery_zone/repo/delivery_zone_repo.dart';
import 'package:hyper_local_seller/screen/home_page/bloc/notification/notification_list_bloc.dart';
import 'package:hyper_local_seller/screen/home_page/repo/notification_list_repo.dart';
import 'package:hyper_local_seller/widgets/ui/maintenance_screen.dart';
import 'package:hyper_local_seller/widgets/ui/no_internet_screen.dart';

// ─── Background message handler (top-level, runs in a separate isolate) ───────
// This function CANNOT access any Flutter widgets or Blocs. It stores a flag in
// Hive so that when the app resumes the AppLifecycleObserverWidget can trigger
// the Bloc refresh on the main isolate.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Minimal init — only what's safe in a background isolate.
  await Hive.initFlutter();

  final type = message.data['type']?.toString().toLowerCase();
  final orderId = message.data['order_id']?.toString();

  final isOrderNotification =
      type == 'order' ||
      type == 'orders' ||
      type == 'order_update' ||
      type == 'new_order' ||
      type == 'return_order' ||
      type == 'return_order_update' ||
      (orderId != null && orderId.isNotEmpty && type == null);

  try {
    final box = await Hive.openBox('notificationRefreshBox');
    if (isOrderNotification) {
      await box.put('pendingOrderRefresh', true);
      debugPrint(
        '[BG Handler] Order notification received — pendingOrderRefresh set to true',
      );
    }
    // Always mark that notification count needs refresh
    await box.put('pendingNotificationCountRefresh', true);
    debugPrint('[BG Handler] Background notification processed: type=$type');
  } catch (e) {
    debugPrint('[BG Handler] Error storing refresh flag: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Must be registered BEFORE Firebase.initializeApp()
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await Firebase.initializeApp();

  await Hive.initFlutter();
  await HiveStorage.initPrefs();
  await NotificationService().init();

  if (kDebugMode) {
    io.HttpClient.enableTimelineLogging = true;
  }

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => AuthRepository()),
        RepositoryProvider(create: (_) => CategoriesRepo()),
        RepositoryProvider(create: (_) => BrandsRepo()),
        RepositoryProvider(create: (_) => AttributesRepo()),
        RepositoryProvider(create: (_) => ProductsRepo()),
        RepositoryProvider(create: (_) => TaxGroupsRepo()),
        RepositoryProvider(create: (_) => StoresRepo()),
        RepositoryProvider(create: (_) => AddProductRepo()),
        RepositoryProvider(create: (_) => AddStoreRepository()),
        RepositoryProvider(create: (_) => HomeDataRepo()),
        RepositoryProvider(create: (_) => OrdersRepo()),
        RepositoryProvider(create: (_) => ProductFaqRepo()),
        RepositoryProvider(create: (_) => DeliveryZoneRepo()),
        RepositoryProvider(create: (_) => NotificationListRepo()),
        RepositoryProvider(create: (_) => SubscriptionPlansRepo()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => SettingsCubit()),
          BlocProvider(create: (_) => ConnectivityCubit()),
          BlocProvider(create: (_) => ScreenSizeBloc()),
          BlocProvider(create: (_) => LanguageCubit()),
          BlocProvider(create: (_) => ThemeCubit()),
          BlocProvider(
            create: (context) => AuthBloc(
              context.read<AuthRepository>(),
              FirebasePhoneAuthService(),
            ),
          ),
          BlocProvider(
            create: (context) =>
                ForgotPasswordBloc(context.read<AuthRepository>()),
          ),
          BlocProvider(
            create: (context) =>
                VerifyUserBloc(authRepository: context.read<AuthRepository>()),
          ),
          BlocProvider(
            create: (context) => BrandsBloc(context.read<BrandsRepo>()),
          ),
          BlocProvider(
            create: (context) => CategoriesBloc(context.read<CategoriesRepo>()),
          ),
          BlocProvider(
            create: (context) => AttributesBloc(context.read<AttributesRepo>()),
          ),
          BlocProvider(
            create: (context) =>
                AttributeValuesBloc(context.read<AttributesRepo>()),
          ),
          BlocProvider(
            create: (context) => ProductsBloc(context.read<ProductsRepo>()),
          ),
          BlocProvider(
            create: (context) => TaxGroupsBloc(context.read<TaxGroupsRepo>()),
          ),
          BlocProvider(
            create: (context) => StoresBloc(context.read<StoresRepo>()),
          ),
          BlocProvider(
            create: (context) => StoreSwitcherCubit(context.read<StoresRepo>()),
          ),
          BlocProvider(create: (_) => SelectedCategoriesCubit()),
          BlocProvider(create: (_) => CategoryExpansionCubit()),
          BlocProvider(
            create: (context) => AddProductBloc(
              context.read<AddProductRepo>(),
              context.read<ProductsRepo>(),
              context.read<CategoriesRepo>(),
            ),
          ),
          BlocProvider(
            create: (context) =>
                AddStoreBloc(context.read<AddStoreRepository>()),
          ),
          BlocProvider(
            create: (context) =>
                HomePageBloc(repo: context.read<HomeDataRepo>())
                  ..add(FetchHomePageData()),
          ),
          BlocProvider(
            create: (context) =>
                OrdersBloc(context.read<OrdersRepo>())
                  ..add(LoadOrdersInitial()),
          ),
          BlocProvider(
            create: (context) =>
                OrderFiltersBloc(context.read<OrdersRepo>())
                  ..add(FetchOrderFilters()),
          ),
          BlocProvider(
            create: (context) => OrderDetailsBloc(context.read<OrdersRepo>()),
          ),
          BlocProvider(create: (context) => ProfileBloc()),
          BlocProvider(create: (context) => WalletBloc()),
          BlocProvider(
            create: (context) => WithdrawHistoryBloc(WalletRepository()),
          ),
          BlocProvider(
            create: (context) => TransactionsHistoryBloc(WalletRepository()),
          ),
          BlocProvider(
            create: (context) => SettledEarningsBloc(EarningRepository()),
          ),
          BlocProvider(
            create: (context) => UnsettledEarningsBloc(EarningRepository()),
          ),
          BlocProvider(
            create: (context) => ProductFaqBloc(context.read<ProductFaqRepo>()),
          ),
          BlocProvider(create: (context) => RolesBloc(RolesRepo())),
          BlocProvider(
            create: (context) =>
                DeliveryZoneBloc(context.read<DeliveryZoneRepo>()),
          ),
          BlocProvider(
            create: (context) => SystemUserBloc(repo: SystemUsersRepo()),
          ),
          BlocProvider(
            create: (context) =>
                NotificationListBloc(context.read<NotificationListRepo>())
                  ..add(FetchUnreadCount()),
          ),
          BlocProvider(
            create: (context) =>
                SubscriptionPlanBloc(context.read<SubscriptionPlansRepo>())
                  ..add(LoadSubscriptionPlansInitial()),
          ),
          BlocProvider(
            create: (context) =>
                CheckEligibilityBloc(context.read<SubscriptionPlansRepo>()),
          ),
          BlocProvider(
            create: (context) =>
                CurrentSubscriptionBloc(context.read<SubscriptionPlansRepo>()),
          ),
          BlocProvider(
            create: (context) =>
                BuySubscriptionBloc(context.read<SubscriptionPlansRepo>()),
          ),
          BlocProvider(
            create: (_) => SubscriptionHistoryBloc(SubscriptionHistoryRepo()),
          ),
        ],
        child: const AppLifecycleObserverWidget(child: AppWrapper()),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: SafeArea(
        top: false,
        bottom: Platform.isIOS ? false : true,
        child: BlocBuilder<LanguageCubit, Locale>(
          builder: (context, locale) {
            return BlocBuilder<ThemeCubit, ThemeMode>(
              builder: (context, themeMode) {
                return MaterialApp.router(
                  debugShowCheckedModeBanner: false,
                  locale: locale,
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                    FlutterQuillLocalizations.delegate,
                  ],
                  supportedLocales: AppLocalizations.supportedLocales,
                  theme: AppTheme.lightTheme,
                  darkTheme: AppTheme.darkTheme,
                  themeMode: themeMode,
                  routerConfig: MyAppRoutes.router,
                  builder: (context, child) {
                    // Initialize/Update screen size in Bloc
                    final size = MediaQuery.of(context).size;
                    context.read<ScreenSizeBloc>().add(ScreenSizeChanged(size));
                    return SubscriptionReminderWrapper(child: child!);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Wrapper widget that handles connectivity and maintenance mode
class AppWrapper extends StatelessWidget {
  const AppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityCubit, ConnectivityStatus>(
      builder: (context, connectivityState) {
        return BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, settingsState) {
            // Check for maintenance mode
            if (settingsState is SettingsLoaded &&
                settingsState.maintenanceMode) {
              // Show maintenance screen with MaterialApp wrapper for theming
              return _buildMaterialWrapper(
                context,
                const MaintenanceScreenWrapper(),
              );
            }

            // Check for no internet
            if (connectivityState == ConnectivityStatus.disconnected) {
              return _buildMaterialWrapper(
                context,
                NoInternetScreenWrapper(
                  onRetry: () {
                    context.read<ConnectivityCubit>().checkConnection();
                  },
                ),
              );
            }

            // Normal app
            return const MyApp();
          },
        );
      },
    );
  }

  Widget _buildMaterialWrapper(BuildContext context, Widget child) {
    return BlocBuilder<LanguageCubit, Locale>(
      builder: (context, locale) {
        return BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              locale: locale,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              home: child,
            );
          },
        );
      },
    );
  }
}

/// Wrapper for MaintenanceScreen to access localization
class MaintenanceScreenWrapper extends StatelessWidget {
  const MaintenanceScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsCubit>().state;
    final message = settingsState is SettingsLoaded
        ? settingsState.maintenanceMessage
        : null;
    return MaintenanceScreen(message: message);
  }
}

/// Wrapper for NoInternetScreen to access localization
class NoInternetScreenWrapper extends StatelessWidget {
  final VoidCallback onRetry;
  const NoInternetScreenWrapper({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return NoInternetScreen(onRetry: onRetry);
  }
}

// ─── App Lifecycle Observer ───────────────────────────────────────────────────
// Watches for app resume events and triggers Bloc refreshes if the background
// handler previously stored a pending-refresh flag in Hive.
class AppLifecycleObserverWidget extends StatefulWidget {
  final Widget child;
  const AppLifecycleObserverWidget({super.key, required this.child});

  @override
  State<AppLifecycleObserverWidget> createState() =>
      _AppLifecycleObserverWidgetState();
}

class _AppLifecycleObserverWidgetState extends State<AppLifecycleObserverWidget>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndRefreshIfNeeded();
    }
  }

  Future<void> _checkAndRefreshIfNeeded() async {
    try {
      final box = await Hive.openBox('notificationRefreshBox');

      final needsOrderRefresh =
          box.get('pendingOrderRefresh', defaultValue: false) as bool;
      final needsCountRefresh =
          box.get('pendingNotificationCountRefresh', defaultValue: false)
              as bool;

      if (!needsOrderRefresh && !needsCountRefresh) return;

      // Clear flags before dispatching to avoid double-refresh
      await box.put('pendingOrderRefresh', false);
      await box.put('pendingNotificationCountRefresh', false);

      if (!mounted) return;

      if (needsOrderRefresh) {
        context.read<OrdersBloc>().add(RefreshOrders());
        debugPrint(
          '[Lifecycle] Resumed — dispatching RefreshOrders from pending bg notification',
        );
      }
      if (needsCountRefresh) {
        context.read<NotificationListBloc>().add(FetchUnreadCount());
        debugPrint(
          '[Lifecycle] Resumed — dispatching FetchUnreadCount from pending bg notification',
        );
      }
    } catch (e) {
      debugPrint('[Lifecycle] Error checking refresh flag: $e');
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
