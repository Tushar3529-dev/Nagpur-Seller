import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/bloc/pagination/paginated_state.dart';
import 'package:hyper_local_seller/screen/more_page/view/delivery_zone/model/delivery_zone_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/delivery_zone/repo/delivery_zone_repo.dart';

part 'delivery_zone_event.dart';
part 'delivery_zone_state.dart';

class DeliveryZoneBloc extends Bloc<DeliveryZoneEvent, DeliveryZoneState> {
  final DeliveryZoneRepo _repo;
  String? _currentSearch;

  DeliveryZoneBloc(this._repo) : super(const DeliveryZoneState()) {
    on<LoadDeliveryZonesInitial>(_onLoadInitial);
    on<LoadMoreDeliveryZones>(_onLoadMore);
    on<RefreshDeliveryZones>(_onRefresh);
    on<SearchDeliveryZones>(_onSearch);
    on<DeliveryZoneReset>(_onReset);
  }

  Future<void> _onLoadInitial(
    LoadDeliveryZonesInitial event,
    Emitter<DeliveryZoneState> emit,
  ) async {
    _currentSearch = event.search;
    emit(
      state.copyWith(
        isInitialLoading: true,
        items: [],
        currentPage: 1,
        hasMore: true,
        error: null,
      ),
    );

    try {
      final response = await _repo.getDeliveryZone(
        page: 1,
        search: _currentSearch,
      );

      final result = DeliveryZoneResponse.fromJson(response);

      if (result.success == true && result.data != null) {
        final zones = result.data!.zones ?? [];
        emit(
          state.copyWith(
            isInitialLoading: false,
            items: zones,
            currentPage: 1,
            hasMore:
                (result.data!.currentPage ?? 1) < (result.data!.lastPage ?? 1),
            total: result.data!.total,
          ),
        );
      } else {
        emit(
          state.copyWith(
            isInitialLoading: false,
            error: result.message ?? 'Failed to load delivery zones',
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(isInitialLoading: false, error: e.toString()));
    }
  }

  Future<void> _onLoadMore(
    LoadMoreDeliveryZones event,
    Emitter<DeliveryZoneState> emit,
  ) async {
    if (state.isPaginating || !state.hasMore) return;

    emit(state.copyWith(isPaginating: true));

    try {
      final nextPage = state.currentPage + 1;
      final response = await _repo.getDeliveryZone(
        page: nextPage,
        search: _currentSearch,
      );

      final result = DeliveryZoneResponse.fromJson(response);

      if (result.success == true && result.data != null) {
        final zones = result.data!.zones ?? [];
        emit(
          state.copyWith(
            isPaginating: false,
            items: [...state.items, ...zones],
            currentPage: nextPage,
            hasMore:
                (result.data!.currentPage ?? 1) < (result.data!.lastPage ?? 1),
            total: result.data!.total,
          ),
        );
      } else {
        emit(
          state.copyWith(
            isPaginating: false,
            error: result.message ?? 'Failed to load more delivery zones',
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(isPaginating: false, error: e.toString()));
    }
  }

  Future<void> _onRefresh(
    RefreshDeliveryZones event,
    Emitter<DeliveryZoneState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true, error: null));

    try {
      final response = await _repo.getDeliveryZone(
        page: 1,
        search: _currentSearch,
      );

      final result = DeliveryZoneResponse.fromJson(response);

      if (result.success == true && result.data != null) {
        final zones = result.data!.zones ?? [];
        emit(
          state.copyWith(
            isRefreshing: false,
            items: zones,
            currentPage: 1,
            hasMore:
                (result.data!.currentPage ?? 1) < (result.data!.lastPage ?? 1),
            total: result.data!.total,
          ),
        );
      } else {
        emit(
          state.copyWith(
            isRefreshing: false,
            error: result.message ?? 'Failed to refresh delivery zones',
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(isRefreshing: false, error: e.toString()));
    }
  }

  Future<void> _onSearch(
    SearchDeliveryZones event,
    Emitter<DeliveryZoneState> emit,
  ) async {
    _currentSearch = event.query.isEmpty ? null : event.query;
    add(LoadDeliveryZonesInitial(search: _currentSearch));
  }

  Future<void> _onReset(
      DeliveryZoneReset event,
      Emitter<DeliveryZoneState> emit,
      ) async {
    _currentSearch = null;
    emit(const DeliveryZoneState());
  }
}
