import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/bloc/store_switcher/store_switcher_cubit.dart';
import 'package:hyper_local_seller/screen/home_page/bloc/home_page/home_page_bloc.dart';
import 'package:hyper_local_seller/screen/home_page/bloc/notification/notification_list_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/attributes/bloc/attributes_bloc/attributes_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/attributes/bloc/attribute_values_bloc/attribute_values_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/brands/bloc/brands_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/categories/bloc/categories_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/delivery_zone/bloc/delivery_zone_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/earning/bloc/settled_earnings_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/earning/bloc/unsettled_earnings_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/profile/bloc/profile_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/roles_and_permissions/bloc/roles_bloc/roles_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/bloc/stores_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/bloc/buy_subscription/buy_subscription_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/bloc/check_eligibility/check_eligibility_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/bloc/current_subscription/current_subscription_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/bloc/my_subscriptions/subscription_history_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/bloc/subscription_plans_bloc/subscription_plan_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/service/subscription_limit_service.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/service/subscription_reminder_service.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/bloc/system_user_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/tax_group/bloc/tax_group_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/wallet/bloc/transactions_bloc/transactions_history_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/wallet/bloc/wallet_bloc/wallet_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/wallet/bloc/withdraw_history_bloc/withdraw_history_bloc.dart';
import 'package:hyper_local_seller/screen/products_page/products/bloc/product_faq_bloc/product_faq_bloc.dart';
import 'package:hyper_local_seller/screen/products_page/products/bloc/products_bloc/products_bloc.dart';
import 'package:hyper_local_seller/screen/order_page/bloc/orders/orders_bloc.dart';
import 'package:hyper_local_seller/screen/order_page/bloc/order_filters_bloc/order_filters_bloc.dart';

import '../screen/more_page/view/subscription_plans/bloc/buy_subscription/buy_subscription_event.dart';

class MasterApiService {
  /// Called after successful login to refresh ALL data for the new user.
  /// This MUST be called BEFORE navigating to the home screen.
  static Future<void> callNeededApisOnLogin(BuildContext context) async {
    debugPrint('[MasterApiService] callNeededApisOnLogin triggered');

    // 0. Sync subscription first (Critical for navigation)
    await SubscriptionLimitService().syncSubscription();

    // 1. Profile (Global)
    context.read<ProfileBloc>().add(
      const ProfileFetchEvent(forceRefresh: true),
    );

    // 2. Current Subscription & History
    context.read<CurrentSubscriptionBloc>().add(FetchCurrentSubscription());
    context.read<SubscriptionHistoryBloc>().add(
      LoadSubscriptionHistoryInitial(),
    );
    context.read<SubscriptionPlanBloc>().add(LoadSubscriptionPlansInitial());

    // 3. Stores (both the list page and the switcher)
    context.read<StoresBloc>().add(LoadStoresInitial());
    context.read<StoreSwitcherCubit>().loadStores();

    // 4. Home dashboard — will be triggered by StoreSwitcherCubit listener
    //    when selectedStore changes, but also fire it directly to be safe
    context.read<HomePageBloc>().add(FetchHomePageData());

    // 5. Orders — will also be refreshed by StoreSwitcherCubit listener
    context.read<OrdersBloc>().add(LoadOrdersInitial());
    context.read<OrderFiltersBloc>().add(FetchOrderFilters());

    // 6. Notifications
    context.read<NotificationListBloc>().add(FetchUnreadCount());
    context.read<NotificationListBloc>().add(LoadNotificationsInitial());

    // 7. Wallet & Earnings
    context.read<WalletBloc>().add(FetchWallet());
    context.read<WithdrawHistoryBloc>().add(LoadHistoryInitial());
    context.read<TransactionsHistoryBloc>().add(LoadTransactionsInitial());
    context.read<SettledEarningsBloc>().add(LoadSettledEarningsInitial());
    context.read<UnsettledEarningsBloc>().add(LoadUnsettledEarningsInitial());

    // 8. Products & related
    context.read<ProductsBloc>().add(LoadProductsInitial());
    context.read<BrandsBloc>().add(LoadBrandsInitial());
    context.read<CategoriesBloc>().add(LoadCategoriesInitial());
    context.read<AttributesBloc>().add(LoadAttributesInitial());
    context.read<ProductFaqBloc>().add(LoadFaqsInitial());

    // 9. Global Settings & Management
    context.read<TaxGroupsBloc>().add(LoadTaxGroupsInitial());
    context.read<RolesBloc>().add(LoadRolesInitial());
    context.read<DeliveryZoneBloc>().add(LoadDeliveryZonesInitial());
    context.read<SystemUserBloc>().add(FetchSystemUsersEvent());
  }

  /// Called on logout to clear ALL cached/session data from every BLoC.
  /// This ensures no stale data from user A is visible when user B logs in.
  static void clearAllApisData(BuildContext context) {
    debugPrint('[MasterApiService] clearAllApisData triggered');

    // Reset subscription reminder service session
    SubscriptionReminderService().resetSession();

    // ── Profile & Home ──
    context.read<ProfileBloc>().add(const ProfileResetEvent());
    context.read<HomePageBloc>().add(HomePageReset());

    // ── Store Switcher ──
    context.read<StoreSwitcherCubit>().clear();

    // ── Subscription related ──
    context.read<CurrentSubscriptionBloc>().add(ResetCurrentSubscription());
    context.read<SubscriptionHistoryBloc>().add(ClearSubscriptionHistory());
    context.read<SubscriptionPlanBloc>().add(SubscriptionPlanReset());
    context.read<BuySubscriptionBloc>().add(BuySubscriptionReset());
    context.read<CheckEligibilityBloc>().add(CheckEligibilityReset());

    // ── Wallet ──
    context.read<WalletBloc>().add(ResetWallet());

    // ── Stores ──
    context.read<StoresBloc>().add(ClearStores());

    // ── Products & related ──
    context.read<ProductsBloc>().add(ClearProducts());
    context.read<BrandsBloc>().add(ClearBrands());
    context.read<CategoriesBloc>().add(ClearCategories());
    context.read<AttributesBloc>().add(AttributesReset());
    context.read<AttributeValuesBloc>().add(AttributeValuesReset());
    context.read<ProductFaqBloc>().add(ProductFaqReset());

    // ── Notifications ──
    context.read<NotificationListBloc>().add(ClearNotifications());

    // ── Orders ──
    context.read<OrdersBloc>().add(OrdersReset());
    context.read<OrderFiltersBloc>().add(ResetOrderFilters());

    // ── Earnings ──
    context.read<SettledEarningsBloc>().add(SettledEarningsReset());
    context.read<UnsettledEarningsBloc>().add(UnsettledEarningsReset());

    // ── Transactions & Withdrawals ──
    context.read<TransactionsHistoryBloc>().add(TransactionsHistoryReset());
    context.read<WithdrawHistoryBloc>().add(WithdrawHistoryReset());

    // ── System Users & Roles ──
    context.read<SystemUserBloc>().add(SystemUserReset());
    context.read<RolesBloc>().add(RolesReset());
    context.read<TaxGroupsBloc>().add(TaxGroupsReset());

    // ── Delivery Zone ──
    context.read<DeliveryZoneBloc>().add(DeliveryZoneReset());
  }
}