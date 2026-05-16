import 'package:hyper_local_seller/bloc/pagination/paginated_state.dart';
import 'package:hyper_local_seller/bloc/pagination/pagination_guard.dart';
import 'package:hyper_local_seller/bloc/pagination/pagination_response.dart';
import 'package:hyper_local_seller/service/connectivity_service.dart';

typedef StateEmitter<T> = void Function(PaginatedState<T> state);

class PaginationController<T> {
  final Future<PaginationResponse<T>> Function(int page, int perPage) fetcher;
  final StateEmitter<T> emit;
  final int perPage;

  PaginationController({
    required this.fetcher,
    required this.emit,
    this.perPage = 10,
  });

  /// Initial load or full refresh (clears data if stale-while-revalidate is disabled)
  void reset() {
    emit(PaginatedState<T>());
  }

  Future<void> loadInitial({bool silent = false, PaginatedState<T>? currentState}) async {
    final baseState = currentState ?? PaginatedState<T>(); // Temporary initial state
    
    if (!silent) {
      emit(baseState.copyWith(isInitialLoading: true, items: [], clearOperation: true));
    }

    await _fetchData(
      page: 1,
      onStart: (state) => emit(state.copyWith(
        isInitialLoading: !silent && state.items.isEmpty,
        isRefreshing: silent,
      )),
      currentState: baseState,
    );
  }

  /// Refresh existing data in background (Stale-While-Revalidate)
  Future<void> refresh(PaginatedState<T> currentState) async {
    // Don't refresh if already loading
    if (currentState.isInitialLoading || currentState.isRefreshing) return;

    emit(currentState.copyWith(isRefreshing: true));

    await _fetchData(
      page: 1,
      onStart: (state) => emit(state.copyWith(isRefreshing: true)),
      isRefresh: true,
      currentState: currentState,
    );
  }

  /// Load next page
  Future<void> loadNextPage(PaginatedState<T> currentState) async {
    if (!currentState.hasMore || 
        currentState.isInitialLoading || 
        currentState.isRefreshing || 
        currentState.isPaginating) {
      return;
    }

    // Network check before paginating
    if (!await ConnectivityService.isConnected()) {
      return;
    }

    emit(currentState.copyWith(isPaginating: true));

    await _fetchData(
      page: currentState.currentPage + 1,
      onStart: (state) => emit(state.copyWith(isPaginating: true)),
      isNextPage: true,
      currentState: currentState,
    );
  }

  Future<void> _fetchData({
    required int page,
    required void Function(PaginatedState<T> state) onStart,
    bool isRefresh = false,
    bool isNextPage = false,
    PaginatedState<T>? currentState,
  }) async {
    final state = currentState ?? PaginatedState<T>();
    
    try {
      final response = await fetcher(page, perPage);
      
      final newItems = isNextPage 
          ? [...state.items, ...response.items] 
          : response.items;

      final shouldStop = PaginationGuard.shouldStopPagination(
        itemsReceived: response.items,
        currentItems: isNextPage ? state.items : [],
        total: response.total,
        hasMoreBackend: response.hasMore,
        perPage: perPage,
      );

      emit(state.copyWith(
        items: newItems,
        isInitialLoading: false,
        isRefreshing: false,
        isPaginating: false,
        hasMore: !shouldStop,
        currentPage: page,
        total: response.total ?? state.total,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isInitialLoading: false,
        isRefreshing: false,
        isPaginating: false,
        error: e.toString(),
      ));
    }
  }
}
