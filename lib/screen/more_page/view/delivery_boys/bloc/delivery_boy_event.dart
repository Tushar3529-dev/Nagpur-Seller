part of 'delivery_boy_bloc.dart';

abstract class DeliveryBoyEvent extends Equatable {
  const DeliveryBoyEvent();
  @override
  List<Object?> get props => [];
  @override
  bool get stringify => false;
}

class FetchRiders extends DeliveryBoyEvent {
  final bool silent;
  const FetchRiders({this.silent = false});
  @override
  List<Object?> get props => [silent];
}

class LoadMoreAssigned extends DeliveryBoyEvent {}

class LoadMoreAvailable extends DeliveryBoyEvent {}

class SearchChanged extends DeliveryBoyEvent {
  final String query;
  const SearchChanged(this.query);
  @override
  List<Object?> get props => [query];
}

class ClaimRider extends DeliveryBoyEvent {
  final int id;
  const ClaimRider(this.id);
}

class CreateRider extends DeliveryBoyEvent {
  final String fullName;
  final String email;
  final String? mobile;
  final String password;
  final int deliveryZoneId;
  const CreateRider({
    required this.fullName,
    required this.email,
    this.mobile,
    required this.password,
    required this.deliveryZoneId,
  });
}

class UpdateRider extends CreateRider {
  final int id;
  const UpdateRider(
    this.id, {
    required super.fullName,
    required super.email,
    super.mobile,
    super.password = '',
    required super.deliveryZoneId,
  });
}

class DeleteRider extends DeliveryBoyEvent {
  final int id;
  const DeleteRider(this.id);
}

class ApproveLogin extends DeliveryBoyEvent {
  final int id;
  final int? durationHours;
  const ApproveLogin(this.id, this.durationHours);
}

class RejectLogin extends DeliveryBoyEvent {
  final int id;
  const RejectLogin(this.id);
}

class ClearMessages extends DeliveryBoyEvent {}

class DeliveryBoyReset extends DeliveryBoyEvent {}
