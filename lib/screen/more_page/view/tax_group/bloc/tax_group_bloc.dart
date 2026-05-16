import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/global_keys.dart';
import 'package:hyper_local_seller/bloc/pagination/paginated_state.dart';
import 'package:hyper_local_seller/bloc/pagination/pagination_controller.dart';
import 'package:hyper_local_seller/bloc/pagination/pagination_response.dart';
import 'package:hyper_local_seller/screen/more_page/view/tax_group/model/tax_group_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/tax_group/repo/tax_group_repo.dart';

part 'tax_group_event.dart';
part 'tax_group_state.dart';

class TaxGroupsBloc extends Bloc<TaxGroupsEvent, TaxGroupsState> {
  final TaxGroupsRepo _repo;
  late final PaginationController<TaxGroup> _paginationController;

  TaxGroupsBloc(this._repo) : super(const TaxGroupsState()) {
    _paginationController = PaginationController<TaxGroup>(
      fetcher: _fetchTaxGroups,
      emit: (state) => emit(state),
      perPage: GlobalKeys.perPage,
    );

    on<LoadTaxGroupsInitial>(_onLoadTaxGroupsInitial);
    on<LoadMoreTaxGroups>(_onLoadMoreTaxGroups);
    on<RefreshTaxGroups>(_onRefreshTaxGroups);
    on<TaxGroupsReset>(_onTaxGroupsReset);
  }

  Future<PaginationResponse<TaxGroup>> _fetchTaxGroups(int page, int perPage) async {
    final response = await _repo.getTaxGroups(page: page, perPage: perPage);
    final taxGroupsResponse = TaxGroupsResponse.fromJson(response);
    
    return PaginationResponse(
      items: taxGroupsResponse.data?.taxGroups ?? [],
      total: taxGroupsResponse.data?.total,
      currentPage: page,
    );
  }

  Future<void> _onLoadTaxGroupsInitial(
    LoadTaxGroupsInitial event,
    Emitter<TaxGroupsState> emit,
  ) async {
    if (state.items.isEmpty) {
      await _paginationController.loadInitial();
    }
  }

  Future<void> _onLoadMoreTaxGroups(
    LoadMoreTaxGroups event,
    Emitter<TaxGroupsState> emit,
  ) async {
    await _paginationController.loadNextPage(state);
  }

  Future<void> _onRefreshTaxGroups(
    RefreshTaxGroups event,
    Emitter<TaxGroupsState> emit,
  ) async {
    await _paginationController.refresh(state);
  }

  Future<void> _onTaxGroupsReset(
      TaxGroupsReset event,
      Emitter<TaxGroupsState> emit,
      ) async {
    emit(const TaxGroupsState());
    _paginationController.reset();
  }
}
