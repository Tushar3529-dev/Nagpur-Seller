import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/model/current_plan_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/repo/subscription_plans_repo.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/service/subscription_limit_service.dart';
import 'buy_subscription_event.dart';
import 'buy_subscription_state.dart';

class BuySubscriptionBloc
    extends Bloc<BuySubscriptionEvent, BuySubscriptionState> {
  final SubscriptionPlansRepo _repo;

  final SubscriptionLimitService _limitService = SubscriptionLimitService();
  bool _isPolling = false;

  BuySubscriptionBloc(this._repo) : super(BuySubscriptionInitial()) {
    on<PurchasePlan>(_onPurchasePlan);
    on<CheckPaymentStatus>(_onCheckPaymentStatus);
    on<StopPaymentPolling>(_onStopPaymentPolling);
    on<StartPaymentPolling>(_onStartPaymentPolling);
    on<BuySubscriptionReset>(_onReset);
  }

  void _onStartPaymentPolling(
    StartPaymentPolling event,
    Emitter<BuySubscriptionState> emit,
  ) {
    _isPolling = true;
    add(const CheckPaymentStatus());
  }

  void _onStopPaymentPolling(
    StopPaymentPolling event,
    Emitter<BuySubscriptionState> emit,
  ) {
    _isPolling = false;
  }

  Future<void> _onPurchasePlan(
    PurchasePlan event,
    Emitter<BuySubscriptionState> emit,
  ) async {
    _isPolling = false; // reset
    emit(BuySubscriptionLoading());
    try {
      final response = await _repo.buySubscriptionPlan(
        event.planId,
        event.paymentType,
        event.gatewayTransactionId,
      );

      if (response['success'] == true) {
        final data = response['data'];
        final status = data['status'];

        if (status == 'pending' && data['payment_url'] != null) {
          // Save pending to Hive
          await HiveStorage.setPendingSubscription(
            subscriptionId: data['subscription_id'],
            planId: event.planId,
            paymentUrl: data['payment_url'],
          );

          emit(
            BuySubscriptionPending(
              message: response['message'] ?? 'Payment pending',
              subscriptionId: data['subscription_id'],
              paymentUrl: data['payment_url'],
              planId: event.planId,
            ),
          );

          // Start Polling
          _isPolling = true;
          add(const CheckPaymentStatus());
        } else {
          emit(
            BuySubscriptionSuccess(
              message:
                  response['message'] ?? 'Subscription purchased successfully',
              data: data,
            ),
          );
        }
      } else {
        emit(
          BuySubscriptionFailure(
            message: response['message'] ?? 'Failed to purchase subscription',
          ),
        );
      }
    } catch (e) {
      emit(BuySubscriptionFailure(message: e.toString()));
    }
  }

  Future<void> _onCheckPaymentStatus(
    CheckPaymentStatus event,
    Emitter<BuySubscriptionState> emit,
  ) async {
    if (!_isPolling) return; // Stop if requested

    try {
      final response = await _repo.getCurrentSubscriptionPlan();
      final currentPlan = CurrentPlanResponse.fromJson(response);

      if (currentPlan.success == true && currentPlan.data == null) {
        await HiveStorage.clearPendingSubscription();
        await HiveStorage.clearSubscriptionLimits();
      } else if (currentPlan.success == true && currentPlan.data != null) {
        final data = currentPlan.data!;
        if (data.status == 'active') {
          // Clear pending and notify success
          await HiveStorage.clearPendingSubscription();
          await _limitService.syncSubscription();

          emit(
            BuySubscriptionSuccess(
              message: 'Subscription payment successful!',
              data: response['data'],
            ),
          );
        } else if (data.status == 'pending') {
          // Wait and poll again
          await Future.delayed(const Duration(seconds: 5));
          if (!isClosed) {
            add(const CheckPaymentStatus());
          }
        } else {
          // Cancelled, Expired etc
          _isPolling = false;
          await HiveStorage.clearPendingSubscription();
          emit(
            BuySubscriptionFailure(
              message: 'Subscription status: ${data.status}',
            ),
          );
        }
      } else {
        // Error or no plan found (might be cleared on server)
        // If it was pending but now not even found, something changed
        await Future.delayed(const Duration(seconds: 5));
        if (!isClosed && _isPolling) {
          add(const CheckPaymentStatus());
        }
      }
    } catch (e) {
      // transient error, retry
      await Future.delayed(const Duration(seconds: 10));
      if (!isClosed && _isPolling) {
        add(const CheckPaymentStatus());
      }
    }
  }

  void _onReset(
      BuySubscriptionReset event,
      Emitter<BuySubscriptionState> emit,
      ) {
    _isPolling = false;
    emit(BuySubscriptionInitial());
  }
}
