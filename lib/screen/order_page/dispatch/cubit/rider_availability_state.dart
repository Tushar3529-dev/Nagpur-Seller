import 'package:equatable/equatable.dart';
import 'package:hyper_local_seller/screen/order_page/dispatch/model/dispatch_model.dart';

class RiderAvailabilityState extends Equatable {
  final RiderAvailability? data;
  final bool isLoading;
  final String? error;
  final bool isForbidden;
  final bool expanded;
  final DateTime? lastUpdated;
  const RiderAvailabilityState({
    this.data,
    this.isLoading = false,
    this.error,
    this.isForbidden = false,
    this.expanded = false,
    this.lastUpdated,
  });
  RiderAvailabilityState copyWith({
    RiderAvailability? data,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? isForbidden,
    bool? expanded,
    DateTime? lastUpdated,
  }) => RiderAvailabilityState(
    data: data ?? this.data,
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : error ?? this.error,
    isForbidden: isForbidden ?? this.isForbidden,
    expanded: expanded ?? this.expanded,
    lastUpdated: lastUpdated ?? this.lastUpdated,
  );
  List<AvailableRider> get sortedRiders {
    int group(AvailableRider rider) => rider.isAvailableInRadius
        ? 0
        : rider.status == 'active'
        ? 1
        : 2;
    final riders = [...?data?.riders];
    riders.sort((a, b) {
      final byGroup = group(a).compareTo(group(b));
      if (byGroup != 0) return byGroup;
      if (a.isAvailableInRadius && b.isAvailableInRadius) {
        final distance = a.nearestPickupDistanceM == null
            ? (b.nearestPickupDistanceM == null ? 0 : 1)
            : b.nearestPickupDistanceM == null
            ? -1
            : a.nearestPickupDistanceM!.compareTo(b.nearestPickupDistanceM!);
        if (distance != 0) return distance;
      }
      return a.name.compareTo(b.name);
    });
    return riders;
  }

  @override
  List<Object?> get props => [
    data,
    isLoading,
    error,
    isForbidden,
    expanded,
    lastUpdated,
  ];
}
