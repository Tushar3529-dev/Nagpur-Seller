import 'package:hyper_local_seller/service/json_parser.dart';

class TransactionHistoryModel {
  final bool success;
  final String message;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final List<TransactionData> data;

  TransactionHistoryModel({
    required this.success,
    required this.message,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    required this.data,
  });

  factory TransactionHistoryModel.fromJson(Map<String, dynamic> json) {
    // ignore: avoid_print
    print('RAW TRANSACTIONS JSON: $json');
    bool success = JsonParser.boolValue(
      json['success'] ?? true,
    ); // Default to true if not present
    String message = JsonParser.string(json['message'] ?? '');

    // The data might be directly in 'data' field or nested
    dynamic jsonData = json['data'];
    List<TransactionData> items = [];

    // Default pagination values from root if available
    int currentPage = JsonParser.intValue(json['current_page'] ?? 1);
    int lastPage = JsonParser.intValue(json['last_page'] ?? 1);
    int perPage = JsonParser.intValue(json['per_page'] ?? 15);
    int total = JsonParser.intValue(json['total'] ?? 0);

    if (jsonData is Map<String, dynamic>) {
      // Check if 'data' contains the list nested inside (standard Laravel)
      if (jsonData.containsKey('data') && jsonData['data'] is List) {
        currentPage = JsonParser.intValue(
          jsonData['current_page'] ?? currentPage,
        );
        lastPage = JsonParser.intValue(jsonData['last_page'] ?? lastPage);
        perPage = JsonParser.intValue(jsonData['per_page'] ?? perPage);
        total = JsonParser.intValue(jsonData['total'] ?? total);
        items = (jsonData['data'] as List)
            .map((e) => TransactionData.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        // 'data' is a Map but doesn't have nested 'data' list?
        // Maybe 'data' is actually the record itself (if single)?
        // For history, this is less likely.
      }
    } else if (jsonData is List) {
      // 'data' is a direct list
      items = jsonData
          .map((e) => TransactionData.fromJson(e as Map<String, dynamic>))
          .toList();
      if (total == 0) total = items.length;
    }

    return TransactionHistoryModel(
      success: success,
      message: message,
      currentPage: currentPage,
      lastPage: lastPage,
      perPage: perPage,
      total: total,
      data: items,
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

class TransactionData {
  final int id;
  final String amount;
  final String type;
  final String? message;
  final String createdAt;
  final String? transactionId;
  final String? balance;

  TransactionData({
    required this.id,
    required this.amount,
    required this.type,
    this.message,
    required this.createdAt,
    this.transactionId,
    this.balance,
  });

  factory TransactionData.fromJson(Map<String, dynamic> json) {
    return TransactionData(
      id: JsonParser.intValue(json['id']),
      amount: JsonParser.string(json['amount']),
      type: JsonParser.string(json['transaction_type']),
      message: JsonParser.string(json['message']),
      createdAt: JsonParser.string(json['created_at']),
      transactionId: JsonParser.string(json['transaction_id']),
      balance: JsonParser.string(json['balance']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'transaction_type': type,
      'message': message,
      'created_at': createdAt,
      'transaction_id': transactionId,
      'balance': balance,
    };
  }
}
