class OrderEnumsResponse {
  bool? success;
  String? message;
  OrderEnum? enums;

  OrderEnumsResponse({this.success, this.message, this.enums});

  OrderEnumsResponse.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    enums = json['data'] != null ? OrderEnum.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    if (enums != null) {
      data['data'] = enums!.toJson();
    }
    return data;
  }
}

class OrderEnum {
  List<String>? status;
  List<String>? range;
  List<String>? paymentType;

  OrderEnum({this.status, this.range, this.paymentType});

  OrderEnum.fromJson(Map<String, dynamic> json) {
    status = json['status'].cast<String>();
    range = json['range'].cast<String>();
    paymentType = json['payment_type'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['range'] = range;
    data['payment_type'] = paymentType;
    return data;
  }
}
