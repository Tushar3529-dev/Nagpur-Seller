import 'package:equatable/equatable.dart';

abstract class BuySubscriptionState extends Equatable {
  const BuySubscriptionState();

  @override
  List<Object?> get props => [];
}

class BuySubscriptionInitial extends BuySubscriptionState {}

class BuySubscriptionLoading extends BuySubscriptionState {}

class BuySubscriptionSuccess extends BuySubscriptionState {
  final String message;
  final dynamic data;

  const BuySubscriptionSuccess({required this.message, this.data});

  @override
  List<Object?> get props => [message, data];
}

class BuySubscriptionFailure extends BuySubscriptionState {
  final String message;

  const BuySubscriptionFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

class BuySubscriptionPending extends BuySubscriptionState {
  final String message;
  final int subscriptionId;
  final String paymentUrl;
  final int planId;

  const BuySubscriptionPending({
    required this.message,
    required this.subscriptionId,
    required this.paymentUrl,
    required this.planId,
  });

  @override
  List<Object?> get props => [message, subscriptionId, paymentUrl, planId];
}
