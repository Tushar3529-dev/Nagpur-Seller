// ignore_for_file: unused_field

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/repo/add_product_repo.dart';
import 'package:hyper_local_seller/screen/products_page/products/model/product_model.dart';
import 'package:hyper_local_seller/screen/products_page/products/repo/products_repo.dart';
import 'package:hyper_local_seller/utils/image_picker_utils.dart';
import 'package:hyper_local_seller/screen/more_page/view/categories/repo/categories_repo.dart';

part 'add_product_event.dart';
part 'add_product_state.dart';

class AddProductBloc extends Bloc<AddProductEvent, AddProductState> {
  final AddProductRepo _repo;
  final ProductsRepo _productsRepo;
  final CategoriesRepo _categoriesRepo;

  AddProductBloc(this._repo, this._productsRepo, this._categoriesRepo) : super(AddProductInitial()) {
    on<UpdateProductData>(_onUpdateProductData);
    on<SubmitProduct>(_onSubmitProduct);
    on<AddProductReset>(_onReset);
    on<LoadProductForEdit>(_onLoadProductForEdit);
    on<SetProductForEdit>(_onSetProductForEdit);
  }

  Future<void> _onLoadProductForEdit(LoadProductForEdit event, Emitter<AddProductState> emit) async {
    emit(AddProductLoadingEdit());
    try {
      final response = await _productsRepo.getProductById(event.productId);
      if (response != null && response['data'] != null) {
        final product = Product.fromJson(response['data'] as Map<String, dynamic>);
        add(SetProductForEdit(product));
      } else {
        emit(AddProductFailure(ProductData(), 'Failed to load product data'));
      }
    } catch (e) {
      emit(AddProductFailure(ProductData(), e.toString()));
    }
  }

  Future<void> _onSetProductForEdit(SetProductForEdit event, Emitter<AddProductState> emit) async {
    final p = event.product;
    final data = ProductData();
    
    data.id = p.id;
    data.categoryId = p.categoryId;
    data.brandId = p.brandId;
    data.brandName = p.brandName;
    data.madeIn = p.madeIn;
    data.title = p.title;
    data.hsnCode = p.hsnCode;
    data.indicator = p.indicator;
    data.prepTime = p.prepTime ?? 20;
    data.isReturnable = p.isReturnable;
    data.returnableDays = p.returnableDays ?? 0;
    data.isCancelable = p.isCancelable ?? false;
    data.cancelableTill = p.cancelableTill;
    data.type = p.type ?? 'simple';
    data.barcode = p.variants?.isNotEmpty == true ? p.variants!.first.barcode : null;
    data.taxGroupIds = List<int>.from(p.taxGroups);
    data.imageFit = p.imageFit ?? "cover";
    data.videoType = p.videoType;
    data.videoLink = p.videoLink;
    data.shortDescription = p.shortDescription;
    data.description = p.description;
    data.minimumOrderQuantity = p.minimumOrderQuantity ?? 1;
    data.quantityStepSize = p.quantityStepSize ?? 1;
    data.totalAllowedQuantity = p.totalAllowedQuantity ?? 0;
    data.isAttachmentRequired = p.isAttachmentRequired ?? false;
    data.featured = p.featured == "1";
    data.requiresOtp = p.requiresOtp ?? false;
    data.warrantyPeriod = p.warrantyPeriod;
    data.guaranteePeriod = p.guaranteePeriod;
    data.tags = List<String>.from(p.tags);

    // Populate categoryLineage from CategoryHierarchyNode
    final List<int> lineage = [];
    CategoryHierarchyNode? currentNode = p.categoryHierarchyKey;
    while (currentNode != null) {
      lineage.add(currentNode.id);
      currentNode = currentNode.child;
    }
    data.categoryLineage = lineage;

    if (p.customFields != null) {
      data.customFields = p.customFields!.entries
          .map((e) => {'key': e.key, 'value': e.value.toString()})
          .toList();
    }

    emit(AddProductUpdating(data)); // Show initial UI with text fields

    // Now Cache Images
    if (p.mainImage.isNotEmpty) {
      final local = await ImagePickerUtils.downloadImageToFile(p.mainImage);
      if (local != null) {
        final currentData = state.productData;
        emit(AddProductUpdating(currentData.copyWith(mainImage: local)));
      }
    }

    if (p.additionalImages.isNotEmpty) {
      final List<String> cachedOther = [];
      for (var imgUrl in p.additionalImages) {
        final local = await ImagePickerUtils.downloadImageToFile(imgUrl);
        if (local != null) {
          cachedOther.add(local);
        } else {
          cachedOther.add(imgUrl); // Keep original if download fails
        }
      }
      final currentData = state.productData;
      emit(AddProductUpdating(currentData.copyWith(otherImages: cachedOther)));
    }

    if (p.productVideo != null && p.productVideo!.isNotEmpty) {
      final local = await ImagePickerUtils.downloadImageToFile(p.productVideo!);
      if (local != null) {
        final currentData = state.productData;
        emit(AddProductUpdating(currentData.copyWith(productVideo: local)));
      }
    }

    if (p.variants != null) {
      final Map<String, VariantData> uniqueVariants = {};
      final Set<int> uniqueStoreIds = {};

      for (var v in p.variants!) {
        final variantTitle = v.title ?? p.title;

        if (!uniqueVariants.containsKey(variantTitle)) {
          final vd = VariantData(
            title: variantTitle,
            attributeValueIds: [],
          );
          vd.id = v.id?.toString();
          vd.barcode = v.barcode;
          vd.weight = v.weight?.toString();
          vd.height = v.height?.toString();
          vd.length = v.length?.toString();
          vd.breadth = v.breadth?.toString();
          vd.isAvailable = v.availability ?? true;
          vd.isDefault = v.isDefault ?? false;
          vd.image = (v.image?.isNotEmpty == true) ? v.image : null;

          if (v.attributesMap != null) {
            vd.attributes = v.attributesMap!.entries.map((e) {
              final attr = p.productAttributes?.firstWhere(
                (pa) => pa.slug == e.key,
                orElse: () => ProductAttribute(name: e.key, slug: e.key),
              );
              return {
                "attribute_id": e.key,
                "value_id": e.value,
                "attribute_name": attr?.name ?? e.key,
                "value_name": e.value,
              };
            }).toList();
          } else if (v.variantAttributes != null) {
            vd.attributes = v.variantAttributes!
                .map(
                  (a) => {
                    "attribute_id": a.slug,
                    "value_id": a.values.isNotEmpty ? a.values.first : "",
                    "attribute_name": a.name,
                    "value_name": a.values.isNotEmpty ? a.values.first : "",
                  },
                )
                .toList();
          }

          uniqueVariants[variantTitle] = vd;
        }

        // Handle Store Pricing
        final storesList = v.stores ?? [];
        if (storesList.isEmpty && v.storeId != null) {
          storesList.add(
            VariantStore(
              storeId: v.storeId,
              storeName: v.storeName,
              sku: v.sku,
              price: v.price?.toDouble(),
              specialPrice: v.specialPrice?.toDouble(),
              stock: v.stock,
            ),
          );
        }

        for (var s in storesList) {
          if (s.storeId != null) {
            if (!uniqueStoreIds.contains(s.storeId)) {
              uniqueStoreIds.add(s.storeId!);
              data.storePricing.add(
                StorePricing(
                  storeId: s.storeId!,
                  storeName: s.storeName ?? "Store",
                  price: p.type == 'simple' ? s.price?.toString() : null,
                  specialPrice:
                      p.type == 'simple' ? s.specialPrice?.toString() : null,
                  cost: p.type == 'simple' ? s.cost?.toString() : null,
                  stock: p.type == 'simple' ? s.stock?.toString() : null,
                  sku: p.type == 'simple' ? s.sku : null,
                ),
              );
            } else if (p.type == 'simple') {
              final idx = data.storePricing.indexWhere(
                (sp) => sp.storeId == s.storeId,
              );
              if (idx != -1) {
                data.storePricing[idx] = data.storePricing[idx].copyWith(
                  price: s.price?.toString(),
                  specialPrice: s.specialPrice?.toString(),
                  stock: s.stock?.toString(),
                  sku: s.sku,
                );
              }
            }

            if (p.type == 'variant') {
              final vd = uniqueVariants[variantTitle]!;
              data.variantStorePricing.add(
                VariantStorePricing(
                  storeId: s.storeId!,
                  variantId: vd.id ?? "",
                  price: s.price?.toString(),
                  specialPrice: s.specialPrice?.toString(),
                  cost: s.cost?.toString(),
                  stock: s.stock?.toString(),
                  sku: s.sku,
                ),
              );
            }
          }
        }
      }
      data.variants = uniqueVariants.values.toList();
    }

    if (p.customProductSections != null) {
      data.customProductSections = p.customProductSections!.map((s) {
        return CustomProductSection(
          id: s.id,
          uuid: s.uuid,
          title: s.title,
          description: s.description,
          sortOrder: s.sortOrder,
          fields: s.fields.map((f) {
            return CustomProductField(
              id: f.id,
              uuid: f.uuid,
              title: f.title,
              description: f.description,
              image: (f.image?.isNotEmpty == true) ? f.image : null,
              sortOrder: f.sortOrder,
            );
          }).toList(),
        );
      }).toList();
    }

    emit(AddProductUpdating(data));

    // Now Cache Images
    if (p.mainImage.isNotEmpty) {
      final local = await ImagePickerUtils.downloadImageToFile(p.mainImage);
      if (local != null) {
        final currentData = state.productData;
        emit(AddProductUpdating(currentData.copyWith(mainImage: local)));
      }
    }

    if (p.additionalImages.isNotEmpty) {
      final List<String> cachedOther = [];
      for (var imgUrl in p.additionalImages) {
        final local = await ImagePickerUtils.downloadImageToFile(imgUrl);
        if (local != null) {
          cachedOther.add(local);
        } else {
          cachedOther.add(imgUrl); // Keep original if download fails
        }
      }
      final currentData = state.productData;
      emit(AddProductUpdating(currentData.copyWith(otherImages: cachedOther)));
    }

    if (p.productVideo != null && p.productVideo!.isNotEmpty) {
      final local = await ImagePickerUtils.downloadImageToFile(p.productVideo!);
      if (local != null) {
        final currentData = state.productData;
        emit(AddProductUpdating(currentData.copyWith(productVideo: local)));
      }
    }

    if (data.variants.isNotEmpty) {
      final currentVariants = List<VariantData>.from(state.productData.variants);
      bool anyVariantImageCached = false;

      for (int i = 0; i < currentVariants.length; i++) {
        final vd = currentVariants[i];
        if (vd.image != null && vd.image!.isNotEmpty && vd.image!.startsWith('http')) {
          final local = await ImagePickerUtils.downloadImageToFile(vd.image!);
          if (local != null) {
            currentVariants[i] = vd.copyWith(image: local);
            anyVariantImageCached = true;
          }
        }
      }

      if (anyVariantImageCached) {
        final currentData = state.productData;
        emit(
          AddProductUpdating(currentData.copyWith(variants: currentVariants)),
        );
      }
    }

    if (p.customProductSections != null) {
      final currentSections =
          List<CustomProductSection>.from(state.productData.customProductSections);
      bool anyCustomImageCached = false;

      for (int i = 0; i < currentSections.length; i++) {
        final section = currentSections[i];
        final newFields = List<CustomProductField>.from(section.fields);
        bool sectionModified = false;

        for (int j = 0; j < newFields.length; j++) {
          final field = newFields[j];
          if (field.image != null &&
              field.image!.isNotEmpty &&
              field.image!.startsWith('http')) {
            final local =
                await ImagePickerUtils.downloadImageToFile(field.image!);
            if (local != null) {
              newFields[j] = field.copyWith(image: local);
              sectionModified = true;
              anyCustomImageCached = true;
            }
          }
        }

        if (sectionModified) {
          currentSections[i] = section.copyWith(fields: newFields);
        }
      }

      if (anyCustomImageCached) {
        final currentData = state.productData;
        emit(AddProductUpdating(
            currentData.copyWith(customProductSections: currentSections)));
      }
    }
  }

  void _onReset(AddProductReset event, Emitter<AddProductState> emit) {
    emit(AddProductInitial());
  }

  void _onUpdateProductData(UpdateProductData event, Emitter<AddProductState> emit) {
    emit(AddProductUpdating(event.productData));
  }

  Future<void> _onSubmitProduct(SubmitProduct event, Emitter<AddProductState> emit) async {
    emit(AddProductSubmitting(state.productData));
    try {
      await _repo.addProduct(productData: state.productData);
      emit(AddProductSuccess(state.productData));
    } catch (e) {
      emit(AddProductFailure(state.productData, e.toString()));
    }
  }
}
