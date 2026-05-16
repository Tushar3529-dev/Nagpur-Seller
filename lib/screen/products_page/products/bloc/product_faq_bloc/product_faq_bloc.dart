import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/bloc/pagination/paginated_state.dart';
import 'package:hyper_local_seller/bloc/pagination/pagination_controller.dart';
import 'package:hyper_local_seller/bloc/pagination/pagination_response.dart';
import 'package:hyper_local_seller/config/global_keys.dart';
import 'package:hyper_local_seller/screen/products_page/products/model/product_faq_model.dart';
import 'package:hyper_local_seller/screen/products_page/products/repo/product_faq_repo.dart';

part 'product_faq_event.dart';
part 'product_faq_state.dart';

class ProductFaqBloc extends Bloc<ProductFaqEvent, ProductFaqState> {
  final ProductFaqRepo _repo;
  late final PaginationController<ProductFaq> _paginationController;

  ProductFaqBloc(this._repo) : super(const ProductFaqState()) {
    _paginationController = PaginationController<ProductFaq>(
      fetcher: _fetchFaqs,
      emit: (paginatedState) => emit(state.copyWith(
        items: paginatedState.items,
        isInitialLoading: paginatedState.isInitialLoading,
        isRefreshing: paginatedState.isRefreshing,
        isPaginating: paginatedState.isPaginating,
        hasMore: paginatedState.hasMore,
        error: paginatedState.error,
        currentPage: paginatedState.currentPage,
        total: paginatedState.total,
      )),
      perPage: GlobalKeys.perPage,
    );

    on<LoadFaqsInitial>(_onLoadFaqsInitial);
    on<LoadMoreFaqs>(_onLoadMoreFaqs);
    on<RefreshFaqs>(_onRefreshFaqs);
    on<SearchFaqs>(_onSearchFaqs);
    on<SaveProductFaq>(_onSaveProductFaq);
    on<DeleteProductFaq>(_onDeleteProductFaq);
    on<ClearProductFaqOperation>((event, emit) => emit(state.copyWith(clearOperation: true)));
    on<ProductFaqReset>(_onReset);
  }

  Future<PaginationResponse<ProductFaq>> _fetchFaqs(int page, int perPage) async {
    final response = await _repo.getProductFaqs(
      page: page,
      perPage: perPage,
      search: state.search,
      productId: state.productId,
    );
    final faqResponse = ProductFaqResponse.fromJson(response);
    return PaginationResponse(
      items: faqResponse.data?.faqs ?? [],
      total: faqResponse.data?.total,
      currentPage: page,
    );
  }

  Future<void> _onLoadFaqsInitial(
    LoadFaqsInitial event,
    Emitter<ProductFaqState> emit,
  ) async {
    emit(state.copyWith(
      productId: event.productId,
      search: event.search,
      overrideFilters: true,
    ));
    await _paginationController.loadInitial(currentState: state);
  }

  Future<void> _onLoadMoreFaqs(
    LoadMoreFaqs event,
    Emitter<ProductFaqState> emit,
  ) async {
    await _paginationController.loadNextPage(state);
  }

  Future<void> _onRefreshFaqs(
    RefreshFaqs event,
    Emitter<ProductFaqState> emit,
  ) async {
    await _paginationController.refresh(state);
  }

  Future<void> _onSearchFaqs(
    SearchFaqs event,
    Emitter<ProductFaqState> emit,
  ) async {
    emit(state.copyWith(
      search: event.query,
      productId: state.productId,
      overrideFilters: true,
    ));
    await _paginationController.loadInitial(currentState: state);
  }

  Future<void> _onSaveProductFaq(
    SaveProductFaq event,
    Emitter<ProductFaqState> emit,
  ) async {
    // Note: We don't change state to "OperationLoading" via a new class anymore, 
    // instead we can add fields to the main state if needed, but for now 
    // let's keep it simple and just do the operation and refresh.
    try {
      final response = await _repo.saveProductFaq(
        id: event.id,
        productId: event.productId,
        question: event.question,
        answer: event.answer,
        status: event.status,
      );

      if (response['success'] == true) {
        emit(state.copyWith(
          operationSuccess: true, 
          operationMessage: response['message'] ?? 'FAQ saved successfully'
        ));
        add(RefreshFaqs());
      } else {
        emit(state.copyWith(
          operationSuccess: false, 
          error: response['message'] ?? 'Failed to save FAQ'
        ));
      }
    } catch (e) {
      emit(state.copyWith(operationSuccess: false, error: e.toString()));
    }
  }

  Future<void> _onDeleteProductFaq(
    DeleteProductFaq event,
    Emitter<ProductFaqState> emit,
  ) async {
    try {
      final response = await _repo.deleteProductFaq(event.id);

      if (response['success'] == true) {
        emit(state.copyWith(
          operationSuccess: true, 
          operationMessage: response['message'] ?? 'FAQ deleted successfully'
        ));
        add(RefreshFaqs());
      } else {
        emit(state.copyWith(
          operationSuccess: false, 
          error: response['message'] ?? 'Failed to delete FAQ'
        ));
      }
    } catch (e) {
      emit(state.copyWith(operationSuccess: false, error: e.toString()));
    }
  }

  Future<void> _onReset(
      ProductFaqReset event,
      Emitter<ProductFaqState> emit,
      ) async {
    emit(const ProductFaqState());
    _paginationController.reset();
  }
}
