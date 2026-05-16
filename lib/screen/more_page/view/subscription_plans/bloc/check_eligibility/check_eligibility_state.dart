part of 'check_eligibility_bloc.dart';

sealed class CheckEligibilityState extends Equatable {
  const CheckEligibilityState();
  @override
  List<Object> get props => [];
}

final class CheckEligibilityInitial extends CheckEligibilityState {}

final class CheckEligibilityLoading extends CheckEligibilityState {}

final class CheckEligibilitySuccess extends CheckEligibilityState {
  final EligibilityData data;

  const CheckEligibilitySuccess(this.data);
}

final class CheckEligibilityFailure extends CheckEligibilityState {
  final String message;

  const CheckEligibilityFailure(this.message);

  @override
  List<Object> get props => [message];
}
