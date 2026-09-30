import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/bloc/pagination/paginated_state.dart';
import 'package:hyper_local_seller/bloc/pagination/pagination_controller.dart';
import 'package:hyper_local_seller/bloc/pagination/pagination_response.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/model/subscription_plans_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/repo/subscription_plans_repo.dart';

part 'subscription_plan_event.dart';
part 'subscription_plan_state.dart';

class SubscriptionPlanBloc
    extends Bloc<SubscriptionPlanEvent, SubscriptionPlanState> {
  final SubscriptionPlansRepo _repo;

  // Settings are a one-off object alongside the list — store as instance var
  SubscriptionSettings? settings;

  late final PaginationController<SubscriptionPlan> _paginationController;

  SubscriptionPlanBloc(this._repo) : super(const PaginatedState()) {
    _paginationController = PaginationController<SubscriptionPlan>(
      fetcher: _fetchPlans,
      emit: (state) => emit(state),
    );

    on<LoadSubscriptionPlansInitial>(_onLoadInitial);
    on<RefreshSubscriptionPlans>(_onRefresh);
    on<SubscriptionPlanReset>(_onReset);
  }

  Future<PaginationResponse<SubscriptionPlan>> _fetchPlans(
    int page,
    int perPage,
  ) async {
    final response = await _repo.getSubscriptionPlans();
    final parsed = SubscriptionPlansResponse.fromJson(response);

    // Cache settings so the view can read it
    settings = parsed.data?.settings;

    final plans = parsed.data?.plans ?? [];

    return PaginationResponse<SubscriptionPlan>(
      items: plans,
      total: plans.length,
      hasMore: false, // All plans returned in a single response, no pagination
    );
  }

  Future<void> _onLoadInitial(
    LoadSubscriptionPlansInitial event,
    Emitter<SubscriptionPlanState> emit,
  ) async {
    if (state.items.isEmpty) {
      await _paginationController.loadInitial();
    }
  }

  Future<void> _onRefresh(
    RefreshSubscriptionPlans event,
    Emitter<SubscriptionPlanState> emit,
  ) async {
    await _paginationController.refresh(state);
  }

  void _onReset(
      SubscriptionPlanReset event,
      Emitter<SubscriptionPlanState> emit,
      ) {
    settings = null;
    emit(const PaginatedState());
    _paginationController.reset();
  }
}
