import 'package:hyper_local_seller/service/json_parser.dart';

const String modelName = 'attribute_values_model';

class AttributeValuesResponse {
  bool? success;
  String? message;
  AttributeValueData? data;

  AttributeValuesResponse({this.success, this.message, this.data});

  factory AttributeValuesResponse.fromJson(Map<String, dynamic> json) {
    return AttributeValuesResponse(
      success: JsonParser.boolValue(json['success'] ?? false),
      message: JsonParser.string(json['message'] ?? ''),
      data: json['data'] != null
          ? AttributeValueData.fromJson(json['data'] as Map<String, dynamic>)
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

class AttributeValueData {
  int id;
  int sellerId;
  String title;
  String slug;
  String label;
  String swatcheType;
  String? deletedAt;
  String? createdAt;
  String? updatedAt;
  List<AttributeValue>? values;

  AttributeValueData({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.slug,
    required this.label,
    required this.swatcheType,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
    this.values,
  });

  factory AttributeValueData.fromJson(Map<String, dynamic> json) {
    return AttributeValueData(
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

      values: JsonParser.list<AttributeValue>(
        json['values'],
            (v) => AttributeValue.fromJson(v as Map<String, dynamic>),
      ),
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
    if (values != null) {
      data['values'] = values!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class AttributeValue {
  int id;
  int globalAttributeId;
  String title;
  String swatcheValue;
  String? createdAt;
  String? updatedAt;
  Attribute? attribute;

  AttributeValue({
    required this.id,
    required this.globalAttributeId,
    required this.title,
    required this.swatcheValue,
    this.createdAt,
    this.updatedAt,
    this.attribute,
  });

  factory AttributeValue.fromJson(Map<String, dynamic> json) {
    return AttributeValue(
      id: JsonParser.requireInt(json['id'], model: modelName, field: 'id'),
      globalAttributeId: JsonParser.requireInt(
        json['global_attribute_id'],
        model: modelName,
        field: 'global_attribute_id',
      ),
      title: JsonParser.requireString(
        json['title'],
        model: modelName,
        field: 'title',
      ),
      swatcheValue: JsonParser.string(json['swatche_value']),

      createdAt: JsonParser.string(json['created_at'] ?? ''),
      updatedAt: JsonParser.string(json['updated_at'] ?? ''),

      attribute: json['attribute'] != null
          ? Attribute.fromJson(json['attribute'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['global_attribute_id'] = globalAttributeId;
    data['title'] = title;
    data['swatche_value'] = swatcheValue;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    if (attribute != null) {
      data['attribute'] = attribute!.toJson();
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
    return data;
  }
}