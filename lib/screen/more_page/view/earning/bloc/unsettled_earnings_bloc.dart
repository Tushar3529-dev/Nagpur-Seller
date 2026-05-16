import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/bloc/pagination/paginated_state.dart';
import 'package:hyper_local_seller/bloc/pagination/pagination_controller.dart';
import 'package:hyper_local_seller/bloc/pagination/pagination_response.dart';
import 'package:hyper_local_seller/config/global_keys.dart';

import '../model/earnings_model.dart';
import '../repo/earning_repo.dart';

part 'unsettled_earnings_event.dart';
part 'unsettled_earnings_state.dart';

class UnsettledEarningsBloc
    extends Bloc<UnsettledEarningsEvent, UnsettledEarningsState> {
  final EarningRepository _repo;
  late final PaginationController<EarningData> _paginationController;
  EarningType _currentType = EarningType.credit;
  String? _currentSearch;

  UnsettledEarningsBloc(this._repo) : super(PaginatedState<EarningData>()) {
    _paginationController = PaginationController<EarningData>(
      fetcher: _fetchUnsettledEarnings,
      emit: (state) => add(_UpdateUnsettledEarningsState(state)),
      perPage: GlobalKeys.perPage,
    );

    on<LoadUnsettledEarningsInitial>((event, emit) async {
      if (event.type != null) _currentType = event.type!;
      _currentSearch = event.search;
      await _paginationController.loadInitial();
    });

    on<SearchUnsettledEarnings>((event, emit) async {
      _currentSearch = event.search;
      await _paginationController.loadInitial();
    });

    on<ChangeUnsettledType>((event, emit) async {
      _currentType = event.type;
      await _paginationController.loadInitial();
    });

    on<LoadMoreUnsettledEarnings>((event, emit) async {
      await _paginationController.loadNextPage(state);
    });

    on<RefreshUnsettledEarnings>((event, emit) async {
      await _paginationController.refresh(state);
    });
    
    on<UnsettledEarningsReset>((event, emit) async {
      _currentSearch = null;
      emit(PaginatedState<EarningData>());
      _paginationController.reset();
    });

    on<_UpdateUnsettledEarningsState>((event, emit) => emit(event.state));
  }

  Future<PaginationResponse<EarningData>> _fetchUnsettledEarnings(
    int page,
    int perPage,
  ) async {
    try {
      final response = _currentType == EarningType.credit
          ? await _repo.fetchUnsettledEarnings(
              page: page,
              perPage: perPage,
              search: _currentSearch,
            )
          : await _repo.fetchUnsettledDebitEarnings(
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
      print('UNSETTLED EARNINGS FETCH ERROR: $e');
      rethrow;
    }
  }
}
