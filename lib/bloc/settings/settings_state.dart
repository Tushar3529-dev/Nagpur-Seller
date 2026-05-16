part of 'settings_cubit.dart';

@immutable
sealed class SettingsState {}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final bool maintenanceMode;
  final String maintenanceMessage;
  final bool isDemoMode;
  final String demoMessage;
  final String currency;
  final String currencySymbol;
  final String systemVendorType;
  final Map<String, dynamic>? paymentSettings;

  SettingsLoaded({
    required this.maintenanceMode,
    required this.maintenanceMessage,
    required this.isDemoMode,
    required this.demoMessage,
    required this.currency,
    required this.currencySymbol,
    required this.systemVendorType,
    this.paymentSettings,
  });
}

class SettingsError extends SettingsState {
  final String message;
  SettingsError(this.message);
}
