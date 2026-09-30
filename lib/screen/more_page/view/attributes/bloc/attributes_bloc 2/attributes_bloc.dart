
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/global_keys.dart';
import 'package:hyper_local_seller/screen/more_page/view/attributes/model/attributes_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/attributes/repo/attributes_repo.dart';
import 'package:hyper_local_seller/bloc/pagination/paginated_state.dart';
import 'package:hyper_local_seller/bloc/pagination/pagination_controller.dart';
import 'package:hyper_local_seller/bloc/pagination/pagination_response.dart';

part 'attributes_event.dart';
part 'attributes_state.dart';

class AttributesBloc extends Bloc<AttributesEvent, AttributesState> {
  final AttributesRepo _repo;
  late final PaginationController<Attribute> _paginationController;

  String? _searchQuery;

  AttributesBloc(this._repo) : super(const AttributesState()) {
    _paginationController = PaginationController<Attribute>(
      fetcher: _fetchAttributes,
      emit: (state) => emit(state),
      perPage: GlobalKeys.perPage,
    );

    on<LoadAttributesInitial>(_onLoadAttributesInitial);
    on<LoadMoreAttributes>(_onLoadMoreAttributes);
    on<RefreshAttributes>(_onRefreshAttributes);
    on<SearchAttributes>(_onSearchAttributes);
    on<AddAttribute>(_onAddAttribute);
    on<UpdateAttribute>(_onUpdateAttribute);
    on<DeleteAttribute>(_onDeleteAttribute);
    on<ClearAttributeOperationState>(_onClearOperationState);
    on<AttributesReset>(_onReset);
  }

  Future<PaginationResponse<Attribute>> _fetchAttributes(int page, int perPage) async {
    final response = await _repo.getAttributes(
      page: page,
      perPage: perPage,
      search: _searchQuery,
    );
    final attributesResponse = AttributesResponse.fromJson(response);
    
    return PaginationResponse(
      items: attributesResponse.data?.attributes ?? [],
      total: attributesResponse.data?.total,
      currentPage: page,
    );
  }

  Future<void> _onLoadAttributesInitial(
    LoadAttributesInitial event,
    Emitter<AttributesState> emit,
  ) async {
    _searchQuery = event.search;
    // Always load initial if search is null (resetting) or state is empty
    if (state.items.isEmpty || _searchQuery == null || event.search != null) {
      await _paginationController.loadInitial();
    }
  }

  Future<void> _onSearchAttributes(
    SearchAttributes event,
    Emitter<AttributesState> emit,
  ) async {
    _searchQuery = event.query;
    await _paginationController.loadInitial();
  }

  Future<void> _onLoadMoreAttributes(
    LoadMoreAttributes event,
    Emitter<AttributesState> emit,
  ) async {
    await _paginationController.loadNextPage(state);
  }

  Future<void> _onRefreshAttributes(
    RefreshAttributes event,
    Emitter<AttributesState> emit,
  ) async {
    await _paginationController.refresh(state);
  }

  Future<void> _onAddAttribute(
    AddAttribute event,
    Emitter<AttributesState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true, clearOperation: true));
    try {
      await _repo.addAttribute(event.data);
      emit(state.copyWith(
        operationSuccess: true,
        operationMessage: "Attribute created successfully",
        isRefreshing: false,
      ));
      add(RefreshAttributes());
    } catch (e) {
      emit(state.copyWith(
        operationSuccess: false,
        error: e.toString(),
        isRefreshing: false,
      ));
    }
  }

  Future<void> _onUpdateAttribute(
    UpdateAttribute event,
    Emitter<AttributesState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true, clearOperation: true));
    try {
      await _repo.updateAttribute(event.id, event.data);
      emit(state.copyWith(
        operationSuccess: true,
        operationMessage: "Attribute updated successfully",
        isRefreshing: false,
      ));
      add(RefreshAttributes());
    } catch (e) {
      emit(state.copyWith(
        operationSuccess: false,
        error: e.toString(),
        isRefreshing: false,
      ));
    }
  }

  Future<void> _onDeleteAttribute(
    DeleteAttribute event,
    Emitter<AttributesState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true, clearOperation: true));
    try {
      await _repo.deleteAttribute(event.id);
      emit(state.copyWith(
        operationSuccess: true,
        operationMessage: "Attribute deleted successfully",
        isRefreshing: false,
      ));
      add(RefreshAttributes());
    } catch (e) {
      emit(state.copyWith(
        operationSuccess: false,
        error: e.toString(),
        isRefreshing: false,
      ));
    }
  }

  void _onClearOperationState(
    ClearAttributeOperationState event,
    Emitter<AttributesState> emit,
  ) {
    emit(state.copyWith(clearOperation: true));
  }

  Future<void> _onReset(
      AttributesReset event,
      Emitter<AttributesState> emit,
      ) async {
    _searchQuery = null;
    emit(const AttributesState());
    _paginationController.reset();
  }
}
