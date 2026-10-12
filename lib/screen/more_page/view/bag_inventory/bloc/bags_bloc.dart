import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/bloc/pagination/paginated_state.dart';
import 'package:hyper_local_seller/bloc/pagination/pagination_controller.dart';
import 'package:hyper_local_seller/bloc/pagination/pagination_response.dart';
import 'package:hyper_local_seller/screen/more_page/view/bag_inventory/model/bag_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/bag_inventory/repo/bags_repo.dart';

part 'bags_event.dart';

typedef BagsState = PaginatedState<Bag>;

class BagsBloc extends Bloc<BagsEvent, BagsState> {
  final BagsRepo _repo;
  late final PaginationController<Bag> _paginationController;

  String? _status;
  String? _search;

  BagsBloc(this._repo) : super(const BagsState()) {
    _paginationController = PaginationController<Bag>(
      fetcher: _fetchBags,
      emit: (state) => emit(state),
      perPage: 25,
    );

    on<LoadBags>((event, emit) async {
      _status = event.status;
      _search = event.search;
      await _paginationController.loadInitial();
    });
    on<LoadMoreBags>(
      (event, emit) => _paginationController.loadNextPage(state),
    );
    on<RefreshBags>((event, emit) => _paginationController.refresh(state));
  }

  Future<PaginationResponse<Bag>> _fetchBags(int page, int perPage) async {
    final result = await _repo.getBags(
      page: page,
      perPage: perPage,
      status: _status,
      search: _search,
    );
    return PaginationResponse(
      items: result.items,
      total: result.total,
      hasMore: result.currentPage < result.lastPage,
      currentPage: result.currentPage,
    );
  }
}
