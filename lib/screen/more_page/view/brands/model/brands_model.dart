import 'package:hyper_local_seller/service/json_parser.dart';

const String modelName = 'brands_model';

class BrandsResponse {
  bool? success;
  String? message;
  BrandsData? data;

  BrandsResponse({this.success, this.message, this.data});

  factory BrandsResponse.fromJson(Map<String, dynamic> json) {
    return BrandsResponse(
      success: JsonParser.boolValue(json['success'] ?? false),
      message: JsonParser.string(json['message'] ?? ''),
      data: json['data'] != null
          ? BrandsData.fromJson(json['data'] as Map<String, dynamic>)
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

class BrandsData {
  int? currentPage;
  int? lastPage;
  int? perPage;
  int? total;
  List<Brand>? brands;

  BrandsData({
    this.currentPage,
    this.lastPage,
    this.perPage,
    this.total,
    this.brands,
  });

  factory BrandsData.fromJson(Map<String, dynamic> json) {
    return BrandsData(
      currentPage: JsonParser.intValue(json['current_page'] ?? 1),
      lastPage: JsonParser.intValue(json['last_page'] ?? 1),
      perPage: JsonParser.intValue(json['per_page'] ?? 10),
      total: JsonParser.intValue(json['total'] ?? 0),

      // list is allowed to be missing → empty list
      brands: JsonParser.list<Brand>(
        json['data'],
            (v) => Brand.fromJson(v as Map<String, dynamic>),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['current_page'] = currentPage;
    data['last_page'] = lastPage;
    data['per_page'] = perPage;
    data['total'] = total;
    if (brands != null) {
      data['data'] = brands!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Brand {
  int id;
  String title;
  String slug;
  String logo;
  String status;
  String? scopeType;
  int? scopeId;
  String? scopeCategorySlug;
  String? scopeCategoryTitle;
  String description;
  dynamic metadata;
  int totalProducts;

  Brand({
    required this.id,
    required this.title,
    required this.slug,
    required this.logo,
    required this.status,
    this.scopeType,
    this.scopeId,
    this.scopeCategorySlug,
    this.scopeCategoryTitle,
    required this.description,
    this.metadata,
    required this.totalProducts,
  });

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      id: JsonParser.requireInt(json['id'], model: modelName, field: 'id'),
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
      logo: JsonParser.requireString(
        json['logo'],
        model: modelName,
        field: 'logo',
      ),

      status: JsonParser.string(json['status'] ?? 'active'),
      scopeType: json['scope_type']?.toString(),
      scopeId: JsonParser.intValue(json['scope_id']),
      scopeCategorySlug: JsonParser.string(json['scope_category_slug'] ?? ''),
      scopeCategoryTitle: JsonParser.string(json['scope_category_title'] ?? ''),

      description: JsonParser.string(json['description'] ?? ''),

      metadata: json['metadata'],

      totalProducts: JsonParser.intValue(json['total_products'] ?? 0),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['slug'] = slug;
    data['logo'] = logo;
    data['status'] = status;
    data['scope_type'] = scopeType;
    data['scope_id'] = scopeId;
    data['scope_category_slug'] = scopeCategorySlug;
    data['scope_category_title'] = scopeCategoryTitle;
    data['description'] = description;
    data['metadata'] = metadata;
    data['total_products'] = totalProducts;
    return data;
  }
}