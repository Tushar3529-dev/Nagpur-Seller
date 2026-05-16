import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hyper_local_seller/bloc/pagination/paginated_state.dart';
import 'package:hyper_local_seller/bloc/pagination/pagination_controller.dart';
import 'package:hyper_local_seller/bloc/pagination/pagination_response.dart';
import 'package:hyper_local_seller/config/global_keys.dart';

import '../model/earnings_model.dart';
import '../repo/earning_repo.dart';

part 'settled_earnings_event.dart';
part 'settled_earnings_state.dart';

class SettledEarningsBloc
    extends Bloc<SettledEarningsEvent, SettledEarningsState> {
  final EarningRepository _repo;
  late final PaginationController<EarningData> _paginationController;
  String? _currentSearch;

  SettledEarningsBloc(this._repo) : super(PaginatedState<EarningData>()) {
    _paginationController = PaginationController<EarningData>(
      fetcher: _fetchSettledEarnings,
      emit: (state) => add(_UpdateSettledEarningsState(state)),
      perPage: GlobalKeys.perPage,
    );

    on<LoadSettledEarningsInitial>((event, emit) async {
      _currentSearch = event.search;
      await _paginationController.loadInitial();
    });

    on<SearchSettledEarnings>((event, emit) async {
      _currentSearch = event.search;
      await _paginationController.loadInitial();
    });

    on<LoadMoreSettledEarnings>((event, emit) async {
      await _paginationController.loadNextPage(state);
    });

    on<RefreshSettledEarnings>((event, emit) async {
      await _paginationController.refresh(state);
    });

    on<SettledEarningsReset>((event, emit) async {
      _currentSearch = null;
      emit(PaginatedState<EarningData>());
      _paginationController.reset();
    });

    on<_UpdateSettledEarningsState>((event, emit) => emit(event.state));
  }

  Future<PaginationResponse<EarningData>> _fetchSettledEarnings(
    int page,
    int perPage,
  ) async {
    try {
      final response = await _repo.fetchSettledEarnings(
        page: page,
        perPage: perPage,
        search: _currentSearch,
      );

      final items = response?.data ?? [];

      return PaginationResponse(
        items: items,
        total: response?.total,
        currentPage: page,
      );
    } catch (e) {
      // ignore: avoid_print
      print('SETTLED EARNINGS FETCH ERROR: $e');
      rethrow;
    }
  }
}
