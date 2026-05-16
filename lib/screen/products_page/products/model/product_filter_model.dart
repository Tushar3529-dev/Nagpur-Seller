class ProductFilterModel {
  bool? success;
  String? message;
  ProductFilter? productFilter;

  ProductFilterModel({this.success, this.message, this.productFilter});

  ProductFilterModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    productFilter = json['data'] != null
        ? ProductFilter.fromJson(json['data'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    if (productFilter != null) {
      data['data'] = productFilter!.toJson();
    }
    return data;
  }
}

class ProductFilter {
  List<String>? type;
  List<String>? status;
  List<String>? verificationStatus;
  List<String>? productFilter;

  ProductFilter({this.type, this.status, this.verificationStatus});

  ProductFilter.fromJson(Map<String, dynamic> json) {
    type = json['type'].cast<String>();
    status = json['status'].cast<String>();
    verificationStatus = json['verification_status'].cast<String>();
    productFilter = json['product_filter'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['type'] = type;
    data['status'] = status;
    data['verification_status'] = verificationStatus;
    data['product_filter'] = productFilter;
    return data;
  }
}
