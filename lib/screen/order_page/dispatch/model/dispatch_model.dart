import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:hyper_local_seller/service/json_parser.dart';

enum DispatchStatus {
  noNearbyRiders('no_nearby_riders'),
  waitingForDispatch('waiting_for_dispatch'),
  awaitingRiderAcceptance('awaiting_rider_acceptance'),
  riderAssigned('rider_assigned'),
  sellerSelfDelivery('seller_self_delivery'),
  unknown('');

  final String value;
  const DispatchStatus(this.value);
  static DispatchStatus parse(dynamic raw) => values.firstWhere(
    (status) => status != unknown && status.value == raw,
    orElse: () => unknown,
  );
  bool get canSelfDeliver =>
      this == noNearbyRiders ||
      this == waitingForDispatch ||
      this == awaitingRiderAcceptance;
  bool get needsAction => this == noNearbyRiders;
}

String humaniseDispatchValue(String raw) {
  final text = raw.replaceAll('_', ' ').trim();
  return text.isEmpty ? text : '${text[0].toUpperCase()}${text.substring(1)}';
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : {};
String? _optionalString(dynamic value) {
  final text = JsonParser.string(value);
  return text.isEmpty ? null : text;
}

// The API mixes ints, floats (location_age_seconds: 41.43) and numeric strings.
int? _optionalInt(dynamic value) =>
    value == null ? null : num.tryParse(JsonParser.string(value))?.toInt();
// ISO 8601 strings, or Unix epoch seconds (number or numeric string).
DateTime? _localDate(dynamic value) {
  final text = JsonParser.string(value);
  final seconds = num.tryParse(text);
  if (seconds != null) {
    return DateTime.fromMillisecondsSinceEpoch(
      (seconds * 1000).round(),
      isUtc: true,
    ).toLocal();
  }
  return DateTime.tryParse(text)?.toLocal();
}

class DispatchSummary extends Equatable {
  final int readyOrders;
  final int noNearbyRiders;
  final int assignedOrders;
  const DispatchSummary({
    this.readyOrders = 0,
    this.noNearbyRiders = 0,
    this.assignedOrders = 0,
  });
  factory DispatchSummary.fromJson(Map<String, dynamic> json) =>
      DispatchSummary(
        readyOrders: JsonParser.intValue(json['ready_orders']),
        noNearbyRiders: JsonParser.intValue(json['no_nearby_riders']),
        assignedOrders: JsonParser.intValue(json['assigned_orders']),
      );
  bool get hasAlert => noNearbyRiders > 0;
  @override
  List<Object?> get props => [readyOrders, noNearbyRiders, assignedOrders];
}

class DispatchOrder extends Equatable {
  final int orderId;
  final String orderNumber;
  final DispatchStatus status;
  final String rawStatus;
  final int? deliveryBoyId;
  final String? deliveryBoyName;
  final String pickup;
  final int? pickupStoreId;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final int nearbyAvailableRiders;
  final String bagBarcode;
  final DateTime? createdAt;

  const DispatchOrder({
    required this.orderId,
    required this.orderNumber,
    required this.status,
    this.rawStatus = '',
    this.deliveryBoyId,
    this.deliveryBoyName,
    this.pickup = '',
    this.pickupStoreId,
    this.pickupLatitude,
    this.pickupLongitude,
    this.nearbyAvailableRiders = 0,
    this.bagBarcode = '',
    this.createdAt,
  });
  factory DispatchOrder.fromJson(Map<String, dynamic> json) => DispatchOrder(
    orderId: JsonParser.intValue(json['order_id']),
    orderNumber: JsonParser.string(json['order_number']),
    status: DispatchStatus.parse(json['status']),
    rawStatus: JsonParser.string(json['status']),
    deliveryBoyId: _optionalInt(json['delivery_boy_id']),
    deliveryBoyName: _optionalString(json['delivery_boy_name']),
    pickup: JsonParser.string(json['pickup']),
    pickupStoreId: _optionalInt(json['pickup_store_id']),
    pickupLatitude: double.tryParse(JsonParser.string(json['pickup_latitude'])),
    pickupLongitude: double.tryParse(
      JsonParser.string(json['pickup_longitude']),
    ),
    nearbyAvailableRiders: JsonParser.intValue(json['nearby_available_riders']),
    bagBarcode: JsonParser.string(json['bag_barcode']),
    createdAt: _localDate(json['created_at']),
  );
  DispatchOrder copyWith({
    DispatchStatus? status,
    String? rawStatus,
    ValueGetter<int?>? deliveryBoyId,
    ValueGetter<String?>? deliveryBoyName,
  }) => DispatchOrder(
    orderId: orderId,
    orderNumber: orderNumber,
    status: status ?? this.status,
    rawStatus: rawStatus ?? status?.value ?? this.rawStatus,
    deliveryBoyId: deliveryBoyId == null ? this.deliveryBoyId : deliveryBoyId(),
    deliveryBoyName: deliveryBoyName == null
        ? this.deliveryBoyName
        : deliveryBoyName(),
    pickup: pickup,
    pickupStoreId: pickupStoreId,
    pickupLatitude: pickupLatitude,
    pickupLongitude: pickupLongitude,
    nearbyAvailableRiders: nearbyAvailableRiders,
    bagBarcode: bagBarcode,
    createdAt: createdAt,
  );
  @override
  bool get stringify => false;
  @override
  List<Object?> get props => [
    orderId,
    orderNumber,
    status,
    rawStatus,
    deliveryBoyId,
    deliveryBoyName,
    pickup,
    pickupStoreId,
    pickupLatitude,
    pickupLongitude,
    nearbyAvailableRiders,
    bagBarcode,
    createdAt,
  ];
}

class DispatchDashboard extends Equatable {
  final DispatchSummary summary;
  final List<DispatchOrder> orders;
  const DispatchDashboard({
    this.summary = const DispatchSummary(),
    this.orders = const [],
  });
  factory DispatchDashboard.fromJson(Map<String, dynamic> response) {
    final data = _map(response['data']);
    return DispatchDashboard(
      summary: DispatchSummary.fromJson(_map(data['summary'])),
      orders: JsonParser.list(
        data['orders'],
        (value) => DispatchOrder.fromJson(_map(value)),
      ),
    );
  }
  @override
  bool get stringify => false;
  @override
  List<Object?> get props => [summary, orders];
}

enum RiderUnavailableReason {
  inactive('inactive'),
  notVerified('not_verified'),
  noFcmToken('no_fcm_token'),
  locationStale('location_stale'),
  noPickupStore('no_pickup_store'),
  outsidePickupRadius('outside_pickup_radius'),
  pendingOffer('pending_offer'),
  activeDelivery('active_delivery'),
  unknown('');

  final String value;
  const RiderUnavailableReason(this.value);
  static RiderUnavailableReason parse(dynamic raw) => values.firstWhere(
    (reason) => reason != unknown && reason.value == raw,
    orElse: () => unknown,
  );
}

class RiderAvailabilitySummary extends Equatable {
  final int activeRiders;
  final int availableRidersInRadius;
  final int inactiveRiders;
  const RiderAvailabilitySummary({
    this.activeRiders = 0,
    this.availableRidersInRadius = 0,
    this.inactiveRiders = 0,
  });
  factory RiderAvailabilitySummary.fromJson(Map<String, dynamic> json) =>
      RiderAvailabilitySummary(
        activeRiders: JsonParser.intValue(json['active_riders']),
        availableRidersInRadius: JsonParser.intValue(
          json['available_riders_in_radius'],
        ),
        inactiveRiders: JsonParser.intValue(json['inactive_riders']),
      );
  @override
  List<Object?> get props => [
    activeRiders,
    availableRidersInRadius,
    inactiveRiders,
  ];
}

class AvailableRider extends Equatable {
  final int id;
  final String name;
  final String status;
  final String verificationStatus;
  final String? deliveryZone;
  final bool isAvailableInRadius;
  final int? nearestPickupDistanceM;
  final DateTime? locationReportedAt;
  final int? locationAgeSeconds;
  final RiderUnavailableReason? unavailableReason;
  final String? rawUnavailableReason;
  const AvailableRider({
    required this.id,
    required this.name,
    this.status = '',
    this.verificationStatus = '',
    this.deliveryZone,
    this.isAvailableInRadius = false,
    this.nearestPickupDistanceM,
    this.locationReportedAt,
    this.locationAgeSeconds,
    this.unavailableReason,
    this.rawUnavailableReason,
  });
  factory AvailableRider.fromJson(Map<String, dynamic> json) => AvailableRider(
    id: JsonParser.intValue(json['id']),
    name: JsonParser.string(json['name']),
    status: JsonParser.string(json['status']),
    verificationStatus: JsonParser.string(json['verification_status']),
    deliveryZone: _optionalString(json['delivery_zone']),
    isAvailableInRadius: JsonParser.boolValue(json['is_available_in_radius']),
    nearestPickupDistanceM: _optionalInt(json['nearest_pickup_distance_m']),
    locationReportedAt: _localDate(json['location_reported_at']),
    locationAgeSeconds: _optionalInt(json['location_age_seconds']),
    unavailableReason: json['unavailable_reason'] == null
        ? null
        : RiderUnavailableReason.parse(json['unavailable_reason']),
    rawUnavailableReason: json['unavailable_reason'] == null
        ? null
        : JsonParser.string(json['unavailable_reason']),
  );
  @override
  List<Object?> get props => [
    id,
    name,
    status,
    verificationStatus,
    deliveryZone,
    isAvailableInRadius,
    nearestPickupDistanceM,
    locationReportedAt,
    locationAgeSeconds,
    unavailableReason,
    rawUnavailableReason,
  ];
}

class RiderAvailability extends Equatable {
  final RiderAvailabilitySummary summary;
  final List<AvailableRider> riders;
  const RiderAvailability({
    this.summary = const RiderAvailabilitySummary(),
    this.riders = const [],
  });
  factory RiderAvailability.fromJson(Map<String, dynamic> response) {
    final data = _map(response['data']);
    return RiderAvailability(
      summary: RiderAvailabilitySummary.fromJson(_map(data['summary'])),
      riders: JsonParser.list(
        data['riders'],
        (value) => AvailableRider.fromJson(_map(value)),
      ),
    );
  }
  @override
  List<Object?> get props => [summary, riders];
}
