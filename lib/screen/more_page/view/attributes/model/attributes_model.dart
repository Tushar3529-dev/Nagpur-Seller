import 'package:hyper_local_seller/service/json_parser.dart';

const String modelName = 'attributes_model';

class AttributesResponse {
  bool? success;
  String? message;
  AttributesData? data;

  AttributesResponse({this.success, this.message, this.data});

  factory AttributesResponse.fromJson(Map<String, dynamic> json) {
    return AttributesResponse(
      success: JsonParser.boolValue(json['success'] ?? false),
      message: JsonParser.string(json['message'] ?? ''),
      data: json['data'] != null
          ? AttributesData.fromJson(json['data'] as Map<String, dynamic>)
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

class AttributesData {
  int? currentPage;
  int? lastPage;
  int? perPage;
  int? total;
  List<Attribute>? attributes;

  AttributesData({
    this.currentPage,
    this.lastPage,
    this.perPage,
    this.total,
    this.attributes,
  });

  factory AttributesData.fromJson(Map<String, dynamic> json) {
    return AttributesData(
      currentPage: JsonParser.intValue(json['current_page'] ?? 1),
      lastPage: JsonParser.intValue(json['last_page'] ?? 1),
      perPage: JsonParser.intValue(json['per_page'] ?? 15),
      total: JsonParser.intValue(json['total'] ?? 0),

      // list is allowed to be missing → empty list
      attributes: JsonParser.list<Attribute>(
        json['data'],
            (v) => Attribute.fromJson(v as Map<String, dynamic>),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['current_page'] = currentPage;
    data['last_page'] = lastPage;
    data['per_page'] = perPage;
    data['total'] = total;
    if (attributes != null) {
      data['data'] = attributes!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Attribute {
  int id;
  int sellerId;
  String title;
  String slug;
  String label;
  String swatcheType;
  String? deletedAt;
  String? createdAt;
  String? updatedAt;
  int valuesCount;

  Attribute({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.slug,
    required this.label,
    required this.swatcheType,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
    required this.valuesCount,
  });

  factory Attribute.fromJson(Map<String, dynamic> json) {
    return Attribute(
      id: JsonParser.requireInt(json['id'], model: modelName, field: 'id'),
      sellerId: JsonParser.requireInt(
        json['seller_id'],
        model: modelName,
        field: 'seller_id',
      ),
      title: JsonParser.requireString(
        json['title'],
        model: modelName,
        field: 'title',
      ),
      slug: JsonParser.requireString(
        json['slug'],
        model: modelName,
        field: 'slug',
      ),
      label: JsonParser.requireString(
        json['label'],
        model: modelName,
        field: 'label',
      ),
      swatcheType: JsonParser.requireString(
        json['swatche_type'],
        model: modelName,
        field: 'swatche_type',
      ),

      deletedAt: JsonParser.string(json['deleted_at']),
      createdAt: JsonParser.string(json['created_at'] ?? ''),
      updatedAt: JsonParser.string(json['updated_at'] ?? ''),

      valuesCount: JsonParser.intValue(json['values_count'] ?? 0),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['seller_id'] = sellerId;
    data['title'] = title;
    data['slug'] = slug;
    data['label'] = label;
    data['swatche_type'] = swatcheType;
    data['deleted_at'] = deletedAt;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['values_count'] = valuesCount;
    return data;
  }
}