import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:hyper_local_seller/config/api_routes.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/bloc/add_product_bloc/add_product_bloc.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';

class AddProductRepo {
  final ApiBaseHelper _helper = ApiBaseHelper();

  Future<dynamic> addProduct({required ProductData productData}) async {
    try {
      final Map<String, dynamic> fields = {
        "title": productData.title,
        "indicator": productData.indicator,
        "made_in": productData.madeIn,
        "hsn_code": productData.hsnCode,
        // "brand_id": productData.brandId,
        "total_allowed_quantity": productData.totalAllowedQuantity,
        "minimum_order_quantity": productData.minimumOrderQuantity,
        "quantity_step_size": productData.quantityStepSize,
        "base_prep_time": productData.prepTime,
        "image_fit": productData.imageFit.toLowerCase(),
        "is_returnable": productData.isReturnable ? "1" : "0",
        "returnable_days": productData.returnableDays,
        "is_cancelable": productData.isCancelable ? "1" : "0",
        "cancelable_till": productData.cancelableTill,
        "is_attachment_required": productData.isAttachmentRequired ? "1" : "0",
        "featured": productData.featured ? "1" : "0",
        "requires_otp": productData.requiresOtp ? "1" : "0",
        "type": productData.type.toLowerCase(),
        "short_description": productData.shortDescription,
        "description": productData.description,
        "video_type": productData.videoType,
        "video_link": productData.videoLink,
        "warranty_period": productData.warrantyPeriod,
        "guarantee_period": productData.guaranteePeriod,
        "barcode": productData.barcode,
      };

      if (productData.categoryId != null) {
        fields["category_id"] = productData.categoryId.toString();
      }

      final brandId = productData.brandId;

      if (brandId != null) {
        final parsedId = int.tryParse(brandId.toString());

        if (parsedId != null && parsedId > 0) {
          fields["brand_id"] = parsedId.toString();
        }
      }

      for (int i = 0; i < productData.taxGroupIds.length; i++) {
        fields["tax_groups[$i]"] = productData.taxGroupIds[i].toString();
      }

      if (productData.mainImage != null && productData.mainImage!.isNotEmpty) {
        fields["main_image"] = await MultipartFile.fromFile(
          productData.mainImage!,
        );
      }

      if (productData.productVideo != null && productData.productVideo!.isNotEmpty) {
        fields["product_video"] = await MultipartFile.fromFile(
          productData.productVideo!,
        );
      }

      if (productData.otherImages.isEmpty && productData.id != null) {
        // Signal to clear additional images
        fields["additional_images"] = "";
      } else {
        for (int i = 0; i < productData.otherImages.length; i++) {
          if (productData.otherImages[i].startsWith('http')) {
            fields["additional_images[$i]"] = productData.otherImages[i];
          } else if (productData.otherImages[i].isNotEmpty) {
            fields["additional_images[$i]"] = await MultipartFile.fromFile(
              productData.otherImages[i],
            );
          }
        }
      }

      for (int i = 0; i < productData.tags.length; i++) {
        fields["tags[$i]"] = productData.tags[i];
      }

      for (int i = 0; i < productData.customFields.length; i++) {
        fields["custom_fields[$i]"] = jsonEncode({
          "key": productData.customFields[i]['key'],
          "value": productData.customFields[i]['value'],
        });
      }

      final Map<String, dynamic> pricingData = {
        "store_pricing": productData.storePricing
            .map((p) => p.toJson())
            .toList(),
        "variant_pricing": productData.variantStorePricing
            .map((p) => p.toJson())
            .toList(),
      };
      fields["pricing"] = jsonEncode(pricingData);

      // Add simple fields if needed for validation (though user requested pricing object)
      if (productData.type == 'simple' && productData.variants.isNotEmpty) {
        final first = productData.variants.first;
        fields["weight"] = first.weight;
        fields["height"] = first.height;
        fields["length"] = first.length;
        fields["breadth"] = first.breadth;
      } else if (productData.type == 'variant') {
        final List<Map<String, dynamic>> variantsJsonList = [];
        for (int i = 0; i < productData.variants.length; i++) {
          final variant = productData.variants[i];

          variantsJsonList.add({
            "id": variant.id,
            "title": variant.title,
            "weight": variant.weight ?? "",
            "breadth": variant.breadth ?? "",
            "length": variant.length ?? "",
            "height": variant.height ?? "",
            "availability": variant.isAvailable ? "yes" : "no",
            "barcode": variant.barcode ?? "",
            "is_default": variant.isDefault ? "on" : "",
            "attributes":
                variant.attributes, // Already contains {attribute_id, value_id}
          });

          if (variant.image != null && variant.image!.isNotEmpty) {
            if (variant.image!.startsWith('http')) {
               fields["variant_image${variant.id}"] = variant.image;
            } else {
              fields["variant_image${variant.id}"] = await MultipartFile.fromFile(
                variant.image!,
              );
            }
          }
        }
        fields["variants_json"] = jsonEncode(variantsJsonList);
      }

      // Handle Custom Product Sections
      for (int i = 0; i < productData.customProductSections.length; i++) {
        final section = productData.customProductSections[i];
        fields["custom_sections[$i][id]"] = section.id;
        fields["custom_sections[$i][title]"] = section.title;
        fields["custom_sections[$i][description]"] = section.description;
        fields["custom_sections[$i][sort_order]"] = section.sortOrder;

        for (int j = 0; j < section.fields.length; j++) {
          final field = section.fields[j];
          fields["custom_sections[$i][fields][$j][id]"] = field.id;
          fields["custom_sections[$i][fields][$j][title]"] = field.title;
          fields["custom_sections[$i][fields][$j][description]"] =
              field.description;
          fields["custom_sections[$i][fields][$j][sort_order]"] =
              field.sortOrder;

          if (field.image != null && field.image!.isNotEmpty) {
            if (field.image!.startsWith('http')) {
               fields["custom_sections[$i][fields][$j][image]"] = field.image;
            } else {
              fields["custom_sections[$i][fields][$j][image]"] =
                  await MultipartFile.fromFile(field.image!);
            }
          } else if (field.id != null) {
            // Signal to clear image for existing field
            fields["custom_sections[$i][fields][$j][remove_image]"] = "1";
          }
        }
      }

      final formData = FormData.fromMap(fields);
      String url = ApiRoutes.productsApi;

      if (productData.id != null) {
        fields["_method"] = "POST";
        url = "${ApiRoutes.productsApi}/${productData.id}";
        final updateFormData = FormData.fromMap(fields);
        final response = await _helper.postMultipart(url, updateFormData);
        return response;
      }

      final response = await _helper.postMultipart(url, formData);

      return response;
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
