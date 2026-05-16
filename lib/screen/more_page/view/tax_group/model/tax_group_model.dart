import 'package:hyper_local_seller/service/json_parser.dart';

const String modelName = 'tax_group_model';

class TaxGroupsResponse {
  bool? success;
  String? message;
  TaxGroupsData? data;

  TaxGroupsResponse({this.success, this.message, this.data});

  factory TaxGroupsResponse.fromJson(Map<String, dynamic> json) {
    return TaxGroupsResponse(
      success: JsonParser.boolValue(json['success'] ?? false),
      message: JsonParser.string(json['message'] ?? ''),
      data: json['data'] != null
          ? TaxGroupsData.fromJson(json['data'] as Map<String, dynamic>)
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

class TaxGroupsData {
  int? currentPage;
  int? lastPage;
  int? perPage;
  int? total;
  List<TaxGroup>? taxGroups;

  TaxGroupsData({
    this.currentPage,
    this.lastPage,
    this.perPage,
    this.total,
    this.taxGroups,
  });

  factory TaxGroupsData.fromJson(Map<String, dynamic> json) {
    return TaxGroupsData(
      currentPage: JsonParser.intValue(json['current_page'] ?? 1),
      lastPage: JsonParser.intValue(json['last_page'] ?? 1),
      perPage: JsonParser.intValue(json['per_page'] ?? 15),
      total: JsonParser.intValue(json['total'] ?? 0),

      taxGroups: JsonParser.list<TaxGroup>(
        json['data'],
            (v) => TaxGroup.fromJson(v as Map<String, dynamic>),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['current_page'] = currentPage;
    data['last_page'] = lastPage;
    data['per_page'] = perPage;
    data['total'] = total;
    if (taxGroups != null) {
      data['data'] = taxGroups!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class TaxGroup {
  int id;
  String title;
  String? deletedAt;
  String? createdAt;
  String? updatedAt;
  List<TaxRate>? taxRates;

  TaxGroup({
    required this.id,
    required this.title,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
    this.taxRates,
  });

  factory TaxGroup.fromJson(Map<String, dynamic> json) {
    return TaxGroup(
      id: JsonParser.requireInt(json['id'], model: modelName, field: 'id'),
      title: JsonParser.requireString(
        json['title'],
        model: modelName,
        field: 'title',
      ),

      deletedAt: JsonParser.string(json['deleted_at']),
      createdAt: JsonParser.string(json['created_at'] ?? ''),
      updatedAt: JsonParser.string(json['updated_at'] ?? ''),

      taxRates: JsonParser.list<TaxRate>(
        json['tax_rates'],
            (v) => TaxRate.fromJson(v as Map<String, dynamic>),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['deleted_at'] = deletedAt;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    if (taxRates != null) {
      data['tax_rates'] = taxRates!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class TaxRate {
  int id;
  String title;
  String rate;          // keeping as String because it's often formatted like "20.00"
  String? createdAt;
  String? updatedAt;
  Pivot? pivot;

  TaxRate({
    required this.id,
    required this.title,
    required this.rate,
    this.createdAt,
    this.updatedAt,
    this.pivot,
  });

  factory TaxRate.fromJson(Map<String, dynamic> json) {
    return TaxRate(
      id: JsonParser.requireInt(json['id'], model: modelName, field: 'tax_rates[].id'),
      title: JsonParser.requireString(
        json['title'],
        model: modelName,
        field: 'tax_rates[].title',
      ),
      rate: JsonParser.requireString(
        json['rate'],
        model: modelName,
        field: 'tax_rates[].rate',
      ),

      createdAt: JsonParser.string(json['created_at'] ?? ''),
      updatedAt: JsonParser.string(json['updated_at'] ?? ''),

      pivot: json['pivot'] != null
          ? Pivot.fromJson(json['pivot'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['rate'] = rate;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    if (pivot != null) {
      data['pivot'] = pivot!.toJson();
    }
    return data;
  }
}

class Pivot {
  int? taxClassId;
  int? taxRateId;
  String? createdAt;
  String? updatedAt;

  Pivot({
    this.taxClassId,
    this.taxRateId,
    this.createdAt,
    this.updatedAt,
  });

  factory Pivot.fromJson(Map<String, dynamic> json) {
    return Pivot(
      taxClassId: JsonParser.intValue(json['tax_class_id']),
      taxRateId: JsonParser.intValue(json['tax_rate_id']),
      createdAt: JsonParser.string(json['created_at'] ?? ''),
      updatedAt: JsonParser.string(json['updated_at'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['tax_class_id'] = taxClassId;
    data['tax_rate_id'] = taxRateId;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}