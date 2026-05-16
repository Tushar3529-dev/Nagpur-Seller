import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/api_routes.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(SettingsInitial());

  bool _isFetching = false;

  /*  Future<void> fetchAndSaveSettings() async {
    if (_isFetching) {
      debugPrint('Settings fetch already in progress, skipping...');
      return;
    }
    _isFetching = true;

    // Only emit loading if we don't have existing settings to show
    if (state is! SettingsLoaded) {
      emit(SettingsLoading());
    }

    try {
      final response = await ApiBaseHelper().get(ApiRoutes.settingsApi);
      final data = response['data'] as List<dynamic>;
      final systemEntry = data.firstWhere(
        (item) => item['variable'] == 'system',
        orElse: () => null,
      );

      final paymentEntry = data.firstWhere(
        (item) => item['variable'] == 'payment',
        orElse: () => null,
      );

      final customSmsEntry = data.firstWhere(
        (item) => item['variable'] == 'authentication',
        orElse: () => null,
      );

      if (systemEntry != null && systemEntry['value'] is Map) {
        final systemValue = systemEntry['value'] as Map<String, dynamic>;
        final paymentValue =
            paymentEntry != null && paymentEntry['value'] is Map
            ? paymentEntry['value'] as Map<String, dynamic>
            : null;

        // Filter only the fields we care about
        final filteredSystem = {
          'sellerAppMaintenanceMode':
              systemValue['sellerAppMaintenanceMode'] ?? false,
          'sellerAppMaintenanceMessage':
              systemValue['sellerAppMaintenanceMessage'] ?? '',
          'demoMode': systemValue['demoMode'] ?? false,
          'sellerDemoModeMessage': systemValue['sellerDemoModeMessage'] ?? '',
          'currency': systemValue['currency'] ?? 'USD',
          'currencySymbol': systemValue['currencySymbol'] ?? '\$',
          'systemVendorType': systemValue['systemVendorType'] ?? 'multi',
        };

        final authenticationValue = customSmsEntry != null && customSmsEntry['value'] is Map
            ? customSmsEntry['value'] as Map<String, dynamic>
            : null;

        final isCustomSms = authenticationValue?['customSms'] as bool? ?? false;

        // Save to Hive
        await HiveStorage.setSystemSettings(
          filteredSystem,
          payment: paymentValue,
          isCustomSms: isCustomSms,
        );

        emit(
          SettingsLoaded(
            maintenanceMode: HiveStorage.sellerAppMaintenanceMode,
            maintenanceMessage: HiveStorage.sellerAppMaintenanceMessage,
            isDemoMode: HiveStorage.demoMode,
            demoMessage: HiveStorage.sellerDemoModeMessage,
            currency: HiveStorage.currency,
            currencySymbol: HiveStorage.currencySymbol,
            systemVendorType: HiveStorage.systemVendorType,
            paymentSettings: paymentValue,
          ),
        );
      } else {
        if (state is! SettingsLoaded) {
          emit(SettingsError('System settings not found in response'));
        }
      }

      // Future: handle seller section similarly when ready
      final sellerEntry = data.firstWhere(
        (item) => item['variable'] == 'seller',
        orElse: () => null,
      );
      if (sellerEntry != null) {
        await HiveStorage.setSellerSettings(sellerEntry['value']);
      }
    } catch (e) {
      debugPrint('Settings fetch error: $e');
      if (state is! SettingsLoaded) {
        emit(SettingsError(e.toString()));
      }
    } finally {
      _isFetching = false;
    }
  }*/

  Future<void> fetchAndSaveSettings() async {
    if (_isFetching) {
      debugPrint('Settings fetch already in progress, skipping...');
      return;
    }
    _isFetching = true;

    if (state is! SettingsLoaded) {
      emit(SettingsLoading());
    }

    try {
      final response = await ApiBaseHelper().get(ApiRoutes.settingsApi);
      final data = response['data'] as List<dynamic>;

      // 🧠 Convert list → map (ONLY ONE LOOP)
      final Map<String, dynamic> settingsMap = {
        for (var item in data) item['variable']: item['value'],
      };

      final systemValue = settingsMap['system'] as Map<String, dynamic>?;
      final paymentValue = settingsMap['payment'] as Map<String, dynamic>?;
      final authenticationValue =
          settingsMap['authentication'] as Map<String, dynamic>?;
      final sellerValue = settingsMap['seller'];
      final subscriptionValue =
          settingsMap['subscription'] as Map<String, dynamic>?;

      if (systemValue != null) {
        final filteredSystem = {
          'sellerAppMaintenanceMode':
              systemValue['sellerAppMaintenanceMode'] ?? false,
          'sellerAppMaintenanceMessage':
              systemValue['sellerAppMaintenanceMessage'] ?? '',
          'demoMode': systemValue['demoMode'] ?? false,
          'sellerDemoModeMessage': systemValue['sellerDemoModeMessage'] ?? '',
          'currency': systemValue['currency'] ?? 'USD',
          'currencySymbol': systemValue['currencySymbol'] ?? '\$',
          'systemVendorType': systemValue['systemVendorType'] ?? 'multi',
        };

        final isCustomSms = authenticationValue?['customSms'] as bool? ?? false;

        final isSubscriptionAvailable =
            subscriptionValue?['enableSubscription'] as bool? ?? false;

        await HiveStorage.setSystemSettings(
          filteredSystem,
          payment: paymentValue,
          isCustomSms: isCustomSms,
          isSubscriptionAvailable: isSubscriptionAvailable,
        );

        emit(
          SettingsLoaded(
            maintenanceMode: HiveStorage.sellerAppMaintenanceMode,
            maintenanceMessage: HiveStorage.sellerAppMaintenanceMessage,
            isDemoMode: HiveStorage.demoMode,
            demoMessage: HiveStorage.sellerDemoModeMessage,
            currency: HiveStorage.currency,
            currencySymbol: HiveStorage.currencySymbol,
            systemVendorType: HiveStorage.systemVendorType,
            paymentSettings: paymentValue,
          ),
        );
      } else {
        if (state is! SettingsLoaded) {
          emit(SettingsError('System settings not found in response'));
        }
      }

      // Seller settings
      if (sellerValue != null) {
        await HiveStorage.setSellerSettings(sellerValue);
      }
    } catch (e) {
      debugPrint('Settings fetch error: $e');
      if (state is! SettingsLoaded) {
        emit(SettingsError(e.toString()));
      }
    } finally {
      _isFetching = false;
    }
  }

  // Call this early (e.g. after auth check or app start)
  Future<void> loadCachedSettings() async {
    if (HiveStorage.systemSettings != null) {
      emit(
        SettingsLoaded(
          maintenanceMode: HiveStorage.sellerAppMaintenanceMode,
          maintenanceMessage: HiveStorage.sellerAppMaintenanceMessage,
          isDemoMode: HiveStorage.demoMode,
          demoMessage: HiveStorage.sellerDemoModeMessage,
          currency: HiveStorage.currency,
          currencySymbol: HiveStorage.currencySymbol,
          systemVendorType: HiveStorage.systemVendorType,
          paymentSettings: HiveStorage.paymentSettings,
        ),
      );
    }
  }
}
