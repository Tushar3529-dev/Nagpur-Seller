import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/bloc/pagination/paginated_state.dart';
import 'package:hyper_local_seller/screen/products_page/products/model/product_model.dart';
import 'package:hyper_local_seller/screen/products_page/products/model/product_filter_model.dart';
import 'package:hyper_local_seller/screen/products_page/products/repo/products_repo.dart';
part 'products_event.dart';
part 'products_state.dart';

class ProductsBloc extends Bloc<ProductsEvent, ProductsState> {
  final ProductsRepo _repo;

  /// The API cannot sort by stock or price, so the list is sorted on the client.
  /// For the order to be correct end to end the whole result set is fetched
  /// first, otherwise the order would restart at every page break.
  static const int _fetchPageSize = 100;

  /// Safety net for very large catalogues.
  static const int _maxSortedProducts = 2000;

  String? _searchQuery;

  /// Bumped by every (re)load so a late response from an older load is dropped.
  int _generation = 0;

  ProductsBloc(this._repo) : super(const ProductsState(isInitialLoading: true)) {
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

  /// Fetches every page of the current filter set, sorts it and emits
  /// it in one go, so the list is ordered as a whole and never re-orders itself
  /// while the seller scrolls.
  Future<void> _loadAllSorted(
    Emitter<ProductsState> emit, {
    bool silent = false,
  }) async {
    final generation = ++_generation;

    emit(state.copyWith(
      items: silent ? null : const [],
      isInitialLoading: !silent,
      isRefreshing: silent,
      isPaginating: false,
      clearOperation: true,
    ));

    try {
      final products = <Product>[];
      int page = 1;
      int? total;

      while (true) {
        final response = await _repo.getProducts(
          page: page,
          perPage: _fetchPageSize,
          search: _searchQuery,
          type: state.selectedType,
          status: state.selectedStatus,
          verificationStatus: state.selectedVerificationStatus,
          productFilter: state.selectedProductFilter,
        );
        if (generation != _generation) return;

        final data = ProductsResponse.fromJson(response).data;
        final pageProducts = data?.products ?? [];
        total = data?.total ?? total;
        products.addAll(pageProducts);

        final lastPage = data?.lastPage ?? page;
        if (pageProducts.isEmpty ||
            page >= lastPage ||
            products.length >= _maxSortedProducts) {
          break;
        }
        page++;
      }

      emit(state.copyWith(
        items: ProductsState.sortProducts(products, state.sortBy),
        isInitialLoading: false,
        isRefreshing: false,
        isPaginating: false,
        hasMore: false,
        currentPage: page,
        total: total ?? products.length,
        error: null,
      ));
    } catch (e) {
      if (generation != _generation) return;
      emit(state.copyWith(
        isInitialLoading: false,
        isRefreshing: false,
        isPaginating: false,
        error: e.toString(),
      ));
    }
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
    // Sorting happens on the client, so changing only the sort re-orders
    // the loaded items instead of refetching.
    final onlySortChanged =
        event.type == state.selectedType &&
        event.status == state.selectedStatus &&
        event.verificationStatus == state.selectedVerificationStatus &&
        event.productFilter == state.selectedProductFilter;

    emit(state.copyWith(
      items: onlySortChanged
          ? ProductsState.sortProducts(state.items, event.sortBy)
          : null,
      selectedType: event.type,
      selectedStatus: event.status,
      selectedVerificationStatus: event.verificationStatus,
      selectedProductFilter: event.productFilter,
      sortBy: event.sortBy,
      overrideFilters: true,
    ));

    if (onlySortChanged) return;
    await _loadAllSorted(emit);
  }

  Future<void> _onLoadProductsInitial(
    LoadProductsInitial event,
    Emitter<ProductsState> emit,
  ) async {
    _searchQuery = event.search;
    await _loadAllSorted(emit);
  }

  Future<void> _onSearchProducts(
    SearchProducts event,
    Emitter<ProductsState> emit,
  ) async {
    _searchQuery = event.query;
    await _loadAllSorted(emit);
  }

  Future<void> _onLoadMoreProducts(
    LoadMoreProducts event,
    Emitter<ProductsState> emit,
  ) async {
    // Nothing to do: the sorted list is loaded in full.
  }

  Future<void> _onRefreshProducts(
    RefreshProducts event,
    Emitter<ProductsState> emit,
  ) async {
    if (state.isInitialLoading || state.isRefreshing) return;
    await _loadAllSorted(emit, silent: true);
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
