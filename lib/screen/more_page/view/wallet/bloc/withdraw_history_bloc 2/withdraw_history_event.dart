part of 'withdraw_history_bloc.dart';

abstract class WithdrawHistoryEvent extends Equatable {
  const WithdrawHistoryEvent();

  @override
  List<Object?> get props => [];
}

class LoadHistoryInitial extends WithdrawHistoryEvent {}

class LoadMoreHistory extends WithdrawHistoryEvent {}

class RefreshHistory extends WithdrawHistoryEvent {}

class WithdrawHistoryReset extends WithdrawHistoryEvent {}

class _UpdateHistoryState extends WithdrawHistoryEvent {
  final WithdrawHistoryState state;
  const _UpdateHistoryState(this.state);

  @override
  List<Object?> get props => [state];
}
