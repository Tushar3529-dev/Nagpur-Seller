import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local_seller/config/global_keys.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/screen/auth/view/forgot_password_page.dart';
import 'package:hyper_local_seller/screen/auth/view/login_page.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/view/subscription_history_page.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/bloc/subscription_plans_bloc/subscription_plan_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/model/subscription_plans_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/repo/subscription_plans_repo.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/view/subscription_plan_details_page.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/view/subscription_payment_webview.dart';
import 'package:hyper_local_seller/screen/auth/view/otp_page.dart';
import 'package:hyper_local_seller/screen/auth/view/sign_up_page.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/view/choose_plan_page.dart';
import 'package:hyper_local_seller/screen/more_page/more_page.dart';
import 'package:hyper_local_seller/screen/more_page/view/attributes/view/attribute_values_page.dart';
import 'package:hyper_local_seller/screen/more_page/view/attributes/view/attributes_page.dart';
import 'package:hyper_local_seller/screen/more_page/view/brands/view/brands_page.dart';
import 'package:hyper_local_seller/screen/more_page/view/categories/bloc/categories_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/categories/repo/categories_repo.dart';
import 'package:hyper_local_seller/screen/more_page/view/categories/view/categories_page.dart';
import 'package:hyper_local_seller/screen/dashboard/dashboard.dart';
import 'package:hyper_local_seller/screen/home_page/view/home_page.dart';
import 'package:hyper_local_seller/screen/more_page/view/profile/view/profile_page.dart';
import 'package:hyper_local_seller/screen/more_page/view/roles_and_permissions/view/permission_page.dart';
import 'package:hyper_local_seller/screen/more_page/view/roles_and_permissions/view/roles_and_permissions_page.dart';
import 'package:hyper_local_seller/screen/more_page/view/settings_content_page.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/view/stores_page.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/add_store/view/add_store_page.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/add_store/view/map_screen.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/view/subscription_plans_page.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/view/system_users_page.dart';
import 'package:hyper_local_seller/screen/more_page/view/wallet/view/transaction_history_page.dart';
import 'package:hyper_local_seller/screen/more_page/view/wallet/view/wallet_page.dart';
import 'package:hyper_local_seller/screen/more_page/view/wallet/view/withdraw_history_page.dart';
import 'package:hyper_local_seller/screen/more_page/view/wallet/view/withdraw_request_page.dart';
import 'package:hyper_local_seller/screen/order_page/view/order_details_page.dart';
import 'package:hyper_local_seller/screen/order_page/view/order_page.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/view/add_product_page.dart';
import 'package:hyper_local_seller/screen/products_page/products/view/product_details_page.dart';
import 'package:hyper_local_seller/screen/products_page/products/view/products_page.dart';
import 'package:hyper_local_seller/screen/splash_screen/view/splash_screen.dart';
import 'package:hyper_local_seller/screen/splash_screen/widgets/intro_slider.dart';
import 'package:hyper_local_seller/screen/more_page/view/tax_group/view/tax_groups_page.dart';
import 'package:hyper_local_seller/screen/more_page/view/earning/view/earning_page.dart';
import 'package:hyper_local_seller/screen/products_page/products/view/product_faqs_page.dart';
import 'package:hyper_local_seller/screen/more_page/view/delivery_zone/view/delivery_zones_page.dart';
import 'package:hyper_local_seller/screen/home_page/view/notification_list_page.dart';

Page platformPage(Widget child) {
  if (Platform.isIOS) {
    return CupertinoPage(child: child);
  } else {
    return MaterialPage(child: child);
  }
}

class AppRoutes {
  static const String splashScreen = '/';
  static const String introSlider = '/intro-slider';
  static const String login = '/login';
  static const String signUp = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String otp = '/otp';
  static const String register = '/register';
  static const String home = '/home';
  static const String orders = '/orders';
  static const String products = '/products';
  static const String productDetails = '/product-details';
  static const String addProduct = '/add-products';
  static const String more = '/more';
  static const String ordersFull = '/orders-full';
  static const String productsFull = '/products-full';
  static const String categories = '/categories';
  static const String brands = '/brands';
  static const String taxGroup = '/tax-group';
  static const String stores = '/stores';
  static const String addStore = '/add-store';
  static const String mapScreen = '/map-screen';
  static const String attributes = '/attributes';
  static const String attributeValues = '/attribute-values';
  static const String orderDetails = '/order-details';
  static const String wallet = '/wallet';
  static const String withdrawRequest = '/withdraw-request';
  static const String withdrawHistory = '/withdraw-history';
  static const String transactionHistory = '/transaction-history';
  static const String earnings = '/earnings';
  static const String productFaqs = '/product-faqs';
  static const String storeConfiguration = '/store-configuration';
  static const String profilePage = '/profile';
  static const String privacyPolicy = '/privacy-policy';
  static const String termsCondition = '/terms-condition';
  static const String rolesAndPermission = '/roles-permission';
  static const String permissions = '/permissions';
  static const String deliveryZones = '/delivery-zones';
  static const String systemUsers = '/system-users';
  static const String notifications = '/notifications';
  static const String subscriptionPlans = '/subscription-plans';
  static const String subscriptionPlanDetails = '/subscription-plan-details';
  static const String subscriptionPaymentWebView =
      '/subscription-payment-webview';
  static const String subscriptionPlanHistory = '/subscription-plan-history';
  static const String subscriptionChoosePlan = '/subscription-choose-plan';
}

class MyAppRoutes {
  static GoRouter router = GoRouter(
    debugLogDiagnostics: true,
    initialLocation: AppRoutes.splashScreen,
    navigatorKey: GlobalKeys.navigatorKey,

    routes: [
      GoRoute(
        path: AppRoutes.splashScreen,
        name: '/',
        pageBuilder: (context, state) => platformPage(SplashScreen()),
      ),

      GoRoute(
        path: AppRoutes.introSlider,
        name: '/intro-slider',
        pageBuilder: (context, state) => platformPage(IntroSlider()),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: '/login',
        pageBuilder: (context, state) => platformPage(const LoginPage()),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        name: '/signup',
        pageBuilder: (context, state) => platformPage(const SignUpPage()),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: '/forgot-password',
        pageBuilder: (context, state) =>
            platformPage(const ForgotPasswordPage()),
      ),
      GoRoute(
        path: AppRoutes.otp,
        name: '/otp',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return platformPage(
            OtpPage(
              verificationId: extra?['verificationId'] as String?,
              phoneNumber: extra?['phoneNumber'] as String?,
            ),
          );
        },
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return Dashboard(
            index: navigationShell.currentIndex,
            navigationShell: navigationShell,
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: '/home',
                pageBuilder: (context, state) => platformPage(HomePage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.orders,
                name: '/order',
                pageBuilder: (context, state) =>
                    platformPage(BackToHomeWrapper(child: OrderPage())),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.products,
                name: '/products',
                pageBuilder: (context, state) =>
                    platformPage(BackToHomeWrapper(child: ProductsPage())),
              ),
            ],
          ),

          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.more,
                name: '/more',
                pageBuilder: (context, state) =>
                    platformPage(BackToHomeWrapper(child: MorePage())),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.addProduct,
        name: '/add-products',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final isEdit = extra?['is_edit'] as bool? ?? false;
          return platformPage(AddProductPage(isEdit: isEdit));
        },
      ),
      GoRoute(
        path: AppRoutes.categories,
        name: '/categories',
        pageBuilder: (context, state) {
          final slug = state.uri.queryParameters['slug'];
          return platformPage(CategoriesPage(categorySlug: slug));
        },
      ),
      GoRoute(
        path: AppRoutes.brands,
        name: '/brands',
        pageBuilder: (context, state) => platformPage(const BrandsPage()),
      ),
      GoRoute(
        path: AppRoutes.taxGroup,
        name: '/tax-group',
        pageBuilder: (context, state) => platformPage(const TaxGroupsPage()),
      ),
      GoRoute(
        path: AppRoutes.stores,
        name: '/stores',
        pageBuilder: (context, state) => platformPage(const StoresPage()),
      ),
      GoRoute(
        path: AppRoutes.addStore,
        name: '/add-store',
        pageBuilder: (context, state) => platformPage(const AddStorePage()),
      ),
      GoRoute(
        path: AppRoutes.mapScreen,
        name: '/map-screen',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return platformPage(
            MapScreen(
              initialLatitude: extra?['latitude'],
              initialLongitude: extra?['longitude'],
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.attributes,
        name: '/attributes',
        pageBuilder: (context, state) => platformPage(const AttributesPage()),
      ),
      GoRoute(
        path: AppRoutes.attributeValues,
        name: '/attribute-values',
        pageBuilder: (context, state) {
          final attribute = state.extra as dynamic;
          return platformPage(AttributeValuesPage(attribute: attribute));
        },
      ),
      GoRoute(
        path: AppRoutes.productDetails,
        name: '/product-details',
        pageBuilder: (context, state) {
          final product = state.extra as dynamic;
          return platformPage(ProductDetailsPage(product: product));
        },
      ),
      GoRoute(
        path: '${AppRoutes.orderDetails}/:id',
        name: '/order-details',
        pageBuilder: (context, state) {
          final idString = state.pathParameters['id'];
          final id = int.tryParse(idString ?? '') ?? 0;
          return platformPage(OrderDetailsPage(orderId: id));
        },
      ),
      GoRoute(
        path: AppRoutes.wallet,
        name: '/wallet',
        pageBuilder: (context, state) => platformPage(const WalletPage()),
      ),
      GoRoute(
        path: AppRoutes.withdrawRequest,
        name: '/withdraw-request',
        pageBuilder: (context, state) =>
            platformPage(const WithdrawRequestPage()),
      ),
      GoRoute(
        path: AppRoutes.withdrawHistory,
        name: '/withdraw-history',
        pageBuilder: (context, state) =>
            platformPage(const WithdrawHistoryPage()),
      ),
      GoRoute(
        path: AppRoutes.transactionHistory,
        name: '/transaction-history',
        pageBuilder: (context, state) =>
            platformPage(const TransactionHistoryPage()),
      ),
      GoRoute(
        path: AppRoutes.earnings,
        name: '/earnings',
        pageBuilder: (context, state) => platformPage(const EarningPage()),
      ),
      GoRoute(
        path: AppRoutes.productFaqs,
        name: '/product-faqs',
        pageBuilder: (context, state) {
          final productIdStr = state.uri.queryParameters['productId'];
          final productId = int.tryParse(productIdStr ?? '');
          return platformPage(ProductFaqsPage(productId: productId));
        },
      ),
      GoRoute(
        path: AppRoutes.profilePage,
        name: '/profile',
        pageBuilder: (context, state) => platformPage(const ProfilePage()),
      ),
      GoRoute(
        path: AppRoutes.ordersFull,
        name: '/orders-full',
        pageBuilder: (context, state) => platformPage(OrderPage()),
      ),
      GoRoute(
        path: AppRoutes.productsFull,
        name: '/products-full',
        pageBuilder: (context, state) => platformPage(ProductsPage()),
      ),
      GoRoute(
        path: AppRoutes.rolesAndPermission,
        name: '/roles-permission',
        pageBuilder: (context, state) => platformPage(RolesAndPermissionPage()),
      ),
      GoRoute(
        path: AppRoutes.permissions,
        name: '/permissions',
        pageBuilder: (context, state) {
          final role = state.uri.queryParameters['role'] ?? '';
          final roleIdStr = state.uri.queryParameters['roleId'] ?? '0';
          final roleId = int.tryParse(roleIdStr) ?? 0;
          return platformPage(PermissionPage(role: role, roleId: roleId));
        },
      ),
      GoRoute(
        path: AppRoutes.deliveryZones,
        name: '/delivery-zones',
        pageBuilder: (context, state) =>
            platformPage(const DeliveryZonesPage()),
      ),
      GoRoute(
        path: AppRoutes.systemUsers,
        name: '/system-users',
        pageBuilder: (context, state) => platformPage(SystemUsersPage()),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        name: '/notifications',
        pageBuilder: (context, state) =>
            platformPage(const NotificationListPage()),
      ),
      GoRoute(
        path: AppRoutes.privacyPolicy,
        name: '/privacy-policy',
        pageBuilder: (context, state) => platformPage(
          SettingsContentPage(
            title: 'Privacy Policy',
            htmlContent: HiveStorage.privacyPolicy,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.termsCondition,
        name: '/terms-condition',
        pageBuilder: (context, state) => platformPage(
          SettingsContentPage(
            title: 'Terms & Condition',
            htmlContent: HiveStorage.termsCondition,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.subscriptionPlans,
        name: '/subscription-plans',
        pageBuilder: (context, state) =>
            platformPage(const SubscriptionPlansPage()),
      ),
      GoRoute(
        path: AppRoutes.subscriptionPlanDetails,
        name: '/subscription-plan-details',
        pageBuilder: (context, state) {
          final plan = state.extra as SubscriptionPlan;
          return platformPage(SubscriptionPlanDetailsPage(plan: plan));
        },
      ),
      GoRoute(
        path: AppRoutes.subscriptionPaymentWebView,
        name: '/subscription-payment-webview',
        pageBuilder: (context, state) {
          final url = state.extra as String;
          return platformPage(SubscriptionPaymentWebView(url: url));
        },
      ),
      GoRoute(
        path: AppRoutes.subscriptionPlanHistory,
        name: '/subscription-plan-history',
        pageBuilder: (context, state) =>
            platformPage(const SubscriptionHistoryPage()),
      ),
      GoRoute(
        path: AppRoutes.subscriptionChoosePlan,
        name: '/subscription-choose-plan',
        pageBuilder: (context, state) => platformPage(const ChoosePlanPage()),
      ),
    ],
  );
}

class BackToHomeWrapper extends StatelessWidget {
  const BackToHomeWrapper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        context.go(AppRoutes.home);
      },
      child: child,
    );
  }
}
