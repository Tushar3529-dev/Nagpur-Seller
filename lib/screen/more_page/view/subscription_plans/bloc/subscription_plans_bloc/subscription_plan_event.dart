part of 'subscription_plan_bloc.dart';

abstract class SubscriptionPlanEvent {}

class LoadSubscriptionPlansInitial extends SubscriptionPlanEvent {}

class RefreshSubscriptionPlans extends SubscriptionPlanEvent {}

class SubscriptionPlanReset extends SubscriptionPlanEvent {}
