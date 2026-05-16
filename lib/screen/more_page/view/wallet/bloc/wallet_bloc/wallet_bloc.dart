import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../model/transactions_model.dart';
import '../../model/wallet_model.dart';
import '../../model/withdrawals_model.dart';
import '../../repo/wallet_repo.dart';

part 'wallet_event.dart';
part 'wallet_state.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final repository = WalletRepository();

  WalletBloc() : super(const WalletState()) {
    on<FetchWallet>(_onFetchWallet);
    on<LoadWithdrawalHistoryInitial>(_onLoadWithdrawalHistoryInitial);
    on<FetchTransactions>(_onFetchTransactions);
    on<SubmitWithdrawRequest>(_onSubmitWithdrawRequest);
    on<ClearWithdrawState>(_onClearWithdrawState);
    on<ResetWallet>((event, emit) => emit(const WalletState()));
  }

  void _onClearWithdrawState(
    ClearWithdrawState event,
    Emitter<WalletState> emit,
  ) {
    emit(
      state.copyWith(
        withdrawStatus: WithdrawStatus.initial,
        withdrawMessage: null,
        error: null,
      ),
    );
  }

  Future<void> _onFetchWallet(
    FetchWallet event,
    Emitter<WalletState> emit,
  ) async {
    emit(state.copyWith(walletStatus: WalletStatus.loading));
    try {
      final response = await repository.fetchWallet();
      emit(
        state.copyWith(
          walletStatus: WalletStatus.success,
          walletData: response?.data,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(walletStatus: WalletStatus.failure, error: e.toString()),
      );
    }
  }

  Future<void> _onLoadWithdrawalHistoryInitial(
    LoadWithdrawalHistoryInitial event,
    Emitter<WalletState> emit,
  ) async {
    emit(state.copyWith(historyStatus: WalletStatus.loading));
    try {
      final response = await repository.fetchWithdrawalHistory(
        page: 1,
        perPage: 5, // Show only few items in preview
      );
      emit(
        state.copyWith(
          historyStatus: WalletStatus.success,
          withdrawalHistory: response?.data ?? [],
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          historyStatus: WalletStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> _onFetchTransactions(
    FetchTransactions event,
    Emitter<WalletState> emit,
  ) async {
    emit(state.copyWith(transactionsStatus: WalletStatus.loading));
    try {
      final response = await repository.fetchTransactions(
        page: 1,
        perPage: 5, // Show only few items in preview
      );
      emit(
        state.copyWith(
          transactionsStatus: WalletStatus.success,
          transactions: response?.data ?? [],
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          transactionsStatus: WalletStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> _onSubmitWithdrawRequest(
    SubmitWithdrawRequest event,
    Emitter<WalletState> emit,
  ) async {
    emit(state.copyWith(withdrawStatus: WithdrawStatus.submitting));
    try {
      final response = await repository.submitWithdrawRequest(event.amount);
      if (response['success'] == true) {
        emit(
          state.copyWith(
            withdrawStatus: WithdrawStatus.success,
            withdrawMessage:
                response['message'] ??
                'Withdrawal request submitted successfully',
          ),
        );
        add(FetchWallet());
        add(LoadWithdrawalHistoryInitial());
      } else {
        emit(
          state.copyWith(
            withdrawStatus: WithdrawStatus.failure,
            error: response['message'] ?? 'Failed to submit withdrawal request',
            withdrawMessage: response['message'],
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          withdrawStatus: WithdrawStatus.failure,
          error: e.toString(),
          withdrawMessage: e.toString(),
        ),
      );
    }
  }
}
