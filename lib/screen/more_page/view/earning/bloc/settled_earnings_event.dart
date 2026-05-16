part of 'settled_earnings_bloc.dart';

abstract class SettledEarningsEvent extends Equatable {
  const SettledEarningsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSettledEarningsInitial extends SettledEarningsEvent {
  final String? search;
  const LoadSettledEarningsInitial({this.search});

  @override
  List<Object?> get props => [search];
}

class LoadMoreSettledEarnings extends SettledEarningsEvent {}

class RefreshSettledEarnings extends SettledEarningsEvent {}

class SettledEarningsReset extends SettledEarningsEvent {}

class SearchSettledEarnings extends SettledEarningsEvent {
  final String search;
  const SearchSettledEarnings(this.search);

  @override
  List<Object?> get props => [search];
}

class _UpdateSettledEarningsState extends SettledEarningsEvent {
  final SettledEarningsState state;
  const _UpdateSettledEarningsState(this.state);

  @override
  List<Object?> get props => [state];
}
