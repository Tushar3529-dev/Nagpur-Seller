import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hyper_local_seller/bloc/pagination/paginated_state.dart';
import 'package:hyper_local_seller/bloc/pagination/pagination_controller.dart';
import 'package:hyper_local_seller/bloc/pagination/pagination_response.dart';
import 'package:hyper_local_seller/config/global_keys.dart';

import '../../model/withdrawals_model.dart';
import '../../repo/wallet_repo.dart';

part 'withdraw_history_event.dart';
part 'withdraw_history_state.dart';

class WithdrawHistoryBloc
    extends Bloc<WithdrawHistoryEvent, WithdrawHistoryState> {
  final WalletRepository _repo;
  late final PaginationController<WithdrawalData> _paginationController;

  WithdrawHistoryBloc(this._repo) : super(const WithdrawHistoryState()) {
    _paginationController = PaginationController<WithdrawalData>(
      fetcher: _fetchHistory,
      emit: (state) => add(_UpdateHistoryState(state)),
      perPage: GlobalKeys.perPage,
    );

    on<LoadHistoryInitial>((event, emit) async {
      await _paginationController.loadInitial();
    });

    on<LoadMoreHistory>((event, emit) async {
      await _paginationController.loadNextPage(state);
    });

    on<RefreshHistory>((event, emit) async {
      await _paginationController.refresh(state);
    });

    on<WithdrawHistoryReset>((event, emit) async {
      emit(const WithdrawHistoryState());
      _paginationController.reset();
    });

    on<_UpdateHistoryState>((event, emit) => emit(event.state));
  }

  Future<PaginationResponse<WithdrawalData>> _fetchHistory(
    int page,
    int perPage,
  ) async {
    final response = await _repo.fetchWithdrawalHistory(
      page: page,
      perPage: perPage,
    );
    return PaginationResponse(
      items: response?.data ?? [],
      total: response?.total,
      currentPage: page,
    );
  }
}
