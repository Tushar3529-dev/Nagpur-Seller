part of 'transactions_history_bloc.dart';

abstract class TransactionsHistoryEvent extends Equatable {
  const TransactionsHistoryEvent();

  @override
  List<Object?> get props => [];
}

class LoadTransactionsInitial extends TransactionsHistoryEvent {}

class LoadMoreTransactions extends TransactionsHistoryEvent {}

class RefreshTransactionsHistory extends TransactionsHistoryEvent {}

class TransactionsHistoryReset extends TransactionsHistoryEvent {}

class _UpdateTransactionsState extends TransactionsHistoryEvent {
  final TransactionsHistoryState state;
  const _UpdateTransactionsState(this.state);

  @override
  List<Object?> get props => [state];
}
