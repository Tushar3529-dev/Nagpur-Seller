import 'package:hyper_local_seller/config/constant.dart';

class ApiRoutes {
  // DON"T CHANGE ANY OF THIS URLs
  static String mainUrl = '${AppConstants.domainUrl}/api';
  static String baseUrl = '$mainUrl/seller';

  // ROUTES

  // AUTH
  static String registerApi = '$baseUrl/register';
  static String loginApi = '$baseUrl/login';
  static String logoutApi = '$baseUrl/logout';
  static String forgetPasswordApi = '$mainUrl/forget-password';
  static String verifyUserApi = '$mainUrl/verify-user';
  static String callbackApi = '$mainUrl/auth/phone/callback';
  static String customSendOtpApi = '$mainUrl/auth/send-otp';
  static String customVerifyOtpApi = '$mainUrl/auth/verify-otp';

  static String settingsApi = '$mainUrl/settings';

  static String categoriesApi = '$mainUrl/categories';
  static String brandsApi = '$baseUrl/brands';
  static String attributesApi = '$baseUrl/attributes';
  static String attributeValueApi = '$baseUrl/attribute-values';
  static String productsApi = '$baseUrl/products';
  static String productInventoryBaseUrl = '$baseUrl/products';
  static String productFaqsApi = '$baseUrl/product-faqs';
  static String productsEnumsApi = '$productsApi/enums';
  static String productByBarcodeApi = '$mainUrl/products/barcode';
  static String taxGroupsApi = '$baseUrl/tax-classes';
  static String storesApi = '$baseUrl/stores';
  static String storesEnumsApi = '$storesApi/enums';
  static String rolesApi = '$baseUrl/roles';
  static String rolesListApi = '$rolesApi/list';
  static String permissionsApi = '$baseUrl/permissions';
  static String systemUsersApi = '$baseUrl/system-users';
  static String loginApprovalsApi = '$systemUsersApi/login-approvals';
  static String approveLoginApi(int userId) =>
      '$systemUsersApi/$userId/approve-login';
  static String rejectLoginApi(int userId) =>
      '$systemUsersApi/$userId/reject-login';
  static String notificationsApi = '$baseUrl/notifications';
  static String bagsApi = '$baseUrl/bags';

  static String dashboardDataApi = '$baseUrl/dashboard';
  static String ordersApi = '$baseUrl/orders';
  static String ordersEnumsApi = '$ordersApi/enums';
  static String pendingRegularOrdersApi = '$ordersApi/pending-regular';
  static String popupPresenceApi = '$ordersApi/popup-presence';
  static String popupUsersApi = '$ordersApi/popup-users';
  static String fcmTokenApi = '$baseUrl/fcm-token';

  // wallet / transactions
  static String walletApi = '$baseUrl/wallet';
  static String transactionsApi = '$walletApi/transactions';
  static String withdrawalsApi = '$baseUrl/withdrawals';
  static String withdrawalHistoryApi = '$withdrawalsApi/history';

  // commission
  static String unsettledCreditApi = '$baseUrl/commissions';
  static String unsettledDebitApi = '$unsettledCreditApi/debits';
  static String settledEarningsApi = '$unsettledCreditApi/history';

  // profile
  static String updateUserApi = '$mainUrl/user/profile';
  static String changePasswordApi = '$mainUrl/user/change-password';

  // delivery zone
  static String deliveryZonesApi = '$mainUrl/delivery-zone';

  // subscription plans
  static String subscriptionPlansApi = '$mainUrl/subscription/plans';
  static String checkEligibilityApi = '$baseUrl/subscription/check-eligibility';
  static String buySubscriptionPlanApi = '$baseUrl/subscription/buy';
  static String currentSubscriptionPlanApi = '$baseUrl/subscription/current';
  static String subscriptionPlanHistoryApi = '$baseUrl/subscription/history';
  // delivery boys
  static String deliveryBoysApi = '$baseUrl/delivery-boys';
  static String deliveryBoyApi(int id) => '$deliveryBoysApi/$id';
  static String claimDeliveryBoyApi(int id) => '$deliveryBoysApi/$id/claim';
  static String approveDeliveryBoyLoginApi(int id) => '$deliveryBoysApi/$id/approve-login';
  static String rejectDeliveryBoyLoginApi(int id) => '$deliveryBoysApi/$id/reject-login';
  static String deliveryBoyLoginQrApi(int id) => '$deliveryBoysApi/$id/login-qr';
  static String rotateDeliveryBoyLoginQrApi(int id) => '$deliveryBoysApi/$id/rotate-login-qr';
  // rider dispatch
  static String dispatchDashboardApi = '$ordersApi/dispatch-dashboard';
  static String selfDeliverApi(int orderId) => '$ordersApi/$orderId/self-deliver';
  static String riderAvailabilityApi = '$ordersApi/rider-availability';
}
