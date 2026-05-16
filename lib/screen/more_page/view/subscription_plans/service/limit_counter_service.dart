import 'package:hyper_local_seller/l10n/app_localizations.dart';

class LimitCounterService {
  String formatDuration(
    AppLocalizations? l10n,
    String durationType,
    int? durationDays,
  ) {
    if (durationType == 'unlimited') {
      return l10n?.durationUnlimited ?? 'Unlimited';
    }
    if (durationDays != null) {
      return l10n?.durationPerXDays(durationDays) ?? '/ $durationDays days';
    }
    return durationType;
  }

  String getStoresFeatureText(int? rawLimit, AppLocalizations? l10n) {
    final limit = rawLimit ?? -1;

    if (limit < 0) {
      return l10n?.featureStoresUnlimited ?? 'Unlimited Stores';
    }

    return l10n?.featureStores(limit) ??
        'Up to $limit ${limit > 1 ? 'Stores' : 'Store'}';
  }

  String getProductFeatureText(int? rawLimit, AppLocalizations? l10n) {
    final limit = rawLimit ?? -1;

    if (limit < 0) {
      return l10n?.featureProductsUnlimited ?? 'Unlimited Products';
    }

    return l10n?.featureProducts(limit) ??
        'Up to $limit ${limit > 1 ? 'Products' : 'Product'}';
  }

  String getRolesFeatureText(int? rawLimit, AppLocalizations? l10n) {
    final limit = rawLimit ?? -1;

    if (limit < 0) {
      return l10n?.featureRolesUnlimited ?? 'Unlimited Roles';
    }

    return l10n?.featureRoles(limit) ??
        'Up to $limit ${limit > 1 ? 'Roles' : 'Role'}';
  }

  String getSystemUserFeatureText(int? rawLimit, AppLocalizations? l10n) {
    final limit = rawLimit ?? -1;

    if (limit < 0) {
      return l10n?.featureUsersUnlimited ?? 'Unlimited System Users';
    }

    return l10n?.featureUsers(limit) ??
        'Up to $limit ${limit > 1 ? 'System Users' : 'System User'}';
  }
}
