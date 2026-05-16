import 'package:hyper_local_seller/service/json_parser.dart';

const String modelName = 'categories_model';

class CategoryResponse {
  bool? success;
  String? message;
  CategoryData? data;

  CategoryResponse({this.success, this.message, this.data});

  factory CategoryResponse.fromJson(Map<String, dynamic> json) {
    return CategoryResponse(
      success: JsonParser.boolValue(json['success'] ?? false),
      message: JsonParser.string(json['message'] ?? ''),
      data: json['data'] != null
          ? CategoryData.fromJson(json['data'] as Map<String, dynamic>)
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

class CategoryData {
  int? currentPage;
  int? lastPage;
  int? perPage;
  int? total;
  List<Category>? category;

  CategoryData({
    this.currentPage,
    this.lastPage,
    this.perPage,
    this.total,
    this.category,
  });

  factory CategoryData.fromJson(Map<String, dynamic> json) {
    return CategoryData(
      currentPage: JsonParser.intValue(json['current_page'] ?? 1),
      lastPage: JsonParser.intValue(json['last_page'] ?? 1),
      perPage: JsonParser.intValue(json['per_page'] ?? 10),
      total: JsonParser.intValue(json['total'] ?? 0),

      // list is allowed to be missing → empty list
      category: JsonParser.list<Category>(
        json['data'],
        (v) => Category.fromJson(v as Map<String, dynamic>),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['current_page'] = currentPage;
    data['last_page'] = lastPage;
    data['per_page'] = perPage;
    data['total'] = total;
    if (category != null) {
      data['data'] = category!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Category {
  int id;
  String title;
  String slug;
  String image;
  String banner;
  String icon;
  String activeIcon;
  String? backgroundType;
  String backgroundColor;
  String backgroundImage;
  String fontColor;
  int? parentId;
  String? parentSlug;
  String description;
  String commission;
  String status;
  bool requiresApproval;
  dynamic metadata;
  int subcategoryCount;
  int productCount;

  Category({
    required this.id,
    required this.title,
    required this.slug,
    required this.image,
    required this.banner,
    required this.icon,
    required this.activeIcon,
    this.backgroundType,
    required this.backgroundColor,
    required this.backgroundImage,
    required this.fontColor,
    this.parentId,
    this.parentSlug,
    required this.description,
    required this.status,
    required this.requiresApproval,
    this.metadata,
    required this.subcategoryCount,
    required this.productCount,
    required this.commission,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
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
      image: JsonParser.string(json['image'] ?? ''),

      banner: JsonParser.string(json['banner'] ?? ''),
      icon: JsonParser.string(json['icon'] ?? ''),
      activeIcon: JsonParser.string(json['active_icon'] ?? ''),

      backgroundType: json['background_type']?.toString(),
      backgroundColor: JsonParser.string(json['background_color'] ?? '#FFFFFF'),
      backgroundImage: JsonParser.string(json['background_image'] ?? ''),
      fontColor: JsonParser.string(json['font_color'] ?? '#000000'),

      parentId: JsonParser.intValue(json['parent_id']), // usually optional
      parentSlug: json['parent_slug']?.toString(),

      description: JsonParser.string(json['description'] ?? ''),
      status: JsonParser.string(json['status'] ?? 'active'),

      requiresApproval: JsonParser.boolValue(
        json['requires_approval'] ?? false,
      ),

      metadata: json['metadata'],

      subcategoryCount: JsonParser.intValue(json['subcategory_count'] ?? 0),
      productCount: JsonParser.intValue(json['product_count'] ?? 0),
      commission: JsonParser.string(json['commission']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['slug'] = slug;
    data['image'] = image;
    data['banner'] = banner;
    data['icon'] = icon;
    data['active_icon'] = activeIcon;
    data['background_type'] = backgroundType;
    data['background_color'] = backgroundColor;
    data['background_image'] = backgroundImage;
    data['font_color'] = fontColor;
    data['parent_id'] = parentId;
    data['parent_slug'] = parentSlug;
    data['description'] = description;
    data['status'] = status;
    data['requires_approval'] = requiresApproval;
    data['metadata'] = metadata;
    data['subcategory_count'] = subcategoryCount;
    data['product_count'] = productCount;
    data['commission'] = commission;
    return data;
  }
}
