import 'package:hyper_local_seller/service/json_parser.dart';

class WithdrawalHistoryModel {
  final bool success;
  final String message;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final List<WithdrawalData> data;

  WithdrawalHistoryModel({
    required this.success,
    required this.message,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    required this.data,
  });

  factory WithdrawalHistoryModel.fromJson(Map<String, dynamic> json) {
    final dataMap = json['data'] as Map<String, dynamic>?;
    return WithdrawalHistoryModel(
      success: JsonParser.boolValue(json['success'] ?? false),
      message: JsonParser.string(json['message'] ?? ''),
      currentPage: JsonParser.intValue(dataMap?['current_page'] ?? 1),
      lastPage: JsonParser.intValue(dataMap?['last_page'] ?? 1),
      perPage: JsonParser.intValue(dataMap?['per_page'] ?? 15),
      total: JsonParser.intValue(dataMap?['total'] ?? 0),
      data: (dataMap?['data'] as List? ?? [])
          .map((e) => WithdrawalData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': {
        'current_page': currentPage,
        'last_page': lastPage,
        'per_page': perPage,
        'total': total,
        'data': data.map((e) => e.toJson()).toList(),
      },
    };
  }
}

class WithdrawalData {
  final int id;
  final String amount;
  final String status;
  final String? message;
  final String createdAt;
  final String? transactionId;

  WithdrawalData({
    required this.id,
    required this.amount,
    required this.status,
    this.message,
    required this.createdAt,
    this.transactionId,
  });

  factory WithdrawalData.fromJson(Map<String, dynamic> json) {
    return WithdrawalData(
      id: JsonParser.intValue(json['id']),
      amount: JsonParser.string(json['amount']),
      status: JsonParser.string(json['status']),
      message: JsonParser.string(json['message']),
      createdAt: JsonParser.string(json['created_at']),
      transactionId: JsonParser.string(json['transaction_id']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'status': status,
      'message': message,
      'created_at': createdAt,
      'transaction_id': transactionId,
    };
  }
}
