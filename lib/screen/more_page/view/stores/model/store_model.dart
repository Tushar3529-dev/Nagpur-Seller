import 'package:hyper_local_seller/service/json_parser.dart';

const String modelName = 'stores_model';

class StoresResponse {
  bool? success;
  String? message;
  StoresPageData? data;

  StoresResponse({this.success, this.message, this.data});

  factory StoresResponse.fromJson(Map<String, dynamic> json) {
    return StoresResponse(
      success: JsonParser.boolValue(json['success'] ?? false),
      message: JsonParser.string(json['message'] ?? ''),
      data: json['data'] != null
          ? StoresPageData.fromJson(json['data'] as Map<String, dynamic>)
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

class StoresPageData {
  int? currentPage;
  int? lastPage;
  int? perPage;
  int? total;
  List<Store>? stores;

  StoresPageData({
    this.currentPage,
    this.lastPage,
    this.perPage,
    this.total,
    this.stores,
  });

  factory StoresPageData.fromJson(Map<String, dynamic> json) {
    return StoresPageData(
      currentPage: JsonParser.intValue(json['current_page'] ?? 1),
      lastPage: JsonParser.intValue(json['last_page'] ?? 1),
      perPage: JsonParser.intValue(json['per_page'] ?? 15),
      total: JsonParser.intValue(json['total'] ?? 0),

      stores: JsonParser.list<Store>(
        json['data'],
            (v) => Store.fromJson(v as Map<String, dynamic>),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['current_page'] = currentPage;
    data['last_page'] = lastPage;
    data['per_page'] = perPage;
    data['total'] = total;
    if (stores != null) {
      data['data'] = stores!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Store {
  int id;
  String name;
  String slug;
  int? productCount;
  String? description;
  String? contactNumber;
  String? contactEmail;
  int? sellerId;
  String? taxName;
  String? taxNumber;
  String? bankName;
  String? bankBranchCode;
  String? accountHolderName;
  String? accountNumber;
  String? routingNumber;
  String? bankAccountType;
  String? currencyCode;
  int? maxDeliveryDistance;
  int? orderPreparationTime;
  String? promotionalText;
  String? aboutUs;
  String? returnReplacementPolicy;
  String? refundPolicy;
  String? termsAndConditions;
  String? deliveryPolicy;
  String? domesticShippingCharges;
  String? internationalShippingCharges;
  dynamic metadata;
  String? fulfillmentType;
  String? address;
  String? city;
  String? landmark;
  String? state;
  String? country;
  String? countryCode;
  String? zipcode;
  String? latitude;
  String? longitude;
  int? distance;
  String? timing;
  String? logo;
  String? banner;
  String? addressProof;
  String? voidedCheck;
  String? avgProductsRating;
  String? avgStoreRating;
  int? totalStoreFeedback;
  String? createdAt;
  String? updatedAt;
  String? verificationStatus;
  String? visibilityStatus;
  StoreStatus? status;

  Store({
    required this.id,
    required this.name,
    required this.slug,
    this.productCount,
    this.description,
    this.contactNumber,
    this.contactEmail,
    this.sellerId,
    this.taxName,
    this.taxNumber,
    this.bankName,
    this.bankBranchCode,
    this.accountHolderName,
    this.accountNumber,
    this.routingNumber,
    this.bankAccountType,
    this.currencyCode,
    this.maxDeliveryDistance,
    this.orderPreparationTime,
    this.promotionalText,
    this.aboutUs,
    this.returnReplacementPolicy,
    this.refundPolicy,
    this.termsAndConditions,
    this.deliveryPolicy,
    this.domesticShippingCharges,
    this.internationalShippingCharges,
    this.metadata,
    this.fulfillmentType,
    this.address,
    this.city,
    this.landmark,
    this.state,
    this.country,
    this.countryCode,
    this.zipcode,
    this.latitude,
    this.longitude,
    this.distance,
    this.timing,
    this.logo,
    this.banner,
    this.addressProof,
    this.voidedCheck,
    this.avgProductsRating,
    this.avgStoreRating,
    this.totalStoreFeedback,
    this.createdAt,
    this.updatedAt,
    this.verificationStatus,
    this.visibilityStatus,
    this.status,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: JsonParser.intValue(json['id']),
      name: JsonParser.string(json['name']),
      slug: JsonParser.string(json['slug']),

      productCount: JsonParser.intValue(json['product_count'] ?? 0),
      description: JsonParser.string(json['description'] ?? ''),
      contactNumber: JsonParser.string(json['contact_number'] ?? ''),
      contactEmail: JsonParser.string(json['contact_email'] ?? ''),
      sellerId: JsonParser.intValue(json['seller_id']),
      taxName: JsonParser.string(json['tax_name'] ?? ''),
      taxNumber: JsonParser.string(json['tax_number'] ?? ''),
      bankName: JsonParser.string(json['bank_name'] ?? ''),
      bankBranchCode: JsonParser.string(json['bank_branch_code'] ?? ''),
      accountHolderName: JsonParser.string(json['account_holder_name'] ?? ''),
      accountNumber: JsonParser.string(json['account_number'] ?? ''),
      routingNumber: JsonParser.string(json['routing_number'] ?? ''),
      bankAccountType: JsonParser.string(json['bank_account_type'] ?? ''),
      currencyCode: JsonParser.string(json['currency_code'] ?? ''),
      maxDeliveryDistance: JsonParser.intValue(json['max_delivery_distance']),
      orderPreparationTime: JsonParser.intValue(json['order_preparation_time']),
      promotionalText: JsonParser.string(json['promotional_text'] ?? ''),
      aboutUs: JsonParser.string(json['about_us'] ?? ''),
      returnReplacementPolicy: JsonParser.string(json['return_replacement_policy'] ?? ''),
      refundPolicy: JsonParser.string(json['refund_policy'] ?? ''),
      termsAndConditions: JsonParser.string(json['terms_and_conditions'] ?? ''),
      deliveryPolicy: JsonParser.string(json['delivery_policy'] ?? ''),
      domesticShippingCharges: JsonParser.string(json['domestic_shipping_charges'] ?? ''),
      internationalShippingCharges: JsonParser.string(json['international_shipping_charges'] ?? ''),
      metadata: json['metadata'],
      fulfillmentType: JsonParser.string(json['fulfillment_type'] ?? ''),
      address: JsonParser.string(json['address'] ?? ''),
      city: JsonParser.string(json['city'] ?? ''),
      landmark: JsonParser.string(json['landmark'] ?? ''),
      state: JsonParser.string(json['state'] ?? ''),
      country: JsonParser.string(json['country'] ?? 'India'),
      countryCode: JsonParser.string(json['country_code'] ?? ''),
      zipcode: JsonParser.string(json['zipcode'] ?? ''),
      latitude: JsonParser.string(json['latitude']),
      longitude: JsonParser.string(json['longitude']),
      distance: JsonParser.intValue(json['distance']),
      timing: JsonParser.string(json['timing'] ?? ''),
      logo: JsonParser.string(json['logo'] ?? ''),
      banner: JsonParser.string(json['banner'] ?? ''),
      addressProof: JsonParser.string(json['address_proof'] ?? ''),
      voidedCheck: JsonParser.string(json['voided_check'] ?? ''),
      avgProductsRating: JsonParser.string(json['avg_products_rating'] ?? '0.0'),
      avgStoreRating: JsonParser.string(json['avg_store_rating'] ?? '0.0'),
      totalStoreFeedback: JsonParser.intValue(json['total_store_feedback'] ?? 0),
      createdAt: JsonParser.string(json['created_at'] ?? ''),
      updatedAt: JsonParser.string(json['updated_at'] ?? ''),
      verificationStatus: JsonParser.string(json['verification_status'] ?? ''),
      visibilityStatus: JsonParser.string(json['visibility_status'] ?? ''),
      status: json['status'] != null
          ? StoreStatus.fromJson(json['status'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['slug'] = slug;
    data['product_count'] = productCount;
    data['description'] = description;
    data['contact_number'] = contactNumber;
    data['contact_email'] = contactEmail;
    data['seller_id'] = sellerId;
    data['tax_name'] = taxName;
    data['tax_number'] = taxNumber;
    data['bank_name'] = bankName;
    data['bank_branch_code'] = bankBranchCode;
    data['account_holder_name'] = accountHolderName;
    data['account_number'] = accountNumber;
    data['routing_number'] = routingNumber;
    data['bank_account_type'] = bankAccountType;
    data['currency_code'] = currencyCode;
    data['max_delivery_distance'] = maxDeliveryDistance;
    data['order_preparation_time'] = orderPreparationTime;
    data['promotional_text'] = promotionalText;
    data['about_us'] = aboutUs;
    data['return_replacement_policy'] = returnReplacementPolicy;
    data['refund_policy'] = refundPolicy;
    data['terms_and_conditions'] = termsAndConditions;
    data['delivery_policy'] = deliveryPolicy;
    data['domestic_shipping_charges'] = domesticShippingCharges;
    data['international_shipping_charges'] = internationalShippingCharges;
    data['metadata'] = metadata;
    data['fulfillment_type'] = fulfillmentType;
    data['address'] = address;
    data['city'] = city;
    data['landmark'] = landmark;
    data['state'] = state;
    data['country'] = country;
    data['country_code'] = countryCode;
    data['zipcode'] = zipcode;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    data['distance'] = distance;
    data['timing'] = timing;
    data['logo'] = logo;
    data['banner'] = banner;
    data['address_proof'] = addressProof;
    data['voided_check'] = voidedCheck;
    data['avg_products_rating'] = avgProductsRating;
    data['avg_store_rating'] = avgStoreRating;
    data['total_store_feedback'] = totalStoreFeedback;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['verification_status'] = verificationStatus;
    data['visibility_status'] = visibilityStatus;
    if (status != null) data['status'] = status!.toJson();
    return data;
  }
}

class StoreStatus {
  bool isOpen;
  String? status;

  StoreStatus({
    this.isOpen = false,
    this.status,
  });

  factory StoreStatus.fromJson(Map<String, dynamic> json) {
    return StoreStatus(
      isOpen: JsonParser.boolValue(json['is_open'] ?? false),
      status: JsonParser.string(json['status'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['is_open'] = isOpen;
    data['status'] = status;
    return data;
  }
}