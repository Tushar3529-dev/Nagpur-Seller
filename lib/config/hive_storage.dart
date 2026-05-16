import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';

class HiveStorage {
  static const String _prefBoxName = "AppPrefs";

  // Is first time -------------------------------------------------------------
  static const String _isFirstTimeKey = "isFirstTime";
  static bool? _isFirstTime;

  static const String _isFirstTimeSubscriptionVisitKey =
      "isFirstTimeSubscriptionVisit";
  static bool? _isFirstTimeSubscriptionVisit;

  static const String _choosePlanRemindTimeKey = "choosePlanRemindTime";
  static String? _choosePlanRemindTime;

  static Future<void> initPrefs() async {
    try {
      final Box prefBox = await Hive.openBox(_prefBoxName);
      _isFirstTime =
          prefBox.get(_isFirstTimeKey, defaultValue: true) as bool? ?? true;
      _languageCode = prefBox.get(_languageKey, defaultValue: 'en') as String?;
      _themeMode = prefBox.get(_themeKey, defaultValue: 'light') as String?;
      _selectedStoreId = prefBox.get(_selectedStoreIdKey) as int?;
      _fcmToken = prefBox.get(_fcmTokenKey) as String?;
      _apnsToken = prefBox.get(_apnsTokenKey) as String?;
      _accessToken = prefBox.get(_accessTokenKey) as String?;
      _isFirstTimeSubscriptionVisit =
          prefBox.get(_isFirstTimeSubscriptionVisitKey, defaultValue: true)
              as bool? ??
          true;
      _storeLimit = prefBox.get(_storeLimitKey) as int?;
      _productLimit = prefBox.get(_productLimitKey) as int?;
      _roleLimit = prefBox.get(_roleLimitKey) as int?;
      _systemUserLimit = prefBox.get(_systemUserLimitKey) as int?;
      _subscriptionStatus = prefBox.get(_subscriptionStatusKey) as String?;
      _subscriptionStartDate =
          prefBox.get(_subscriptionStartDateKey) as String?;
      _subscriptionEndDate = prefBox.get(_subscriptionEndDateKey) as String?;
      _activePlanId = prefBox.get(_activePlanIdKey) as int?;
      _activePlanName = prefBox.get(_activePlanNameKey) as String?;
      _pendingSubscriptionId = prefBox.get(_pendingSubscriptionIdKey) as int?;
      _pendingPlanId = prefBox.get(_pendingPlanIdKey) as int?;
      _pendingPaymentUrl = prefBox.get(_pendingPaymentUrlKey) as String?;
      _pendingTransactionId = prefBox.get(_pendingTransactionIdKey) as String?;
      _pendingPaymentGateway =
          prefBox.get(_pendingPaymentGatewayKey) as String?;
      _isSubscriptionAvailable =
          prefBox.get(_subscriptionAvailableKey) as bool?;

      final rawSeller = prefBox.get(_sellerSettingsKey);
      if (rawSeller is Map) {
        _sellerSettings = Map<String, dynamic>.from(rawSeller);
      }

      // Hive stores Map<dynamic, dynamic>, need to cast carefully if needed
      final rawData = prefBox.get(_userDataKey);
      if (rawData is Map) {
        _userData = rawData;
      }

      final rawSystem = prefBox.get(_systemSettingsKey);
      if (rawSystem is Map) {
        _systemSettings = Map<String, dynamic>.from(rawSystem);
      }

      final rawPayment = prefBox.get(_paymentSettingsKey);
      if (rawPayment is Map) {
        _paymentSettings = Map<String, dynamic>.from(rawPayment);
      }

      debugPrint('System settings loaded: $_systemSettings');
      debugPrint('Initialize Prefs :: isFirstTime $_isFirstTime');
      debugPrint('Initialize Prefs :: languageCode $_languageCode');
      debugPrint('Initialize Prefs :: themeMode $_themeMode');
      debugPrint('Initialize Prefs :: accessToken $_accessToken');
      debugPrint('Initialize Prefs :: fcmToken $_fcmToken');
    } catch (e) {
      debugPrint('Failed to initialize Prefs :: $e ');
    }
  }

  static bool get isFirstTime => _isFirstTime ?? true;

  static bool get isFirstTimeSubscriptionVisit =>
      _isFirstTimeSubscriptionVisit ?? true;

  static Future<void> setIsFirstTime(bool value) async {
    final Box prefBox = await Hive.openBox(_prefBoxName);
    await prefBox.put(_isFirstTimeKey, value);
    _isFirstTime = value;
    debugPrint('Set IsFirstTime :: $_isFirstTime');
  }

  static Future<void> setIsFirstTimeSubscriptionVisit(bool value) async {
    final Box prefBox = await Hive.openBox(_prefBoxName);
    await prefBox.put(_isFirstTimeSubscriptionVisitKey, value);
    _isFirstTimeSubscriptionVisit = value;
    debugPrint('Set IsFirstTimeSubscriptionVisit :: $_isFirstTimeSubscriptionVisit');
  }

  static String? get choosePlanRemindTime => _choosePlanRemindTime;

  static Future<void> setChoosePlanRemindTime(String? value) async {
    final Box prefBox = await Hive.openBox(_prefBoxName);
    if (value == null) {
      await prefBox.delete(_choosePlanRemindTimeKey);
    } else {
      await prefBox.put(_choosePlanRemindTimeKey, value);
    }
    _choosePlanRemindTime = value;
    debugPrint('Set ChoosePlanRemindTime :: $_choosePlanRemindTime');
  }

  // Is first time -------------------------------------------------------------

  // Language ------------------------------------------------------------------
  static const String _languageKey = "languageCode";
  static String? _languageCode;

  static String get languageCode => _languageCode ?? 'en';

  static Future<void> setLanguageCode(String value) async {
    final Box prefBox = await Hive.openBox(_prefBoxName);
    await prefBox.put(_languageKey, value);
    _languageCode = value;
    debugPrint('Set LanguageCode :: $_languageCode');
  }
  // Language ------------------------------------------------------------------

  // Theme ---------------------------------------------------------------------
  static const String _themeKey = "themeMode";
  static String? _themeMode;

  static String get themeMode => _themeMode ?? 'light';

  static Future<void> setThemeMode(String value) async {
    final Box prefBox = await Hive.openBox(_prefBoxName);
    await prefBox.put(_themeKey, value);
    _themeMode = value;
    debugPrint('Set ThemeMode :: $_themeMode');
  }
  // Theme ---------------------------------------------------------------------

  // Selected Store ------------------------------------------------------------
  static const String _selectedStoreIdKey = "selectedStoreId";
  static int? _selectedStoreId;

  static int? get selectedStoreId => _selectedStoreId;

  static Future<void> setSelectedStoreId(int? value) async {
    final Box prefBox = await Hive.openBox(_prefBoxName);
    if (value == null) {
      await prefBox.delete(_selectedStoreIdKey);
    } else {
      await prefBox.put(_selectedStoreIdKey, value);
    }
    _selectedStoreId = value;
    debugPrint('Set SelectedStoreId :: $_selectedStoreId');
  }
  // Selected Store ------------------------------------------------------------

  // System Settings

  static const String _systemSettingsKey = "systemSettings";

  static Map<String, dynamic>? _systemSettings;

  static Map<String, dynamic>? get systemSettings => _systemSettings;

  static bool get sellerAppMaintenanceMode =>
      _systemSettings?['sellerAppMaintenanceMode'] ?? false;

  static String get sellerAppMaintenanceMessage =>
      _systemSettings?['sellerAppMaintenanceMessage'] ??
      "Under maintenance. Please try again later.";

  static bool get demoMode => _systemSettings?['demoMode'] ?? false;

  static String get sellerDemoModeMessage =>
      _systemSettings?['sellerDemoModeMessage'] ??
      "This is a demo account. Some actions are restricted.";

  static String get currency => _systemSettings?['currency'] ?? 'USD';

  static String get currencySymbol =>
      _systemSettings?['currencySymbol'] ?? '\$';

  static String get systemVendorType =>
      _systemSettings?['systemVendorType'] ?? "multiple";

  // Payment Settings
  static const String _paymentSettingsKey = "paymentSettings";
  static Map<String, dynamic>? _paymentSettings;
  static Map<String, dynamic>? get paymentSettings => _paymentSettings;

  static Future<void> setSystemSettings(
    Map<String, dynamic> settings, {
    Map<String, dynamic>? payment,
    bool? isCustomSms,
    bool? isSubscriptionAvailable,
  }) async {
    final box = await Hive.openBox(_prefBoxName);
    await box.put(_systemSettingsKey, settings);
    _systemSettings = settings;

    if (payment != null) {
      await box.put(_paymentSettingsKey, payment);
      _paymentSettings = payment;
    }

    if (isCustomSms != null) {
      await setIsCustomSms(isCustomSms);
    }

    if (isSubscriptionAvailable != null) {
      await setIsSubscriptionAvailable(isSubscriptionAvailable);
    }

    debugPrint('System settings saved to Hive :::: DEMO MODE :::: $demoMode');
  }

  // Future: Seller section (commented for now)
  static const String _sellerSettingsKey = "sellerSettings";

  static Map<String, dynamic>? _sellerSettings;

  static Map<String, dynamic>? get sellerSettings => _sellerSettings;

  static String get termsCondition => _sellerSettings?['termsCondition'] ?? '';

  static String get privacyPolicy => _sellerSettings?['privacyPolicy'] ?? '';

  static Future<void> setSellerSettings(Map<String, dynamic> data) async {
    final box = await Hive.openBox(_prefBoxName);
    await box.put(_sellerSettingsKey, data);
    _sellerSettings = data;
    debugPrint('Seller settings saved');
  }

  // System Settings

  // Auth ----------------------------------------------------------------------
  static const String _fcmTokenKey = "fcmToken";
  static String? _fcmToken;

  static String? get fcmToken => _fcmToken;

  static Future<void> setFcmToken(String? value) async {
    final Box prefBox = await Hive.openBox(_prefBoxName);
    if (value == null) {
      await prefBox.delete(_fcmTokenKey);
    } else {
      await prefBox.put(_fcmTokenKey, value);
    }
    _fcmToken = value;
    debugPrint('Set FcmToken :: $_fcmToken');
  }

  static const String _apnsTokenKey = "apnsToken";
  static String? _apnsToken;

  static String? get apnsToken => _apnsToken;

  static Future<void> setApnsToken(String? value) async {
    final Box prefBox = await Hive.openBox(_prefBoxName);
    if (value == null) {
      await prefBox.delete(_apnsTokenKey);
    } else {
      await prefBox.put(_apnsTokenKey, value);
    }
    _apnsToken = value;
    debugPrint('Set ApnsToken :: $_apnsToken');
  }

  static const String _accessTokenKey = "accessToken";
  static String? _accessToken;

  // Getter for Headers - usually the access token
  static String? get userToken => _accessToken;

  static Future<void> setAccessToken(String? value) async {
    final Box prefBox = await Hive.openBox(_prefBoxName);
    if (value == null) {
      await prefBox.delete(_accessTokenKey);
    } else {
      await prefBox.put(_accessTokenKey, value);
    }
    _accessToken = value;
    debugPrint('Set AccessToken :: $_accessToken');
  }

  static const String _userDataKey = "userData";
  static Map<dynamic, dynamic>? _userData;

  static Map<dynamic, dynamic>? get userData => _userData;

  static Future<void> setUserData(Map<dynamic, dynamic>? value) async {
    final Box prefBox = await Hive.openBox(_prefBoxName);
    if (value == null) {
      await prefBox.delete(_userDataKey);
    } else {
      await prefBox.put(_userDataKey, value);
    }
    _userData = value;
    debugPrint('Set UserData :: $_userData');
  }

  static Future<void> clearAll() async {
    final Box prefBox = await Hive.openBox(_prefBoxName);
    
    // Clear Token and User Data
    await prefBox.delete(_accessTokenKey);
    await prefBox.delete(_userDataKey);
    await prefBox.delete(_selectedStoreIdKey);


    await prefBox.delete(_storeLimitKey);
    await prefBox.delete(_productLimitKey);
    await prefBox.delete(_roleLimitKey);
    await prefBox.delete(_systemUserLimitKey);
    await prefBox.delete(_subscriptionStatusKey);
    await prefBox.delete(_subscriptionStartDateKey);
    await prefBox.delete(_subscriptionEndDateKey);
    await prefBox.delete(_activePlanIdKey);

    _storeLimit = null;
    _productLimit = null;
    _roleLimit = null;
    _systemUserLimit = null;
    _subscriptionStatus = null;
    _subscriptionStartDate = null;
    _subscriptionEndDate = null;
    _activePlanId = null;


    _accessToken = null;
    _userData = null;
    _selectedStoreId = null;

    // Clear Subscription data using sub-methods
    await clearSubscriptionLimits();
    await clearPendingSubscription();

    // Clear auxiliary flags
    await prefBox.delete('subscription_dismiss_date');
    await prefBox.delete(_isFirstTimeSubscriptionVisitKey);
    await prefBox.delete(_choosePlanRemindTimeKey);
    _isFirstTimeSubscriptionVisit = true;
    _choosePlanRemindTime = null;

    debugPrint('Completely cleared user session data and limits');
  }

  // Subscription Limits -------------------------------------------------------
  static const String _storeLimitKey = "storeLimit";
  static const String _productLimitKey = "productLimit";
  static const String _roleLimitKey = "roleLimit";
  static const String _systemUserLimitKey = "systemUserLimit";
  static const String _subscriptionStatusKey = "subscriptionStatus";
  static const String _subscriptionStartDateKey = "subscriptionStartDate";
  static const String _subscriptionEndDateKey = "subscriptionEndDate";
  static const String _activePlanIdKey = "activePlanId";
  static const String _activePlanNameKey = "activePlanName";
  static const String _pendingSubscriptionIdKey = "pendingSubscriptionId";
  static const String _pendingPlanIdKey = "pendingPlanId";
  static const String _pendingPaymentUrlKey = "pendingPaymentUrl";
  static const String _pendingTransactionIdKey = "pendingTransactionId";
  static const String _pendingPaymentGatewayKey = "pendingPaymentGateway";

  static int? _storeLimit;
  static int? _productLimit;
  static int? _roleLimit;
  static int? _systemUserLimit;
  static String? _subscriptionStatus;
  static String? _subscriptionStartDate;
  static String? _subscriptionEndDate;
  static int? _activePlanId;
  static String? _activePlanName;
  static int? _pendingSubscriptionId;
  static int? _pendingPlanId;
  static String? _pendingPaymentUrl;
  static String? _pendingTransactionId;
  static String? _pendingPaymentGateway;

  static int get storeLimit => _storeLimit ?? 0;
  static int get productLimit => _productLimit ?? 0;
  static int get roleLimit => _roleLimit ?? 0;
  static int get systemUserLimit => _systemUserLimit ?? 0;
  static String get subscriptionStatus => _subscriptionStatus ?? 'inactive';
  static String get subscriptionStartDate => _subscriptionStartDate ?? '';
  static String get subscriptionEndDate => _subscriptionEndDate ?? '';
  static int? get activePlanId => _activePlanId;
  static String get activePlanName => _activePlanName ?? '';
  static int? get pendingSubscriptionId => _pendingSubscriptionId;
  static int? get pendingPlanId => _pendingPlanId;
  static String? get pendingPaymentUrl => _pendingPaymentUrl;
  static String? get pendingTransactionId => _pendingTransactionId;
  static String? get pendingPaymentGateway => _pendingPaymentGateway;

  static Future<void> setSubscriptionLimits({
    int? storeLimit,
    int? productLimit,
    int? roleLimit,
    int? systemUserLimit,
    String? status,
    String? startDate,
    String? endDate,
    int? activePlanId,
    String? activePlanName,
  }) async {
    final Box prefBox = await Hive.openBox(_prefBoxName);
    if (storeLimit != null) {
      await prefBox.put(_storeLimitKey, storeLimit);
      _storeLimit = storeLimit;
    }
    if (productLimit != null) {
      await prefBox.put(_productLimitKey, productLimit);
      _productLimit = productLimit;
    }
    if (roleLimit != null) {
      await prefBox.put(_roleLimitKey, roleLimit);
      _roleLimit = roleLimit;
    }
    if (systemUserLimit != null) {
      await prefBox.put(_systemUserLimitKey, systemUserLimit);
      _systemUserLimit = systemUserLimit;
    }
    if (status != null) {
      await prefBox.put(_subscriptionStatusKey, status);
      _subscriptionStatus = status;
    }
    if (startDate != null) {
      await prefBox.put(_subscriptionStartDateKey, startDate);
      _subscriptionStartDate = startDate;
    }
    if (endDate != null) {
      await prefBox.put(_subscriptionEndDateKey, endDate);
      _subscriptionEndDate = endDate;
    }
    if (activePlanId != null) {
      await prefBox.put(_activePlanIdKey, activePlanId);
      _activePlanId = activePlanId;
    }
    if (activePlanName != null) {
      await prefBox.put(_activePlanNameKey, activePlanName);
      _activePlanName = activePlanName;
    }
    debugPrint('Subscription limits updated in Hive');
    debugPrint('SUBSCRIPTION PLAN END DATE :::: $subscriptionEndDate');
    debugPrint(
      'Subscription limits ::: STORE : $storeLimit :: PRODUCT : $productLimit :: ROLE : $roleLimit :: SYSTEM USER : $systemUserLimit :: ACTIVE PLAN ID : $activePlanId',
    );
  }

  static Future<void> clearSubscriptionLimits() async {
    final Box prefBox = await Hive.openBox(_prefBoxName);
    await prefBox.delete(_storeLimitKey);
    await prefBox.delete(_productLimitKey);
    await prefBox.delete(_roleLimitKey);
    await prefBox.delete(_systemUserLimitKey);
    await prefBox.delete(_subscriptionStatusKey);
    await prefBox.delete(_subscriptionStartDateKey);
    await prefBox.delete(_subscriptionEndDateKey);
    await prefBox.delete(_activePlanIdKey);
    await prefBox.delete(_activePlanNameKey);

    _storeLimit = null;
    _productLimit = null;
    _roleLimit = null;
    _systemUserLimit = null;
    _subscriptionStatus = null;
    _subscriptionStartDate = null;
    _subscriptionEndDate = null;
    _activePlanId = null;
    _activePlanName = null;

    debugPrint('Subscription limits cleared from Hive');
  }

  static Future<void> setPendingSubscription({
    required int subscriptionId,
    required int planId,
    required String paymentUrl,
    String? transactionId,
    String? paymentGateway,
  }) async {
    final Box prefBox = await Hive.openBox(_prefBoxName);
    await prefBox.put(_pendingSubscriptionIdKey, subscriptionId);
    await prefBox.put(_pendingPlanIdKey, planId);
    await prefBox.put(_pendingPaymentUrlKey, paymentUrl);
    if (transactionId != null) {
      await prefBox.put(_pendingTransactionIdKey, transactionId);
      _pendingTransactionId = transactionId;
    }
    if (paymentGateway != null) {
      await prefBox.put(_pendingPaymentGatewayKey, paymentGateway);
      _pendingPaymentGateway = paymentGateway;
    }

    _pendingSubscriptionId = subscriptionId;
    _pendingPlanId = planId;
    _pendingPaymentUrl = paymentUrl;

    debugPrint('Pending subscription saved: $subscriptionId');
  }

  static Future<void> clearPendingSubscription() async {
    final Box prefBox = await Hive.openBox(_prefBoxName);
    await prefBox.delete(_pendingSubscriptionIdKey);
    await prefBox.delete(_pendingPlanIdKey);
    await prefBox.delete(_pendingPaymentUrlKey);
    await prefBox.delete(_pendingTransactionIdKey);
    await prefBox.delete(_pendingPaymentGatewayKey);

    _pendingSubscriptionId = null;
    _pendingPlanId = null;
    _pendingPaymentUrl = null;
    _pendingTransactionId = null;
    _pendingPaymentGateway = null;

    debugPrint('Pending subscription cleared');
  }

  // Subscription Limits -------------------------------------------------------

  // Custom SMS -------------------------------------------------------

  static const String _customSmsKey = "isCustomSms";
  static bool? _isCustomSms;

  static bool get isCustomSms => _isCustomSms ?? false;

  static Future<void> setIsCustomSms(bool? value) async {
    final Box prefBox = await Hive.openBox(_prefBoxName);
    if (value == null) {
      await prefBox.delete(_customSmsKey);
    } else {
      await prefBox.put(_customSmsKey, value);
    }
    _isCustomSms = value;
    debugPrint('Set isCustomSms :: $_isCustomSms');
  }

  // Custom SMS -------------------------------------------------------

  // Subscription Available -------------------------------------------------------

  static const String _subscriptionAvailableKey = "isSubscriptionAvailable";
  static bool? _isSubscriptionAvailable;

  static bool get isSubscriptionAvailable => _isSubscriptionAvailable ?? false;

  static Future<void> setIsSubscriptionAvailable(bool? value) async {
    final Box prefBox = await Hive.openBox(_prefBoxName);
    if (value == null) {
      await prefBox.delete(_subscriptionAvailableKey);
    } else {
      await prefBox.put(_subscriptionAvailableKey, value);
    }
    _isSubscriptionAvailable = value;
    debugPrint('Set isSubscriptionAvailable :: $_isSubscriptionAvailable');
  }

  // Subscription Available -------------------------------------------------------
}
