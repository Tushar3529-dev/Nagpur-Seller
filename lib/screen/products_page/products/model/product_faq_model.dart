import 'package:hyper_local_seller/service/json_parser.dart';

const String modelName = 'product_faq_model';

class ProductFaqResponse {
  bool? success;
  String? message;
  ProductFaqPageData? data;

  ProductFaqResponse({this.success, this.message, this.data});

  factory ProductFaqResponse.fromJson(Map<String, dynamic> json) {
    return ProductFaqResponse(
      success: JsonParser.boolValue(json['success'] ?? false),
      message: JsonParser.string(json['message'] ?? ''),
      data: json['data'] != null
          ? ProductFaqPageData.fromJson(json['data'] as Map<String, dynamic>)
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

class ProductFaqPageData {
  int? currentPage;
  int? lastPage;
  int? perPage;
  int? total;
  List<ProductFaq>? faqs;

  ProductFaqPageData({
    this.currentPage,
    this.lastPage,
    this.perPage,
    this.total,
    this.faqs,
  });

  factory ProductFaqPageData.fromJson(Map<String, dynamic> json) {
    return ProductFaqPageData(
      currentPage: JsonParser.intValue(json['current_page'] ?? 1),
      lastPage: JsonParser.intValue(json['last_page'] ?? 1),
      perPage: JsonParser.intValue(json['per_page'] ?? 15),
      total: JsonParser.intValue(json['total'] ?? 0),

      faqs: JsonParser.list<ProductFaq>(
        json['data'],
            (v) => ProductFaq.fromJson(v as Map<String, dynamic>),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['current_page'] = currentPage;
    data['last_page'] = lastPage;
    data['per_page'] = perPage;
    data['total'] = total;
    if (faqs != null) {
      data['data'] = faqs!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ProductFaq {
  int id;
  int productId;
  String? productSlug;
  ProductBasic? product;
  String question;
  String? answer;
  String status;
  String? createdAt;
  String? updatedAt;

  ProductFaq({
    required this.id,
    required this.productId,
    this.productSlug,
    this.product,
    required this.question,
    this.answer,
    this.status = 'pending',
    this.createdAt,
    this.updatedAt,
  });

  factory ProductFaq.fromJson(Map<String, dynamic> json) {
    return ProductFaq(
      id: JsonParser.requireInt(
        json['id'],
        model: modelName,
        field: 'id',
      ),
      productId: JsonParser.requireInt(
        json['product_id'],
        model: modelName,
        field: 'product_id',
      ),
      productSlug: JsonParser.string(json['product_slug'] ?? ''),

      product: json['product'] != null
          ? ProductBasic.fromJson(json['product'] as Map<String, dynamic>)
          : null,

      question: JsonParser.requireString(
        json['question'],
        model: modelName,
        field: 'question',
      ),

      answer: JsonParser.string(json['answer'] ?? ''),

      status: JsonParser.string(json['status'] ?? 'pending'),

      createdAt: JsonParser.string(json['created_at'] ?? ''),
      updatedAt: JsonParser.string(json['updated_at'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['product_id'] = productId;
    data['product_slug'] = productSlug;
    if (product != null) {
      data['product'] = product!.toJson();
    }
    data['question'] = question;
    data['answer'] = answer;
    data['status'] = status;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}

class ProductBasic {
  int id;
  String title;
  String slug;

  ProductBasic({
    required this.id,
    required this.title,
    required this.slug,
  });

  factory ProductBasic.fromJson(Map<String, dynamic> json) {
    return ProductBasic(
      id: JsonParser.intValue(json['id'] ?? 0),
      title: JsonParser.string(json['title'] ?? ''),
      slug: JsonParser.string(json['slug'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['slug'] = slug;
    return data;
  }
}