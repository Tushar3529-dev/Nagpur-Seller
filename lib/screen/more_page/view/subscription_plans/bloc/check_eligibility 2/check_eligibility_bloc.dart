import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/model/plan_eligibility_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/repo/subscription_plans_repo.dart';

part 'check_eligibility_event.dart';
part 'check_eligibility_state.dart';

class CheckEligibilityBloc
    extends Bloc<CheckEligibilityEvent, CheckEligibilityState> {
  final SubscriptionPlansRepo _repo;

  CheckEligibilityBloc(this._repo) : super(CheckEligibilityInitial()) {
    on<CheckSubscriptionAvailability>((
      CheckSubscriptionAvailability event,
      Emitter<CheckEligibilityState> emit,
    ) async {
      emit(CheckEligibilityLoading());
      try {
        final response = await _repo.checkSubscriptionEligibility(event.planId);

        final eligibilityResponse = EligibilityResponse.fromJson(response);

        if (eligibilityResponse.data == null) {
          emit(
            CheckEligibilityFailure(
              eligibilityResponse.message ?? 'No eligibility data received',
            ),
          );
          return;
        }

        emit(CheckEligibilitySuccess(eligibilityResponse.data!));
      } catch (e) {
        emit(CheckEligibilityFailure(e.toString()));
      }
    });

    on<CheckEligibilityReset>((event, emit) => emit(CheckEligibilityInitial()));
  }
}
