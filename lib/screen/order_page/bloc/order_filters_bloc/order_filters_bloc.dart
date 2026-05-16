import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hyper_local_seller/screen/order_page/repo/order_repo.dart';
import 'package:hyper_local_seller/screen/order_page/model/order_filters_model.dart';

part 'order_filters_event.dart';
part 'order_filters_state.dart';

class OrderFiltersBloc extends Bloc<OrderFiltersEvent, OrderFiltersState> {
  final OrdersRepo _repo;

  OrderFiltersBloc(this._repo) : super(OrderFiltersInitial()) {
    on<FetchOrderFilters>(_onFetchOrderFilters);
    on<SelectStatusFilter>(_onSelectStatusFilter);
    on<SelectRangeFilter>(_onSelectRangeFilter);
    on<SelectPaymentTypeFilter>(_onSelectPaymentTypeFilter);
    on<ClearOrderFilters>(_onClearOrderFilters);
    on<ResetOrderFilters>((event, emit) => emit(OrderFiltersInitial()));
  }

  Future<void> _onFetchOrderFilters(
    FetchOrderFilters event,
    Emitter<OrderFiltersState> emit,
  ) async {
    emit(OrderFiltersLoading());
    try {
      final response = await _repo.getOrderFilters();
      
      if (response != null && response['success'] == true) {
        final filtersResponse = OrderEnumsResponse.fromJson(response);
        
        if (filtersResponse.enums != null) {
          emit(OrderFiltersLoaded(
            filters: filtersResponse.enums!,
          ));
        } else {
          emit(const OrderFiltersError('No filter data available'));
        }
      } else {
        emit(OrderFiltersError(response?['message'] ?? 'Failed to load filters'));
      }
    } catch (e) {
      emit(OrderFiltersError(e.toString()));
    }
  }

  void _onSelectStatusFilter(
    SelectStatusFilter event,
    Emitter<OrderFiltersState> emit,
  ) {
    if (state is OrderFiltersLoaded) {
      final currentState = state as OrderFiltersLoaded;
      emit(currentState.copyWith(selectedStatus: event.status));
    }
  }

  void _onSelectRangeFilter(
    SelectRangeFilter event,
    Emitter<OrderFiltersState> emit,
  ) {
    if (state is OrderFiltersLoaded) {
      final currentState = state as OrderFiltersLoaded;
      emit(currentState.copyWith(selectedRange: event.range));
    }
  }

  void _onSelectPaymentTypeFilter(
    SelectPaymentTypeFilter event,
    Emitter<OrderFiltersState> emit,
  ) {
    if (state is OrderFiltersLoaded) {
      final currentState = state as OrderFiltersLoaded;
      emit(currentState.copyWith(selectedPaymentType: event.paymentType));
    }
  }

  void _onClearOrderFilters(
    ClearOrderFilters event,
    Emitter<OrderFiltersState> emit,
  ) {
    if (state is OrderFiltersLoaded) {
      final currentState = state as OrderFiltersLoaded;
      emit(currentState.copyWith(
        selectedStatus: null,
        selectedRange: null,
        selectedPaymentType: null,
      ));
    }
  }
}
