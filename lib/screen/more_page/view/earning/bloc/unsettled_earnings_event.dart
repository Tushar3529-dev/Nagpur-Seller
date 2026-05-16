part of 'unsettled_earnings_bloc.dart';

abstract class UnsettledEarningsEvent extends Equatable {
  const UnsettledEarningsEvent();

  @override
  List<Object?> get props => [];
}

class LoadUnsettledEarningsInitial extends UnsettledEarningsEvent {
  final String? search;
  final EarningType? type;
  const LoadUnsettledEarningsInitial({this.search, this.type});

  @override
  List<Object?> get props => [search, type];
}

class LoadMoreUnsettledEarnings extends UnsettledEarningsEvent {}

class RefreshUnsettledEarnings extends UnsettledEarningsEvent {}

class UnsettledEarningsReset extends UnsettledEarningsEvent {}

class SearchUnsettledEarnings extends UnsettledEarningsEvent {
  final String search;
  const SearchUnsettledEarnings(this.search);

  @override
  List<Object?> get props => [search];
}

class ChangeUnsettledType extends UnsettledEarningsEvent {
  final EarningType type;
  const ChangeUnsettledType(this.type);

  @override
  List<Object?> get props => [type];
}

class _UpdateUnsettledEarningsState extends UnsettledEarningsEvent {
  final UnsettledEarningsState state;
  const _UpdateUnsettledEarningsState(this.state);

  @override
  List<Object?> get props => [state];
}
