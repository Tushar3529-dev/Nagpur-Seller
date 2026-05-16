import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/bloc/pagination/paginated_state.dart';
import 'package:hyper_local_seller/bloc/pagination/pagination_controller.dart';
import 'package:hyper_local_seller/bloc/pagination/pagination_response.dart';
import 'package:hyper_local_seller/config/global_keys.dart';
import 'package:hyper_local_seller/screen/products_page/products/model/product_model.dart';
import 'package:hyper_local_seller/screen/products_page/products/model/product_filter_model.dart';
import 'package:hyper_local_seller/screen/products_page/products/repo/products_repo.dart';
part 'products_event.dart';
part 'products_state.dart';

class ProductsBloc extends Bloc<ProductsEvent, ProductsState> {
  final ProductsRepo _repo;
  late final PaginationController<Product> _paginationController;

  String? _searchQuery;

  ProductsBloc(this._repo) : super(const ProductsState(isInitialLoading: true)) {
    _paginationController = PaginationController<Product>(
      fetcher: _fetchProducts,
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
    on<LoadProductsInitial>(_onLoadProductsInitial);
    on<LoadMoreProducts>(_onLoadMoreProducts);
    on<RefreshProducts>(_onRefreshProducts);
    on<DeleteProduct>(_onDeleteProduct);
    on<SearchProducts>(_onSearchProducts);
    on<LoadProductFilters>(_onLoadProductFilters);
    on<ApplyProductFilter>(_onApplyProductFilter);
    on<UpdateProductStatus>(_onUpdateProductStatus);
    on<ClearProducts>((event, emit) => emit(const ProductsState(isInitialLoading: true)));
  }

  Future<PaginationResponse<Product>> _fetchProducts(
    int page,
    int perPage,
  ) async {
    final response = await _repo.getProducts(
      page: page,
      perPage: perPage,
      search: _searchQuery,
      type: state.selectedType,
      status: state.selectedStatus,
      verificationStatus: state.selectedVerificationStatus,
      productFilter: state.selectedProductFilter,
    );
    final productsResponse = ProductsResponse.fromJson(response);

    return PaginationResponse(
      items: productsResponse.data?.products ?? [],
      total: productsResponse.data?.total,
      currentPage: page,
    );
  }

  Future<void> _onLoadProductFilters(
    LoadProductFilters event,
    Emitter<ProductsState> emit,
  ) async {
    try {
      final response = await _repo.getProductFilters();
      final filterModel = ProductFilterModel.fromJson(response);
      emit(state.copyWith(filterOptions: filterModel.productFilter));
    } catch (e) {
      debugPrint("Load filters error: $e");
    }
  }

  Future<void> _onApplyProductFilter(
    ApplyProductFilter event,
    Emitter<ProductsState> emit,
  ) async {
    emit(state.copyWith(
      selectedType: event.type,
      selectedStatus: event.status,
      selectedVerificationStatus: event.verificationStatus,
      selectedProductFilter: event.productFilter,
      overrideFilters: true,
    ));
    await _paginationController.loadInitial(currentState: state);
  }

  Future<void> _onLoadProductsInitial(
    LoadProductsInitial event,
    Emitter<ProductsState> emit,
  ) async {
    _searchQuery = event.search;
    await _paginationController.loadInitial(currentState: state);
  }

  Future<void> _onSearchProducts(
    SearchProducts event,
    Emitter<ProductsState> emit,
  ) async {
    _searchQuery = event.query;
    await _paginationController.loadInitial(currentState: state);
  }

  Future<void> _onLoadMoreProducts(
    LoadMoreProducts event,
    Emitter<ProductsState> emit,
  ) async {
    await _paginationController.loadNextPage(state);
  }

  Future<void> _onRefreshProducts(
    RefreshProducts event,
    Emitter<ProductsState> emit,
  ) async {
    await _paginationController.refresh(state);
  }

  Future<void> _onDeleteProduct(
    DeleteProduct event,
    Emitter<ProductsState> emit,
  ) async {
    try {
      await _repo.deleteProduct(event.productId);
      emit(state.copyWith(
        operationSuccess: true,
        operationMessage: "Product deleted successfully",
        lastOperationType: "delete",
        error: null,
      ));
      // add(RefreshProducts());
    } catch (e) {
      // We could emit a failure state, but for simplicity we'll just log
      emit(state.copyWith(
        operationSuccess: false,
        operationMessage: "Failed to delete product",
        error: e.toString(),
      ));
      debugPrint("Delete error: $e");
    }
  }

  Future<void> _onUpdateProductStatus(
    UpdateProductStatus event,
    Emitter<ProductsState> emit,
  ) async {
    try {
      await _repo.updateProductStatus(event.productId, event.status);
      emit(state.copyWith(
        operationSuccess: true,
        operationMessage: "Product status updated to ${event.status}",
        lastOperationType: "update_status",
        error: null,
      ));
      add(RefreshProducts());
    } catch (e) {
      emit(state.copyWith(
        operationSuccess: false,
        operationMessage: "Failed to update product status",
        error: e.toString(),
      ));
      debugPrint("Update status error: $e");
    }
  }


  @override
  void onChange(Change<ProductsState> change) {
    super.onChange(change);
  }
}
