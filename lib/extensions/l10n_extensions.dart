import 'package:hyper_local_seller/l10n/app_localizations.dart';

extension AppLocalizationsExtension on AppLocalizations {
  String translateEnum(String key) {
    switch (key) {
      case 'simple':
        return simple;
      case 'variant':
        return variant;
      case 'active':
        return active;
      case 'draft':
        return draft;
      case 'pending_verification':
        return pending_verification;
      case 'rejected':
        return rejected;
      case 'approved':
        return approved;
      case 'featured':
        return featured;
      case 'low_stock':
        return low_stock;
      case 'out_of_stock':
        return out_of_stock;
      case 'online':
        return online;
      case 'offline':
        return offline;
      case 'visible':
        return visible;
      case 'not_approved':
        return not_approved;
      case 'awaiting_store_response':
        return awaiting_store_response;
      case 'accepted':
        return accepted;
      case 'preparing':
        return preparing;
      case 'collected':
        return collected;
      case 'delivered':
        return delivered;
      case 'returned':
        return returned;
      case 'refunded':
        return refunded;
      case 'cancelled':
        return cancelled;
      case 'failed':
        return failed;
      case 'last_30_minutes':
        return last_30_minutes;
      case 'last_1_hour':
        return last_1_hour;
      case 'last_5_hours':
        return last_5_hours;
      case 'last_1_day':
        return last_1_day;
      case 'last_7_days':
        return last_7_days;
      case 'last_30_days':
        return last_30_days;
      case 'last_365_days':
        return last_365_days;
      case 'pending':
        return pending;
      default:
        return key
            .replaceAll('_', ' ')
            .split(' ')
            .map(
              (str) => str.isNotEmpty
                  ? "${str[0].toUpperCase()}${str.substring(1)}"
                  : "",
            )
            .join(' ');
    }
  }
}
