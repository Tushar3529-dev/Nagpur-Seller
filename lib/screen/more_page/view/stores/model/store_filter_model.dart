class StoreFilterModel {
  bool? success;
  String? message;
  StoreFilter? storeFilter;

  StoreFilterModel({this.success, this.message, this.storeFilter});

  StoreFilterModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    storeFilter = json['data'] != null
        ? StoreFilter.fromJson(json['data'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    if (storeFilter != null) {
      data['data'] = storeFilter!.toJson();
    }
    return data;
  }
}

class StoreFilter {
  List<String>? status;
  List<String>? visibilityStatus;
  List<String>? verificationStatus;

  StoreFilter({this.status, this.visibilityStatus, this.verificationStatus});

  StoreFilter.fromJson(Map<String, dynamic> json) {
    status = json['status'].cast<String>();
    visibilityStatus = json['visibility_status'].cast<String>();
    verificationStatus = json['verification_status'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['visibility_status'] = visibilityStatus;
    data['verification_status'] = verificationStatus;
    return data;
  }
}
