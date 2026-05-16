part of 'current_subscription_bloc.dart';

abstract class CurrentSubscriptionState {}

class CurrentSubscriptionInitial extends CurrentSubscriptionState {}

class CurrentSubscriptionLoading extends CurrentSubscriptionState {}

class CurrentSubscriptionLoaded extends CurrentSubscriptionState {
  final CurrentPlanData data;
  CurrentSubscriptionLoaded(this.data);
}

class CurrentSubscriptionError extends CurrentSubscriptionState {
  final String message;
  CurrentSubscriptionError(this.message);
}

class CurrentSubscriptionEmpty extends CurrentSubscriptionState {}

class CurrentSubscriptionPending extends CurrentSubscriptionState {
  final CurrentPlanData data;
  CurrentSubscriptionPending(this.data);
}
