import 'package:equatable/equatable.dart';

abstract class BuySubscriptionEvent extends Equatable {
  const BuySubscriptionEvent();

  @override
  List<Object?> get props => [];
}

class PurchasePlan extends BuySubscriptionEvent {
  final int planId;
  final String paymentType;
  final String? gatewayTransactionId;

  const PurchasePlan({
    required this.planId,
    required this.paymentType,
    this.gatewayTransactionId,
  });

  @override
  List<Object?> get props => [planId, paymentType, gatewayTransactionId];
}

class CheckPaymentStatus extends BuySubscriptionEvent {
  const CheckPaymentStatus();
}

class StartPaymentPolling extends BuySubscriptionEvent {
  const StartPaymentPolling();
}

class StopPaymentPolling extends BuySubscriptionEvent {
  const StopPaymentPolling();
}

class BuySubscriptionReset extends BuySubscriptionEvent {
  const BuySubscriptionReset();
}
