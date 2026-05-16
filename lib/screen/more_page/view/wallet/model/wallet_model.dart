import 'package:hyper_local_seller/service/json_parser.dart';

const String walletModelName = 'wallet_model';

class WalletModel {
  bool? success;
  String? message;
  WalletData? data;

  WalletModel({this.success, this.message, this.data});

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      success: JsonParser.boolValue(json['success'] ?? false),
      message: JsonParser.string(json['message'] ?? ''),
      data: json['data'] != null
          ? WalletData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class WalletData {
  int? id;
  int? userId;
  String? balance;
  String? blockedBalance;
  String? currencyCode;
  String? createdAt;
  String? updatedAt;

  WalletData({
    this.id,
    this.userId,
    this.balance,
    this.blockedBalance,
    this.currencyCode,
    this.createdAt,
    this.updatedAt,
  });

  factory WalletData.fromJson(Map<String, dynamic> json) {
    return WalletData(
      id: JsonParser.intValue(json['id']),
      userId: JsonParser.intValue(json['user_id']),
      balance: JsonParser.string(json['balance']),
      blockedBalance: JsonParser.string(json['blocked_balance']),
      currencyCode: JsonParser.string(json['currency_code']),
      createdAt: JsonParser.string(json['created_at'] ?? ''),
      updatedAt: JsonParser.string(json['updated_at'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['user_id'] = userId;
    data['balance'] = balance;
    data['blocked_balance'] = blockedBalance;
    data['currency_code'] = currencyCode;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}
