import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/model/current_plan_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/repo/subscription_plans_repo.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/service/subscription_limit_service.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/service/subscription_reminder_service.dart';

part 'current_subscription_event.dart';
part 'current_subscription_state.dart';

class CurrentSubscriptionBloc
    extends Bloc<CurrentSubscriptionEvent, CurrentSubscriptionState> {
  final SubscriptionPlansRepo _repo;
  final SubscriptionLimitService _limitService = SubscriptionLimitService();

  CurrentSubscriptionBloc(this._repo) : super(CurrentSubscriptionInitial()) {
    on<FetchCurrentSubscription>(_onFetchCurrentSubscription);
    on<SyncSubscriptionLimits>(_onSyncSubscriptionLimits);
    on<ResetCurrentSubscription>((event, emit) => emit(CurrentSubscriptionInitial()));
  }

  Future<void> _onFetchCurrentSubscription(
    FetchCurrentSubscription event,
    Emitter<CurrentSubscriptionState> emit,
  ) async {
    emit(CurrentSubscriptionLoading());
    try {
      final response = await _repo.getCurrentSubscriptionPlan();
      final currentPlan = CurrentPlanResponse.fromJson(response);

      if (currentPlan.success == true && currentPlan.data != null) {
        // Also sync to Hive when fetching
        await _limitService.syncSubscription();
        if (currentPlan.data!.status == 'pending') {
          emit(CurrentSubscriptionPending(currentPlan.data!));
        } else {
          emit(CurrentSubscriptionLoaded(currentPlan.data!));
        }
      } else if (currentPlan.success == true && currentPlan.data == null) {
        await HiveStorage.clearPendingSubscription();
        await HiveStorage.clearSubscriptionLimits();
        SubscriptionReminderService().hideReminderOverlay();
        emit(CurrentSubscriptionEmpty());
      } else {
        emit(
          CurrentSubscriptionError(
            currentPlan.message ?? 'Failed to fetch current plan',
          ),
        );
      }
    } catch (e) {
      emit(CurrentSubscriptionError(e.toString()));
    }
  }

  Future<void> _onSyncSubscriptionLimits(
    SyncSubscriptionLimits event,
    Emitter<CurrentSubscriptionState> emit,
  ) async {
    await _limitService.syncSubscription();
  }
}
