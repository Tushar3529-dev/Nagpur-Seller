part of 'wallet_bloc.dart';

abstract class WalletEvent extends Equatable {
  const WalletEvent();

  @override
  List<Object?> get props => [];
}

class FetchWallet extends WalletEvent {}

class LoadWithdrawalHistoryInitial extends WalletEvent {}

class FetchTransactions extends WalletEvent {}

class SubmitWithdrawRequest extends WalletEvent {
  final String amount;

  const SubmitWithdrawRequest({required this.amount});

  @override
  List<Object?> get props => [amount];
}

class ClearWithdrawState extends WalletEvent {}

class ResetWallet extends WalletEvent {}
