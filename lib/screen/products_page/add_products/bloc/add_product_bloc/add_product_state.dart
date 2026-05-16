part of 'add_product_bloc.dart';

@immutable
sealed class AddProductState {
  final ProductData productData;
  const AddProductState(this.productData);
}

final class AddProductInitial extends AddProductState {
  AddProductInitial() : super(ProductData());
}

/// Loading state while fetching product data from API for editing
final class AddProductLoadingEdit extends AddProductState {
  AddProductLoadingEdit() : super(ProductData());
}

final class AddProductUpdating extends AddProductState {
  const AddProductUpdating(super.productData);
}

final class AddProductSubmitting extends AddProductState {
  const AddProductSubmitting(super.productData);
}

final class AddProductSuccess extends AddProductState {
  const AddProductSuccess(super.productData);
}

final class AddProductFailure extends AddProductState {
  final String error;
  const AddProductFailure(super.productData, this.error);
}

class StorePricing {
  final int storeId;
  final String storeName;
  final String? price;
  final String? specialPrice;
  final String? cost;
  final String? stock;
  final String? sku;

  StorePricing({
    required this.storeId,
    required this.storeName,
    this.price,
    this.specialPrice,
    this.cost,
    this.stock,
    this.sku,
  });

  StorePricing copyWith({
    int? storeId,
    String? storeName,
    String? price,
    String? specialPrice,
    String? cost,
    String? stock,
    String? sku,
  }) {
    return StorePricing(
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      price: price ?? this.price,
      specialPrice: specialPrice ?? this.specialPrice,
      cost: cost ?? this.cost,
      stock: stock ?? this.stock,
      sku: sku ?? this.sku,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "store_id": storeId.toString(),
      "price": price ?? "",
      "special_price": specialPrice ?? "",
      "cost": cost ?? "",
      "stock": stock ?? "",
      "sku": sku ?? "",
    };
  }
}

class VariantStorePricing {
  final int storeId;
  final String variantId;
  final String? price;
  final String? specialPrice;
  final String? cost;
  final String? stock;
  final String? sku;

  VariantStorePricing({
    required this.storeId,
    required this.variantId,
    this.price,
    this.specialPrice,
    this.cost,
    this.stock,
    this.sku,
  });

  VariantStorePricing copyWith({
    int? storeId,
    String? variantId,
    String? price,
    String? specialPrice,
    String? cost,
    String? stock,
    String? sku,
  }) {
    return VariantStorePricing(
      storeId: storeId ?? this.storeId,
      variantId: variantId ?? this.variantId,
      price: price ?? this.price,
      specialPrice: specialPrice ?? this.specialPrice,
      cost: cost ?? this.cost,
      stock: stock ?? this.stock,
      sku: sku ?? this.sku,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "store_id": storeId.toString(),
      "variant_id": variantId,
      "price": price ?? "",
      "special_price": specialPrice ?? "",
      "cost": cost ?? "",
      "stock": stock ?? "",
      "sku": sku ?? "",
    };
  }
}

class ProductData {
  int? id;
  int? categoryId;
  int? brandId;
  String? brandName; // New
  String? madeIn;
  String? title;
  String? hsnCode;
  String? indicator;
  int prepTime = 20;
  bool isReturnable = false;
  int returnableDays = 0;
  bool isCancelable = false;
  String? cancelableTill;
  String type = 'simple'; // 'simple' or 'variant'
  String? barcode;
  String? mainImage;
  List<String> otherImages = [];
  List<int> taxGroupIds = [];
  List<VariantData> variants = [];
  List<StorePricing> storePricing = [];
  List<VariantStorePricing> variantStorePricing = []; // Added this
  String imageFit = "cover"; // 'cover' or 'contain'
  String? videoType;
  String? videoLink;
  String? productVideo;
  String? shortDescription;
  String? description;
  int minimumOrderQuantity = 1;
  int quantityStepSize = 1;
  int totalAllowedQuantity = 0;
  bool isAttachmentRequired = false;
  bool featured = false;
  bool requiresOtp = false;
  String? warrantyPeriod;
  String? guaranteePeriod;
  List<String> tags = [];
  List<Map<String, String>> customFields = [];
  List<int> categoryLineage = []; // To track expanded parents during edit
  List<CustomProductSection> customProductSections = [];

  ProductData();

  ProductData copyWith({
    int? id,
    int? categoryId,
    int? brandId,
    String? brandName,
    String? madeIn,
    String? title,
    String? hsnCode,
    String? indicator,
    int? prepTime,
    bool? isReturnable,
    int? returnableDays,
    bool? isCancelable,
    String? cancelableTill,
    String? type,
    String? barcode,
    String? mainImage,
    List<String>? otherImages,
    List<int>? taxGroupIds,
    List<VariantData>? variants,
    List<StorePricing>? storePricing,
    List<VariantStorePricing>? variantStorePricing,
    String? imageFit,
    String? videoType,
    String? videoLink,
    String? productVideo,
    String? shortDescription,
    String? description,
    int? minimumOrderQuantity,
    int? quantityStepSize,
    int? totalAllowedQuantity,
    bool? isAttachmentRequired,
    bool? featured,
    bool? requiresOtp,
    String? warrantyPeriod,
    String? guaranteePeriod,
    List<String>? tags,
    List<Map<String, String>>? customFields,
    List<int>? categoryLineage,
    List<CustomProductSection>? customProductSections,
    bool clearMainImage = false,
    bool clearProductVideo = false,
    bool clearVideoLink = false,
  }) {
    final newData = ProductData();
    newData.id = id ?? this.id;
    newData.categoryId = categoryId ?? this.categoryId;
    newData.brandId = brandId ?? this.brandId;
    newData.brandName = brandName ?? this.brandName;
    newData.madeIn = madeIn ?? this.madeIn;
    newData.title = title ?? this.title;
    newData.hsnCode = hsnCode ?? this.hsnCode;
    newData.indicator = indicator ?? this.indicator;
    newData.prepTime = prepTime ?? this.prepTime;
    newData.isReturnable = isReturnable ?? this.isReturnable;
    newData.returnableDays = returnableDays ?? this.returnableDays;
    newData.isCancelable = isCancelable ?? this.isCancelable;
    newData.cancelableTill = cancelableTill ?? this.cancelableTill;
    newData.type = type ?? this.type;
    newData.barcode = barcode ?? this.barcode;
    newData.mainImage = clearMainImage ? null : (mainImage ?? this.mainImage);
    newData.otherImages = otherImages ?? this.otherImages;
    newData.taxGroupIds = taxGroupIds ?? this.taxGroupIds;
    newData.variants = variants ?? this.variants;
    newData.storePricing = storePricing ?? this.storePricing;
    newData.variantStorePricing =
        variantStorePricing ?? this.variantStorePricing;
    newData.imageFit = imageFit ?? this.imageFit;
    newData.videoType = videoType ?? this.videoType;
    newData.videoLink = clearVideoLink ? null : (videoLink ?? this.videoLink);
    newData.productVideo =
        clearProductVideo ? null : (productVideo ?? this.productVideo);
    newData.shortDescription = shortDescription ?? this.shortDescription;
    newData.description = description ?? this.description;
    newData.minimumOrderQuantity =
        minimumOrderQuantity ?? this.minimumOrderQuantity;
    newData.quantityStepSize = quantityStepSize ?? this.quantityStepSize;
    newData.totalAllowedQuantity =
        totalAllowedQuantity ?? this.totalAllowedQuantity;
    newData.isAttachmentRequired =
        isAttachmentRequired ?? this.isAttachmentRequired;
    newData.featured = featured ?? this.featured;
    newData.requiresOtp = requiresOtp ?? this.requiresOtp;
    newData.warrantyPeriod = warrantyPeriod ?? this.warrantyPeriod;
    newData.guaranteePeriod = guaranteePeriod ?? this.guaranteePeriod;
    newData.tags = tags ?? this.tags;
    newData.customFields = customFields ?? this.customFields;
    newData.categoryLineage = categoryLineage ?? this.categoryLineage;
    newData.customProductSections =
        customProductSections ?? this.customProductSections;
    return newData;
  }
}

class VariantData {
  String? id;
  String title;
  String? name; // New optional name
  List<int> attributeValueIds;
  List<Map<String, dynamic>> attributes; // New detailed mapping
  String? barcode;
  String? weight;
  String? height;
  String? length;
  String? breadth;
  bool isAvailable;
  bool isDefault;
  String? image; // New variant image

  VariantData({
    this.id,
    required this.title,
    this.name,
    required this.attributeValueIds,
    this.attributes = const [],
    this.barcode,
    this.weight,
    this.height,
    this.length,
    this.breadth,
    this.isAvailable = true,
    this.isDefault = false,
    this.image,
  });

  VariantData copyWith({
    String? id,
    String? title,
    String? name,
    List<int>? attributeValueIds,
    List<Map<String, dynamic>>? attributes,
    String? barcode,
    String? weight,
    String? height,
    String? length,
    String? breadth,
    bool? isAvailable,
    bool? isDefault,
    String? image,
    bool clearImage = false,
  }) {
    return VariantData(
      id: id ?? this.id,
      title: title ?? this.title,
      name: name ?? this.name,
      attributeValueIds: attributeValueIds ?? this.attributeValueIds,
      attributes: attributes ?? this.attributes,
      barcode: barcode ?? this.barcode,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      length: length ?? this.length,
      breadth: breadth ?? this.breadth,
      isAvailable: isAvailable ?? this.isAvailable,
      isDefault: isDefault ?? this.isDefault,
      image: clearImage ? null : (image ?? this.image),
    );
  }
}

class CustomProductSection {
  int? id;
  String? uuid;
  String? title;
  String? description;
  int sortOrder;
  List<CustomProductField> fields;

  CustomProductSection({
    this.id,
    this.uuid,
    this.title,
    this.description,
    this.sortOrder = 0,
    this.fields = const [],
  });

  CustomProductSection copyWith({
    int? id,
    String? uuid,
    String? title,
    String? description,
    int? sortOrder,
    List<CustomProductField>? fields,
  }) {
    return CustomProductSection(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      title: title ?? this.title,
      description: description ?? this.description,
      sortOrder: sortOrder ?? this.sortOrder,
      fields: fields ?? this.fields,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title ?? "",
      'description': description ?? "",
      'sort_order': sortOrder,
      'fields': fields.map((f) => f.toJson()).toList(),
    };
  }
}

class CustomProductField {
  int? id;
  String? uuid;
  String? title;
  String? description;
  String? image;
  int sortOrder;

  CustomProductField({
    this.id,
    this.uuid,
    this.title,
    this.description,
    this.image,
    this.sortOrder = 0,
  });

  CustomProductField copyWith({
    int? id,
    String? uuid,
    String? title,
    String? description,
    String? image,
    int? sortOrder,
    bool clearImage = false,
  }) {
    return CustomProductField(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      title: title ?? this.title,
      description: description ?? this.description,
      image: clearImage ? null : (image ?? this.image),
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title ?? "",
      'description': description ?? "",
      if (image != null && !image!.startsWith('http')) 'image': image,
      'sort_order': sortOrder,
    };
  }
}
