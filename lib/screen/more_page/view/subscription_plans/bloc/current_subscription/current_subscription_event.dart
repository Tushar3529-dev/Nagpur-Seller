part of 'current_subscription_bloc.dart';

abstract class CurrentSubscriptionEvent {}

class FetchCurrentSubscription extends CurrentSubscriptionEvent {}

class SyncSubscriptionLimits extends CurrentSubscriptionEvent {}

class ResetCurrentSubscription extends CurrentSubscriptionEvent {}
