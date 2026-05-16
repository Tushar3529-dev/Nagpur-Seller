import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/bloc/pagination/paginated_state.dart';
import 'package:hyper_local_seller/bloc/pagination/pagination_controller.dart';
import 'package:hyper_local_seller/bloc/pagination/pagination_response.dart';
import 'package:hyper_local_seller/config/global_keys.dart';

import '../../model/transactions_model.dart';
import '../../repo/wallet_repo.dart';

part 'transactions_history_event.dart';
part 'transactions_history_state.dart';

class TransactionsHistoryBloc
    extends Bloc<TransactionsHistoryEvent, TransactionsHistoryState> {
  final WalletRepository _repo;
  late final PaginationController<TransactionData> _paginationController;

  TransactionsHistoryBloc(this._repo)
    : super(PaginatedState<TransactionData>()) {
    _paginationController = PaginationController<TransactionData>(
      fetcher: _fetchTransactions,
      emit: (state) => add(_UpdateTransactionsState(state)),
      perPage: GlobalKeys.perPage,
    );

    on<LoadTransactionsInitial>((event, emit) async {
      await _paginationController.loadInitial();
    });

    on<LoadMoreTransactions>((event, emit) async {
      await _paginationController.loadNextPage(state);
    });

    on<RefreshTransactionsHistory>((event, emit) async {
      await _paginationController.refresh(state);
    });

    on<TransactionsHistoryReset>((event, emit) async {
      emit(PaginatedState<TransactionData>());
      _paginationController.reset();
    });

    on<_UpdateTransactionsState>((event, emit) => emit(event.state));
  }

  Future<PaginationResponse<TransactionData>> _fetchTransactions(
    int page,
    int perPage,
  ) async {
    try {
      final response = await _repo.fetchTransactions(
        page: page,
        perPage: perPage,
      );

      final items = response?.data ?? [];

      // ignore: avoid_print
      print(
        'TRANSACTIONS FETCHED: Page $page, Items: ${items.length}, Total: ${response?.total}',
      );

      return PaginationResponse(
        items: items,
        total: response?.total,
        currentPage: page,
      );
    } catch (e) {
      // ignore: avoid_print
      print('TRANSACTIONS FETCH ERROR: $e');
      rethrow;
    }
  }
}
