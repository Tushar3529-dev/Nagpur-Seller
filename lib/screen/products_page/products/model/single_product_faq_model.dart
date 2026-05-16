import 'package:hyper_local_seller/service/json_parser.dart';

const String modelName = 'single_product_faq_model';

class SingleProductFaqResponse {
  bool? success;
  String? message;
  SingleFaqData? data;

  SingleProductFaqResponse({this.success, this.message, this.data});

  factory SingleProductFaqResponse.fromJson(Map<String, dynamic> json) {
    return SingleProductFaqResponse(
      success: JsonParser.boolValue(json['success'] ?? false),
      message: JsonParser.string(json['message'] ?? ''),
      data: json['data'] != null
          ? SingleFaqData.fromJson(json['data'] as Map<String, dynamic>)
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

class SingleFaqData {
  int id;
  int productId;
  String? productSlug;
  ProductBasic? product;
  String question;
  String? answer;
  String status;
  String? createdAt;
  String? updatedAt;

  SingleFaqData({
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

  factory SingleFaqData.fromJson(Map<String, dynamic> json) {
    return SingleFaqData(
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