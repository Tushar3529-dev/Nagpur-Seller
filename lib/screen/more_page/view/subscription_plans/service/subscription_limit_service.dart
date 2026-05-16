import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/repo/subscription_plans_repo.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/model/current_plan_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/repo/store_repo.dart';
import 'package:hyper_local_seller/screen/products_page/products/repo/products_repo.dart';
import 'package:hyper_local_seller/screen/more_page/view/roles_and_permissions/repo/roles_repo.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/repo/system_users_repo.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/service/subscription_reminder_service.dart';

class SubscriptionLimitService {
  final SubscriptionPlansRepo _subscriptionRepo = SubscriptionPlansRepo();
  final StoresRepo _storesRepo = StoresRepo();
  final ProductsRepo _productsRepo = ProductsRepo();
  final RolesRepo _rolesRepo = RolesRepo();
  final SystemUsersRepo _systemUsersRepo = SystemUsersRepo();

  /// Sync subscription limits from API to local storage (Hive)
  Future<void> syncSubscription() async {
    try {
      final response = await _subscriptionRepo.getCurrentSubscriptionPlan();
      final currentPlan = CurrentPlanResponse.fromJson(response);

      if (currentPlan.success == true && currentPlan.data != null) {
        final data = currentPlan.data!;

        if (data.status == 'active') {
          final limits = data.snapshot?.limits ?? data.plan?.limits;

          await HiveStorage.setSubscriptionLimits(
            storeLimit: limits?.storeLimit,
            productLimit: limits?.productLimit,
            roleLimit: limits?.roleLimit,
            systemUserLimit: limits?.systemUserLimit,
            status: data.status,
            startDate: data.startDate,
            endDate: data.endDate,
            activePlanId: data.planId,
            activePlanName: data.snapshot?.planName ?? data.plan?.name,
          );
          // If active, ensure pending is cleared just in case
          await HiveStorage.clearPendingSubscription();
          debugPrint('Subscription limits synced successfully');
        } else if (data.status == 'pending') {
          // It's pending, keep limits cleared but save pending state if needed
          await HiveStorage.clearSubscriptionLimits();

          if (data.transactions != null && data.transactions!.isNotEmpty) {
            final tx = data.transactions!.first;
            await HiveStorage.setPendingSubscription(
              subscriptionId: tx.sellerSubscriptionId,
              planId: data.planId,
              paymentUrl: HiveStorage.pendingPaymentUrl ?? '',
              transactionId: tx.transactionId,
              paymentGateway: tx.paymentGateway,
            );
          }
          debugPrint('Subscription is pending');
        } else {
          // Other statuses (expired, cancelled)
          await HiveStorage.clearSubscriptionLimits();
          await HiveStorage.clearPendingSubscription();
          SubscriptionReminderService().hideReminderOverlay();
          debugPrint('Subscription status is ${data.status}, limits cleared');
        }
      } else {
        await HiveStorage.clearSubscriptionLimits();
        await HiveStorage.clearPendingSubscription();
        SubscriptionReminderService().hideReminderOverlay();
        debugPrint('No active subscription found, limits cleared');
      }
    } catch (e) {
      debugPrint('Error syncing subscription: $e');
    }
  }

  /// Get current usage counts for all resources
  Future<Map<String, int>> fetchUsageCounts() async {
    try {
      final results = await Future.wait([
        _storesRepo.getStores(),
        _productsRepo.getProducts(),
        _rolesRepo.getRoles(),
        _systemUsersRepo.getSystemUsers(),
      ]);

      debugPrint(
        'Fetched usage counts::: STORES: ${results[0]['data']['total']}',
      );
      debugPrint(
        'Fetched usage counts::: PRODUCTS: ${results[1]['data']['total']}',
      );
      debugPrint(
        'Fetched usage counts::: ROLES: ${results[2]['data']['total']}',
      );
      debugPrint(
        'Fetched usage counts::: SYSTEM USERS: ${results[3]['data']['total']}',
      );

      return {
        'stores': results[0]['data']['total'] ?? 0,
        'products': results[1]['data']['total'] ?? 0,
        'roles': results[2]['data']['total'] ?? 0,
        'systemUsers': results[3]['data']['total'] ?? 0,
      };
    } catch (e) {
      debugPrint('Error fetching usage counts: $e');
      return {'stores': 0, 'products': 0, 'roles': 0, 'systemUsers': 0};
    }
  }

  /// Validation: Can create a new store?
  Future<bool> canCreateStore() async {
    if (!HiveStorage.isSubscriptionAvailable) {
      return true;
    }
    try {
      final response = await _storesRepo.getStores();
      final total = response['data']['total'] ?? 0;
      debugPrint("TOTAL STORES FROM API ::: $total");
      final limit = HiveStorage.storeLimit;
      debugPrint("TOTAL STORES LIMIT ::: $limit");

      // -1 means unlimited
      if (limit == -1) {
        return true;
      }

      return total < limit;
    } catch (e) {
      debugPrint('Error checking store limit: $e');
      return false;
    }
  }

  /// Validation: Can create a new product?
  Future<bool> canCreateProduct() async {
    if (!HiveStorage.isSubscriptionAvailable) {
      return true;
    }
    try {
      final response = await _productsRepo.getProducts();
      final total = response['data']['total'] ?? 0;
      debugPrint("TOTAL PRODUCTS FROM API ::: $total");
      final limit = HiveStorage.productLimit;
      debugPrint("TOTAL PRODUCTS LIMIT ::: $limit");

      // -1 means unlimited
      if (limit == -1) {
        return true;
      }

      return total < limit;
    } catch (e) {
      debugPrint('Error checking product limit: $e');
      return false;
    }
  }

  /// Validation: Can create a new role?
  Future<bool> canCreateRole() async {
    if (!HiveStorage.isSubscriptionAvailable) {
      return true;
    }
    try {
      final response = await _rolesRepo.getRoles();
      final total = response['data']['total'] ?? 0;
      debugPrint("TOTAL ROLES FROM API ::: $total");
      final limit = HiveStorage.roleLimit;
      debugPrint("TOTAL ROLES LIMIT ::: $limit");

      // -1 means unlimited
      if (limit == -1) {
        return true;
      }

      return total < limit;
    } catch (e) {
      debugPrint('Error checking role limit: $e');
      return false;
    }
  }

  /// Validation: Can create a new system user?
  Future<bool> canCreateSystemUser() async {
    if (!HiveStorage.isSubscriptionAvailable) {
      return true;
    }
    try {
      final response = await _systemUsersRepo.getSystemUsers();
      final total = response['data']['total'] ?? 0;
      debugPrint("TOTAL SYSTEM USERS FROM API ::: $total");
      final limit = HiveStorage.systemUserLimit;
      debugPrint("TOTAL SYSTEM USERS LIMIT ::: $limit");

      // -1 means unlimited
      if (limit == -1) {
        return true;
      }

      return total < limit;
    } catch (e) {
      debugPrint('Error checking system user limit: $e');
      return false;
    }
  }
}
