import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/global_keys.dart';
import 'package:hyper_local_seller/bloc/pagination/paginated_state.dart';
import 'package:hyper_local_seller/bloc/pagination/pagination_controller.dart';
import 'package:hyper_local_seller/bloc/pagination/pagination_response.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/model/subscription_history_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/repo/subscription_history_repo.dart';

part 'subscription_history_event.dart';
part 'subscription_history_state.dart';

class SubscriptionHistoryBloc
    extends Bloc<SubscriptionHistoryEvent, SubscriptionHistoryState> {
  final SubscriptionHistoryRepo _repo;
  late final PaginationController<SubscriptionHistoryEntry>
  _paginationController;

  SubscriptionHistoryBloc(this._repo)
    : super(const SubscriptionHistoryState()) {
    _paginationController = PaginationController<SubscriptionHistoryEntry>(
      fetcher: _fetchSubscriptionHistory,
      emit: (state) => emit(state),
      perPage: GlobalKeys.perPage, // Increased to load more brands
    );

    on<LoadSubscriptionHistoryInitial>(_onLoadSubscriptionHistoryInitial);
    on<LoadMoreSubscriptionHistory>(_onLoadMoreSubscriptionHistory);
    on<RefreshSubscriptionHistory>(_onRefreshSubscriptionHistory);
    on<ClearSubscriptionHistory>(_onClearSubscriptionHistory);
  }

  Future<PaginationResponse<SubscriptionHistoryEntry>>
  _fetchSubscriptionHistory(int page, int perPage) async {
    final response = await _repo.getSubscriptionPlanHistory(
      page: page,
      perPage: perPage,
    );
    final subscriptionHistoryResponse = SubscriptionHistoryResponse.fromJson(
      response,
    );

    return PaginationResponse(
      items: subscriptionHistoryResponse.data?.history ?? [],
      total: subscriptionHistoryResponse.data?.total,
      currentPage: page,
    );
  }

  Future<void> _onLoadSubscriptionHistoryInitial(
    LoadSubscriptionHistoryInitial event,
    Emitter<SubscriptionHistoryState> emit,
  ) async {
    if (state.items.isEmpty) {
      await _paginationController.loadInitial();
    }
  }

  Future<void> _onLoadMoreSubscriptionHistory(
    LoadMoreSubscriptionHistory event,
    Emitter<SubscriptionHistoryState> emit,
  ) async {
    await _paginationController.loadNextPage(state);
  }

  Future<void> _onRefreshSubscriptionHistory(
    RefreshSubscriptionHistory event,
    Emitter<SubscriptionHistoryState> emit,
  ) async {
    await _paginationController.refresh(state);
  }

  Future<void> _onClearSubscriptionHistory(
    ClearSubscriptionHistory event,
    Emitter<SubscriptionHistoryState> emit,
  ) async {
    await _paginationController.loadInitial();
  }
}
