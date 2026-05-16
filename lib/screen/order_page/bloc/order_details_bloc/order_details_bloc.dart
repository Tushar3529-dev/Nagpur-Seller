import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hyper_local_seller/screen/order_page/model/order_details_model.dart';
import 'package:hyper_local_seller/screen/order_page/repo/order_repo.dart';

part 'order_details_event.dart';
part 'order_details_state.dart';

class OrderDetailsBloc extends Bloc<OrderDetailsEvent, OrderDetailsState> {
  final OrdersRepo _repo;

  OrderDetailsBloc(this._repo) : super(OrderDetailsInitial()) {
    on<FetchOrderDetails>(_onFetchOrderDetails);
    on<UpdateOrderStatusEvent>(_onUpdateOrderStatus);
  }

  Future<void> _onFetchOrderDetails(
    FetchOrderDetails event,
    Emitter<OrderDetailsState> emit,
  ) async {
    emit(OrderDetailsLoading());
    try {
      final response = await _repo.getOrderDetails(event.orderId);
      final detailsResponse = OrderDetailsResponse.fromJson(response);
      
      if (detailsResponse.data != null) {
        emit(OrderDetailsLoaded(orderData: detailsResponse.data!));
      } else {
        emit(OrderDetailsError(detailsResponse.message ?? 'Failed to load details'));
      }
    } catch (e) {
      emit(OrderDetailsError(e.toString()));
    }
  }

  Future<void> _onUpdateOrderStatus(
    UpdateOrderStatusEvent event,
    Emitter<OrderDetailsState> emit,
  ) async {
    final currentState = state;
    if (currentState is OrderDetailsLoaded) {
      emit(currentState.copyWith(isUpdating: true));
      try {
        // final response = await _repo.updateOrderStatus(event.orderId, event.status);
        // reload details
        // Or emit success then reload? 
        // Emitting success might break the UI flow if it expects Loaded state always.
        // I will just reload details for simplicity and consistency.
        
        final detailsResponseRaw = await _repo.getOrderDetails(event.orderId);
        final detailsResponse = OrderDetailsResponse.fromJson(detailsResponseRaw);

         if (detailsResponse.data != null) {
          emit(OrderDetailsLoaded(orderData: detailsResponse.data!));
        } else {
             emit(currentState.copyWith(isUpdating: false));
             // Maybe show error as snackbar? In bloc we usually emit state.
             // But if we emit Error it replaces the view.
             // For now, reload.
        }
        
      } catch (e) {
        emit(currentState.copyWith(isUpdating: false));
        // You might want to handle error reporting differently (e.g., separate error stream or state property)
      }
    }
  }
}
