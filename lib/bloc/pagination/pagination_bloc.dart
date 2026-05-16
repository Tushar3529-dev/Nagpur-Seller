@Deprecated('Use PaginatedState and PaginationController instead. This old system lacks SWR and defensive guards.')
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class PaginationEvent {}

class LoadInitialData extends PaginationEvent {}

class LoadMoreData extends PaginationEvent {}

class RefreshData extends PaginationEvent {}

abstract class PaginationState<T> {
  final List<T> items;
  final bool isLoading;
  final bool isFetchingMore;
  final bool hasReachedMax;
  final int currentPage;
  final String? error;

  PaginationState({
    required this.items,
    this.isLoading = false,
    this.isFetchingMore = false,
    this.hasReachedMax = false,
    this.currentPage = 1,
    this.error,
  });

  PaginationState<T> copyWith({
    List<T>? items,
    bool? isLoading,
    bool? isFetchingMore,
    bool? hasReachedMax,
    int? currentPage,
    String? error,
  });
}

abstract class PaginationBloc<T, S extends PaginationState<T>> extends Bloc<PaginationEvent, S> {
  PaginationBloc(super.initialState) {
    on<LoadInitialData>(_onLoadInitialData);
    on<LoadMoreData>(_onLoadMoreData);
    on<RefreshData>(_onRefreshData);
  }

  Future<void> _onLoadInitialData(LoadInitialData event, Emitter<S> emit) async {
    emit(state.copyWith(isLoading: true, error: null) as S);
    try {
      final result = await fetchData(page: 1);
      emit(state.copyWith(
        items: result.items,
        isLoading: false,
        hasReachedMax: result.items.length >= result.total,
        currentPage: 1,
      ) as S);
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()) as S);
    }
  }

  Future<void> _onLoadMoreData(LoadMoreData event, Emitter<S> emit) async {
    if (state.hasReachedMax || state.isFetchingMore) return;

    emit(state.copyWith(isFetchingMore: true) as S);
    try {
      final nextPage = state.currentPage + 1;
      final result = await fetchData(page: nextPage);
      
      final newItems = List<T>.from(state.items)..addAll(result.items);
      
      emit(state.copyWith(
        items: newItems,
        isFetchingMore: false,
        hasReachedMax: newItems.length >= result.total,
        currentPage: nextPage,
      ) as S);
    } catch (e) {
      emit(state.copyWith(isFetchingMore: false, error: e.toString()) as S);
    }
  }

  Future<void> _onRefreshData(RefreshData event, Emitter<S> emit) async {
    add(LoadInitialData());
  }

  Future<PaginationResult<T>> fetchData({required int page});
}

class PaginationResult<T> {
  final List<T> items;
  final int total;

  PaginationResult({required this.items, required this.total});
}
