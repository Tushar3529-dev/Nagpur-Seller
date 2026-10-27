import 'package:equatable/equatable.dart';
import 'package:hyper_local_seller/service/json_parser.dart';

/// Why a system user can't receive incoming-order popups right now, from
/// `ineligible_reason` of `GET /seller/orders/popup-users`.
enum PopupIneligibleReason {
  accountInactive('account_inactive'),
  systemUserInactive('system_user_inactive'),
  loginNotApproved('login_not_approved_or_expired'),
  permissionMissing('order_popup_permission_missing'),
  presenceInactive('popup_presence_inactive'),
  locationStale('location_stale'),
  locationUnavailable('location_or_store_unavailable'),
  outsideRadius('outside_200m_radius'),
  orderInProgress('order_in_progress');

  final String value;
  const PopupIneligibleReason(this.value);

  static PopupIneligibleReason? tryParse(dynamic raw) {
    final text = raw?.toString();
    for (final reason in values) {
      if (reason.value == text) return reason;
    }
    return null;
  }
}

class PopupUsersSummary extends Equatable {
  final int totalSystemUsers;
  final int activeUsers;
  final int eligibleUsers;
  final int inactiveUsers;
  final int busyUsers;

  const PopupUsersSummary({
    this.totalSystemUsers = 0,
    this.activeUsers = 0,
    this.eligibleUsers = 0,
    this.inactiveUsers = 0,
    this.busyUsers = 0,
  });

  factory PopupUsersSummary.fromJson(Map json) => PopupUsersSummary(
    totalSystemUsers: JsonParser.intValue(json['total_system_users']),
    activeUsers: JsonParser.intValue(json['active_users']),
    eligibleUsers: JsonParser.intValue(json['eligible_users']),
    inactiveUsers: JsonParser.intValue(json['inactive_users']),
    busyUsers: JsonParser.intValue(json['busy_users']),
  );

  @override
  List<Object?> get props => [
    totalSystemUsers,
    activeUsers,
    eligibleUsers,
    inactiveUsers,
    busyUsers,
  ];
}

class PopupNearestStore extends Equatable {
  final int id;
  final String name;
  final int? distanceM;

  const PopupNearestStore({required this.id, required this.name, this.distanceM});

  factory PopupNearestStore.fromJson(Map json) => PopupNearestStore(
    id: JsonParser.intValue(json['id']),
    name: JsonParser.string(json['name']),
    distanceM: json['distance_m'] == null
        ? null
        : JsonParser.doubleValue(json['distance_m']).round(),
  );

  @override
  List<Object?> get props => [id, name, distanceM];
}

/// The order a user currently holds. Its shape isn't documented beyond
/// being an object, so only common identifiers are read.
class PopupCurrentOffer extends Equatable {
  final int? sellerOrderId;
  final String? orderNumber;
  final String? status;

  const PopupCurrentOffer({this.sellerOrderId, this.orderNumber, this.status});

  factory PopupCurrentOffer.fromJson(Map json) {
    final id = json['seller_order_id'] ?? json['id'];
    return PopupCurrentOffer(
      sellerOrderId: id == null ? null : JsonParser.intValue(id),
      orderNumber: _nonEmpty(json['order_number']),
      status: _nonEmpty(json['status']),
    );
  }

  /// "NM-…" when known, otherwise "#701".
  String get label =>
      orderNumber ?? (sellerOrderId != null ? '#$sellerOrderId' : '');

  @override
  List<Object?> get props => [sellerOrderId, orderNumber, status];
}

class PopupUser extends Equatable {
  final int userId;
  final String name;
  final String? email;
  final String? mobile;
  final List<String> roles;
  final String? systemUserStatus;
  final String? loginApprovalStatus;
  final DateTime? loginApprovedUntil;
  final bool hasOrderPopupPermission;
  final bool popupPresenceActive;
  final bool locationFresh;
  final DateTime? lastSeenAt;
  final PopupNearestStore? nearestStore;
  final bool hasFcmToken;
  final bool isActive;
  final bool isEligible;
  final PopupIneligibleReason? ineligibleReason;

  /// `ineligible_reason` as sent, kept for values this app doesn't know.
  final String? rawIneligibleReason;
  final PopupCurrentOffer? currentOffer;

  const PopupUser({
    required this.userId,
    required this.name,
    this.email,
    this.mobile,
    this.roles = const [],
    this.systemUserStatus,
    this.loginApprovalStatus,
    this.loginApprovedUntil,
    this.hasOrderPopupPermission = false,
    this.popupPresenceActive = false,
    this.locationFresh = false,
    this.lastSeenAt,
    this.nearestStore,
    this.hasFcmToken = false,
    this.isActive = false,
    this.isEligible = false,
    this.ineligibleReason,
    this.rawIneligibleReason,
    this.currentOffer,
  });

  factory PopupUser.fromJson(Map json) {
    final store = json['nearest_store'];
    final offer = json['current_offer'];
    final roles = json['roles'];
    return PopupUser(
      userId: JsonParser.intValue(json['user_id']),
      name: JsonParser.string(json['name']),
      email: _nonEmpty(json['email']),
      mobile: _nonEmpty(json['mobile']),
      roles: roles is List
          ? [
              for (final role in roles)
                if (_nonEmpty(role is Map ? role['name'] : role) case final r?)
                  r,
            ]
          : const [],
      systemUserStatus: _nonEmpty(json['system_user_status']),
      loginApprovalStatus: _nonEmpty(json['login_approval_status']),
      loginApprovedUntil: _date(json['login_approved_until']),
      hasOrderPopupPermission: JsonParser.boolValue(
        json['has_order_popup_permission'],
      ),
      popupPresenceActive: JsonParser.boolValue(json['popup_presence_active']),
      locationFresh: JsonParser.boolValue(json['location_fresh']),
      lastSeenAt: _date(json['last_seen_at']),
      nearestStore: store is Map ? PopupNearestStore.fromJson(store) : null,
      hasFcmToken: JsonParser.boolValue(json['has_fcm_token']),
      isActive: JsonParser.boolValue(json['is_active']),
      isEligible: JsonParser.boolValue(json['is_eligible']),
      ineligibleReason: PopupIneligibleReason.tryParse(
        json['ineligible_reason'],
      ),
      rawIneligibleReason: _nonEmpty(json['ineligible_reason']),
      currentOffer: offer is Map ? PopupCurrentOffer.fromJson(offer) : null,
    );
  }

  @override
  List<Object?> get props => [
    userId,
    name,
    email,
    mobile,
    roles,
    systemUserStatus,
    loginApprovalStatus,
    loginApprovedUntil,
    hasOrderPopupPermission,
    popupPresenceActive,
    locationFresh,
    lastSeenAt,
    nearestStore,
    hasFcmToken,
    isActive,
    isEligible,
    ineligibleReason,
    rawIneligibleReason,
    currentOffer,
  ];
}

/// `GET /seller/orders/popup-users`: who can receive incoming-order popups.
/// Only the main seller owner may read it.
class PopupUsersAvailability extends Equatable {
  final PopupUsersSummary summary;
  final List<PopupUser> users;
  final int locationFreshnessMinutes;
  final int pickupRadiusMeters;

  const PopupUsersAvailability({
    this.summary = const PopupUsersSummary(),
    this.users = const [],
    this.locationFreshnessMinutes = 2,
    this.pickupRadiusMeters = 200,
  });

  factory PopupUsersAvailability.fromJson(Map json) {
    final data = json['data'] is Map ? json['data'] as Map : json;
    final summary = data['summary'];
    final users = data['users'];
    return PopupUsersAvailability(
      summary: summary is Map
          ? PopupUsersSummary.fromJson(summary)
          : const PopupUsersSummary(),
      users: users is List
          ? users.whereType<Map>().map(PopupUser.fromJson).toList()
          : const [],
      locationFreshnessMinutes: JsonParser.intValue(
        data['location_freshness_minutes'],
        fallback: 2,
      ),
      pickupRadiusMeters: JsonParser.intValue(
        data['pickup_radius_meters'],
        fallback: 200,
      ),
    );
  }

  @override
  List<Object?> get props => [
    summary,
    users,
    locationFreshnessMinutes,
    pickupRadiusMeters,
  ];
}

DateTime? _date(dynamic value) =>
    DateTime.tryParse(value?.toString() ?? '')?.toLocal();

String? _nonEmpty(dynamic value) {
  final text = value?.toString().trim();
  return (text == null || text.isEmpty || text == 'null') ? null : text;
}
