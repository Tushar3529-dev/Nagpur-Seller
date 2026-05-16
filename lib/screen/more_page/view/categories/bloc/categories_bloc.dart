import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/global_keys.dart';
import 'package:hyper_local_seller/screen/more_page/view/categories/model/categories_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/categories/repo/categories_repo.dart';
import 'package:hyper_local_seller/bloc/pagination/paginated_state.dart';
import 'package:hyper_local_seller/bloc/pagination/pagination_controller.dart';
import 'package:hyper_local_seller/bloc/pagination/pagination_response.dart';

part 'categories_event.dart';
part 'categories_state.dart';

class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  final CategoriesRepo _repo;
  late final PaginationController<Category> _paginationController;
  String? _currentSlug;
  String? _currentSearch;

  CategoriesBloc(this._repo) : super(const CategoriesState(isInitialLoading: true)) {
    _paginationController = PaginationController<Category>(
      fetcher: _fetchCategories,
      emit: (state) => emit(state),
      perPage: GlobalKeys.perPage,
    );

    on<LoadCategoriesInitial>(_onLoadCategoriesInitial);
    on<LoadMoreCategories>(_onLoadMoreCategories);
    on<RefreshCategories>(_onRefreshCategories);
    on<SearchCategories>(_onSearchCategories);
    on<ClearCategories>((event, emit) {
      _currentSlug = null;
      _currentSearch = null;
      emit(const CategoriesState(isInitialLoading: true));
    });
  }

  Future<PaginationResponse<Category>> _fetchCategories(
    int page,
    int perPage,
  ) async {
    final response = await _repo.getCategories(
      page: page,
      perPage: perPage,
      slug: _currentSlug,
      search: _currentSearch,
    );
    final categoryResponse = CategoryResponse.fromJson(response);

    return PaginationResponse(
      items: categoryResponse.data?.category ?? [],
      total: categoryResponse.data?.total,
      currentPage: page,
    );
  }

  Future<void> _onLoadCategoriesInitial(
    LoadCategoriesInitial event,
    Emitter<CategoriesState> emit,
  ) async {
    bool paramsChanged =
        _currentSlug != event.slug || _currentSearch != event.search;
    _currentSlug = event.slug;
    _currentSearch = event.search;

    if (state.items.isEmpty || paramsChanged || _currentSearch == null) {
      await _paginationController.loadInitial();
    }
  }

  Future<void> _onLoadMoreCategories(
    LoadMoreCategories event,
    Emitter<CategoriesState> emit,
  ) async {
    await _paginationController.loadNextPage(state);
  }

  Future<void> _onRefreshCategories(
    RefreshCategories event,
    Emitter<CategoriesState> emit,
  ) async {
    await _paginationController.refresh(state);
  }

  Future<void> _onSearchCategories(
    SearchCategories event,
    Emitter<CategoriesState> emit,
  ) async {
    _currentSearch = event.query;
    await _paginationController.loadInitial(currentState: state);
  }
}
