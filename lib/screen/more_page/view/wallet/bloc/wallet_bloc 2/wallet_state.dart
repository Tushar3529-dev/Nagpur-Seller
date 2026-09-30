part of 'wallet_bloc.dart';

enum WalletStatus { initial, loading, success, failure }

enum WithdrawStatus { initial, submitting, success, failure }

class WalletState extends Equatable {
  final WalletData? walletData;
  final List<WithdrawalData> withdrawalHistory;
  final List<TransactionData> transactions;
  final WalletStatus walletStatus;
  final WalletStatus historyStatus;
  final WalletStatus transactionsStatus;
  final WithdrawStatus withdrawStatus;
  final String? error;
  final String? withdrawMessage;

  const WalletState({
    this.walletData,
    this.withdrawalHistory = const [],
    this.transactions = const [],
    this.walletStatus = WalletStatus.initial,
    this.historyStatus = WalletStatus.initial,
    this.transactionsStatus = WalletStatus.initial,
    this.withdrawStatus = WithdrawStatus.initial,
    this.error,
    this.withdrawMessage,
  });

  WalletState copyWith({
    WalletData? walletData,
    List<WithdrawalData>? withdrawalHistory,
    List<TransactionData>? transactions,
    WalletStatus? walletStatus,
    WalletStatus? historyStatus,
    WalletStatus? transactionsStatus,
    WithdrawStatus? withdrawStatus,
    String? error,
    String? withdrawMessage,
  }) {
    return WalletState(
      walletData: walletData ?? this.walletData,
      withdrawalHistory: withdrawalHistory ?? this.withdrawalHistory,
      transactions: transactions ?? this.transactions,
      walletStatus: walletStatus ?? this.walletStatus,
      historyStatus: historyStatus ?? this.historyStatus,
      transactionsStatus: transactionsStatus ?? this.transactionsStatus,
      withdrawStatus: withdrawStatus ?? this.withdrawStatus,
      error: error ?? this.error,
      withdrawMessage: withdrawMessage ?? this.withdrawMessage,
    );
  }

  @override
  List<Object?> get props => [
    walletData,
    withdrawalHistory,
    transactions,
    walletStatus,
    historyStatus,
    transactionsStatus,
    withdrawStatus,
    error,
    withdrawMessage,
  ];
}
