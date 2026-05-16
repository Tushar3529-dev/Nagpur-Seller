import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/global_keys.dart';
import 'package:hyper_local_seller/bloc/pagination/paginated_state.dart';
import 'package:hyper_local_seller/bloc/pagination/pagination_controller.dart';
import 'package:hyper_local_seller/bloc/pagination/pagination_response.dart';
import 'package:hyper_local_seller/screen/order_page/model/order_model.dart';
import 'package:hyper_local_seller/screen/order_page/repo/order_repo.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';

part 'orders_event.dart';
part 'orders_state.dart';

class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  final OrdersRepo _repo;
  late final PaginationController<SellerOrderItem> _paginationController;

  String? _searchQuery;

  OrdersBloc(this._repo) : super(const OrdersState()) {
    _paginationController = PaginationController<SellerOrderItem>(
      fetcher: _fetchOrders,
      emit: (paginatedState) => emit(state.copyWith(
        items: paginatedState.items,
        hasMore: paginatedState.hasMore,
        isInitialLoading: paginatedState.isInitialLoading,
        isRefreshing: paginatedState.isRefreshing,
        isPaginating: paginatedState.isPaginating,
        error: paginatedState.error,
        currentPage: paginatedState.currentPage,
        total: paginatedState.total,
      )),
      perPage: GlobalKeys.perPage,
    );

    on<LoadOrdersInitial>(_onLoadOrdersInitial);
    on<LoadMoreOrders>(_onLoadMoreOrders);
    on<RefreshOrders>(_onRefreshOrders);
    on<SearchOrders>(_onSearchOrders);
    on<ApplyFilter>(_onApplyFilter);
    on<ClearFilters>(_onClearFilters);
    on<OrdersReset>(_onOrdersReset);
    on<UpdateOrderListItemStatus>(_onUpdateOrderListItemStatus);
  }

  Future<PaginationResponse<SellerOrderItem>> _fetchOrders(int page, int perPage) async {
    final response = await _repo.getOrders(
      page: page,
      perPage: perPage,
      search: _searchQuery,
      paymentType: state.paymentType,
      range: state.range,
      sortBy: state.sortBy,
      sortDir: state.sortDir,
      status: state.status,
      storeId: state.storeId,
    );
    final ordersResponse = OrdersResponse.fromJson(response);

    return PaginationResponse(
      items: ordersResponse.data?.items ?? [],
      total: ordersResponse.data?.total,
      currentPage: page,
    );
  }

  Future<void> _onLoadOrdersInitial(
      LoadOrdersInitial event,
      Emitter<OrdersState> emit,
      ) async {
    _searchQuery = event.search;
    final storeId = event.storeId ?? HiveStorage.selectedStoreId;
    emit(state.copyWith(storeId: storeId, overrideFilters: true));
    await _paginationController.loadInitial(currentState: state);
  }

  Future<void> _onSearchOrders(
      SearchOrders event,
      Emitter<OrdersState> emit,
      ) async {
    _searchQuery = event.query;
    await _paginationController.loadInitial();
  }

  Future<void> _onApplyFilter(
      ApplyFilter event,
      Emitter<OrdersState> emit,
      ) async {
    // Update state with new filter values, keeping existing ones if not provided (OR reset? Usually apply filter updates specific ones)
    // The event fields are nullable. If they are passed, update.
    // However, if we want to "set" filters, we might want to update only provided ones.
    
    emit(state.copyWith(
      paymentType: event.paymentType,
      range: event.range,
      sortBy: event.sortBy,
      sortDir: event.sortDir,
      status: event.status,
      overrideFilters: true,
    ));

    await _paginationController.loadInitial();
  }

  Future<void> _onClearFilters(
      ClearFilters event,
      Emitter<OrdersState> emit,
      ) async {
    // Only clear filters, keep search query and storeId
    emit(state.copyWith(
      paymentType: null,
      range: null,
      sortBy: null,
      sortDir: null,
      status: null,
      overrideFilters: true,
    ));
    await _paginationController.loadInitial();
  }

  Future<void> _onOrdersReset(
      OrdersReset event,
      Emitter<OrdersState> emit,
      ) async {
    _searchQuery = null;
    emit(const OrdersState());
    _paginationController.reset();
  }
  
  Future<void> _onUpdateOrderListItemStatus(
      UpdateOrderListItemStatus event,
      Emitter<OrdersState> emit,
      ) async {
    try {
      await _repo.updateOrderStatus(event.orderId, event.status);
      // Refresh list to show updated status
      // Or manually update the item in the list to avoid full reload
      // But status change might move it to another tab if we had tabs (we don't seems to have tabs, just filters)
      // Refreshing is safest.
      add(RefreshOrders());
    } catch (e) {
      // Handle error, maybe emit generic error state or just log
      // ideally show snackbar via listener in UI
    }
  }

  Future<void> _onLoadMoreOrders(
      LoadMoreOrders event,
      Emitter<OrdersState> emit,
      ) async {
    await _paginationController.loadNextPage(state);
  }

  Future<void> _onRefreshOrders(
      RefreshOrders event,
      Emitter<OrdersState> emit,
      ) async {
    final storeId = event.storeId ?? state.storeId ?? HiveStorage.selectedStoreId;
    emit(state.copyWith(storeId: storeId, overrideFilters: true));
    await _paginationController.refresh(state);
  }
}
