import 'package:hyper_local_seller/config/api_routes.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';

import '../model/transactions_model.dart';
import '../model/wallet_model.dart';
import '../model/withdrawals_model.dart';

class WalletRepository {
  Future<WalletModel?> fetchWallet() async {
    try {
      final response = await ApiBaseHelper().get(ApiRoutes.walletApi);
      if (response['success'] == true) {
        return WalletModel.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<WithdrawalHistoryModel?> fetchWithdrawalHistory({
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final response = await ApiBaseHelper().get(
        ApiRoutes.withdrawalsApi,
        queryParameters: {'page': page, 'per_page': perPage},
      );
      if (response['success'] == true) {
        return WithdrawalHistoryModel.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<TransactionHistoryModel?> fetchTransactions({
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final response = await ApiBaseHelper().get(
        ApiRoutes.transactionsApi,
        queryParameters: {'page': page, 'per_page': perPage},
      );
      if (response['success'] == true || response.containsKey('data')) {
        return TransactionHistoryModel.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> submitWithdrawRequest(String amount) async {
    try {
      final response = await ApiBaseHelper().post(ApiRoutes.withdrawalsApi, {
        'amount': amount,
      });
      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
