part of 'subscription_history_bloc.dart';

abstract class SubscriptionHistoryEvent {}

class LoadSubscriptionHistoryInitial extends SubscriptionHistoryEvent {
  final String? search;
  LoadSubscriptionHistoryInitial({this.search});
}

class LoadMoreSubscriptionHistory extends SubscriptionHistoryEvent {}

class RefreshSubscriptionHistory extends SubscriptionHistoryEvent {}

class SearchSubscriptionHistory extends SubscriptionHistoryEvent {
  final String query;
  SearchSubscriptionHistory(this.query);
}

class ClearSubscriptionHistory extends SubscriptionHistoryEvent {}