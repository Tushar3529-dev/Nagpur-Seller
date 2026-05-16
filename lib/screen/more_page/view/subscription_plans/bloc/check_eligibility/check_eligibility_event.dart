part of 'check_eligibility_bloc.dart';

sealed class CheckEligibilityEvent extends Equatable {
  const CheckEligibilityEvent();

  @override
  List<Object?> get props => [];
}

final class CheckSubscriptionAvailability extends CheckEligibilityEvent {
  final int planId;

  const CheckSubscriptionAvailability({required this.planId});

  @override
  List<Object?> get props => [planId];
}

class CheckEligibilityReset extends CheckEligibilityEvent {
  const CheckEligibilityReset();
}
