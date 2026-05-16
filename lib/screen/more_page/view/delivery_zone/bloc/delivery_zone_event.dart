part of 'delivery_zone_bloc.dart';

@immutable
sealed class DeliveryZoneEvent {}

class LoadDeliveryZonesInitial extends DeliveryZoneEvent {
  final String? search;
  LoadDeliveryZonesInitial({this.search});
}

class LoadMoreDeliveryZones extends DeliveryZoneEvent {}

class RefreshDeliveryZones extends DeliveryZoneEvent {}

class SearchDeliveryZones extends DeliveryZoneEvent {
  final String query;

  SearchDeliveryZones(this.query);
}

class DeliveryZoneReset extends DeliveryZoneEvent {}
