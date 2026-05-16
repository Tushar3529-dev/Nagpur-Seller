// ignore_for_file: deprecated_member_use

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/screen/more_page/view/attributes/bloc/attributes_bloc/attributes_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/attributes/model/attribute_values_model.dart'
    as values_model;
import 'package:hyper_local_seller/screen/more_page/view/attributes/model/attributes_model.dart'
    as attr_model;
import 'package:hyper_local_seller/screen/more_page/view/attributes/repo/attributes_repo.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/bloc/add_product_bloc/add_product_bloc.dart';
import 'package:hyper_local_seller/widgets/custom/custom_dropdown.dart';
import 'package:hyper_local_seller/widgets/custom/custom_textfield.dart';
import 'package:hyper_local_seller/utils/image_picker_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_upload_area.dart';
import 'package:hyper_local_seller/widgets/custom/custom_loading_indicator.dart';

class ProductVariationStep extends StatefulWidget {
  const ProductVariationStep({super.key});

  @override
  State<ProductVariationStep> createState() => _ProductVariationStepState();
}

class _ProductVariationStepState extends State<ProductVariationStep> {
  String _productType = 'simple'; // simple, variable
  final TextEditingController _barcodeController = TextEditingController();
  final AttributesRepo _attributesRepo = AttributesRepo();

  // When editing (or when returning to this step), rebuild the attribute selectors
  // from the already-loaded variants so the UI shows selected attributes/values.
  bool _didHydrateAttributeSelections = false;
  bool _isHydratingAttributeSelections = false;
  final List<attr_model.Attribute> _extraAvailableAttributes = [];

  // Dimensions Controllers (Simple)
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _breadthController = TextEditingController();
  final TextEditingController _lengthController = TextEditingController();

  // Dimensions Units (Simple)
  String _weightUnit = 'kg';
  String _heightUnit = 'cm';
  String _breadthUnit = 'cm';
  String _lengthUnit = 'cm';

  // Focus Nodes
  final FocusNode _barcodeFocus = FocusNode();
  final FocusNode _weightFocus = FocusNode();
  final FocusNode _heightFocus = FocusNode();
  final FocusNode _breadthFocus = FocusNode();
  final FocusNode _lengthFocus = FocusNode();

  // Variable Product Controllers
  final List<AttributeSelectionController> _attributeSelections = [];
  List<VariantController> _variantControllers = [];

  @override
  void initState() {
    super.initState();
    context.read<AttributesBloc>().add(LoadAttributesInitial());

    final productData = context.read<AddProductBloc>().state.productData;
    _productType = productData.type;
    _barcodeController.text = productData.barcode ?? "";

    if (_productType == 'simple' && productData.variants.isNotEmpty) {
      final v = productData.variants.first;
      if (_variantControllers.isEmpty) {
        _variantControllers.add(
          VariantController(
            id: v.id ?? "s_${DateTime.now().microsecondsSinceEpoch}",
            title: "simple_variant_placeholder",
            attributeValueIds: [],
          ),
        );
      }
      _variantControllers.first.weightController.text = v.weight ?? "";
      _variantControllers.first.heightController.text = v.height ?? "";
      _variantControllers.first.lengthController.text = v.length ?? "";
      _variantControllers.first.breadthController.text = v.breadth ?? "";

      // Populate local controllers for Simple UI
      _weightController.text = v.weight ?? "";
      _heightController.text = v.height ?? "";
      _lengthController.text = v.length ?? "";
      _breadthController.text = v.breadth ?? "";
    } else if (_productType == 'simple') {
      // Ensure at least one variant controller exists for simple product to hold price/stock
      if (_variantControllers.isEmpty) {
        _variantControllers.add(
          VariantController(
            id: "s_${DateTime.now().microsecondsSinceEpoch}",
            title: "simple_variant_placeholder",
            attributeValueIds: [],
          ),
        );
      }
    } else if (_productType == 'variant' && productData.variants.isNotEmpty) {
      // Reconstruct variant controllers
      _variantControllers = productData.variants.map((v) {
        final vc = VariantController(
          id: v.id ?? "v_${DateTime.now().millisecondsSinceEpoch}",
          title: v.title,
          attributeValueIds: v.attributeValueIds,
          attributes: v.attributes,
        );
        vc.nameController.text = v.title;
        vc.barcodeController.text = v.barcode ?? "";
        vc.weightController.text = v.weight ?? "";
        vc.heightController.text = v.height ?? "";
        vc.lengthController.text = v.length ?? "";
        vc.breadthController.text = v.breadth ?? "";
        vc.isAvailable = v.isAvailable;
        vc.isDefault = v.isDefault;
        vc.image = v.image;

        vc.nameController.addListener(_updateBloc);
        vc.barcodeController.addListener(_updateBloc);
        vc.weightController.addListener(_updateBloc);
        vc.heightController.addListener(_updateBloc);
        vc.lengthController.addListener(_updateBloc);
        vc.breadthController.addListener(_updateBloc);

        return vc;
      }).toList();
    }

    // Add listeners for simple product controllers
    _barcodeController.addListener(_updateBloc);
    _weightController.addListener(_updateBloc);
    _heightController.addListener(_updateBloc);
    _lengthController.addListener(_updateBloc);
    _breadthController.addListener(_updateBloc);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update simple variant titles if they have the placeholder
    for (var controller in _variantControllers) {
      if (controller.title == "simple_variant_placeholder") {
        controller.title =
            AppLocalizations.of(context)?.simpleVariantTitle ?? "Simple";
      }
    }
  }

  @override
  void dispose() {
    _barcodeController.removeListener(_updateBloc);
    _weightController.removeListener(_updateBloc);
    _heightController.removeListener(_updateBloc);
    _lengthController.removeListener(_updateBloc);
    _breadthController.removeListener(_updateBloc);

    _barcodeController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _breadthController.dispose();
    _lengthController.dispose();

    _barcodeFocus.dispose();
    _weightFocus.dispose();
    _heightFocus.dispose();
    _breadthFocus.dispose();
    _lengthFocus.dispose();

    for (var selection in _attributeSelections) {
      selection.dispose();
    }
    for (var controller in _variantControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addAttribute() {
    setState(() {
      _attributeSelections.add(
        AttributeSelectionController(onChanged: _generateVariantsAuto),
      );
    });
  }

  static String _norm(String s) => s.trim().toLowerCase();

  static attr_model.Attribute? _findAttributeById(
    List<attr_model.Attribute> items,
    int id,
  ) {
    for (final a in items) {
      if (a.id == id) return a;
    }
    return null;
  }

  static attr_model.Attribute? _findAttributeBySlug(
    List<attr_model.Attribute> items,
    String slug,
  ) {
    final target = _norm(slug);
    for (final a in items) {
      if (_norm(a.slug) == target) return a;
    }
    return null;
  }

  static attr_model.Attribute? _findAttributeByTitle(
    List<attr_model.Attribute> items,
    String title,
  ) {
    final target = _norm(title);
    for (final a in items) {
      if (_norm(a.title) == target) return a;
    }
    return null;
  }

  List<attr_model.Attribute> _mergeAvailableAttributes(
    List<attr_model.Attribute> fromBloc,
  ) {
    final merged = <attr_model.Attribute>[...fromBloc];
    for (final a in _extraAvailableAttributes) {
      final exists = merged.any((x) => x.id == a.id);
      if (!exists) merged.add(a);
    }
    return merged;
  }

  void _maybeHydrateAttributeSelections(List<attr_model.Attribute> allAttributes) {
    if (_didHydrateAttributeSelections || _isHydratingAttributeSelections) return;
    if (_productType != 'variant') {
      _didHydrateAttributeSelections = true;
      return;
    }

    if (_attributeSelections.isNotEmpty) {
      _didHydrateAttributeSelections = true;
      return;
    }

    // Nothing to hydrate if there are no variants/attributes yet.
    final hasAnyAttrMappings = _variantControllers.any(
      (v) => v.attributes.isNotEmpty,
    );
    if (_variantControllers.isEmpty || !hasAnyAttrMappings) {
      _didHydrateAttributeSelections = true;
      return;
    }

    _isHydratingAttributeSelections = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _hydrateAttributeSelectionsFromVariants(allAttributes);
    });
  }

  Future<void> _hydrateAttributeSelectionsFromVariants(
    List<attr_model.Attribute> allAttributes,
  ) async {
    try {
      final aggregates = <String, _VariantAttributeAggregate>{};

      for (final vc in _variantControllers) {
        for (final raw in vc.attributes) {
          final rawAttrId = raw['attribute_id'];
          final rawAttrName = raw['attribute_name'];
          final rawValueId = raw['value_id'];
          final rawValueName = raw['value_name'];

          int? attrId;
          String? attrSlug;
          if (rawAttrId is int) {
            attrId = rawAttrId;
          } else if (rawAttrId is String) {
            final parsed = int.tryParse(rawAttrId);
            if (parsed != null) {
              attrId = parsed;
            } else if (rawAttrId.trim().isNotEmpty) {
              attrSlug = rawAttrId;
            }
          } else if (rawAttrId != null) {
            final asString = rawAttrId.toString();
            final parsed = int.tryParse(asString);
            if (parsed != null) {
              attrId = parsed;
            } else if (asString.trim().isNotEmpty) {
              attrSlug = asString;
            }
          }

          String attrName = (rawAttrName ?? '').toString().trim();
          if (attrName.isEmpty) {
            if (attrId != null) {
              attrName = _findAttributeById(allAttributes, attrId)?.title ?? "";
            } else if (attrSlug != null) {
              attrName =
                  _findAttributeBySlug(allAttributes, attrSlug)?.title ?? "";
            }
          }

          int? valueId;
          String? valueTitle;
          if (rawValueId is int) {
            valueId = rawValueId;
          } else if (rawValueId is String) {
            final parsed = int.tryParse(rawValueId);
            if (parsed != null) {
              valueId = parsed;
            } else if (rawValueId.trim().isNotEmpty) {
              valueTitle = rawValueId;
            }
          } else if (rawValueId != null) {
            final asString = rawValueId.toString();
            final parsed = int.tryParse(asString);
            if (parsed != null) {
              valueId = parsed;
            } else if (asString.trim().isNotEmpty) {
              valueTitle = asString;
            }
          }

          if (rawValueName != null &&
              rawValueName.toString().trim().isNotEmpty) {
            valueTitle = rawValueName.toString();
          }

          final key = attrId != null
              ? 'id:$attrId'
              : (attrSlug != null ? 'slug:${_norm(attrSlug)}' : null);
          if (key == null) continue;

          final agg = aggregates.putIfAbsent(
            key,
            () => _VariantAttributeAggregate(
              attrId: attrId,
              attrSlug: attrSlug,
              attrName: attrName,
            ),
          );

          if (valueId != null) agg.valueIds.add(valueId);
          if (valueTitle != null && valueTitle.trim().isNotEmpty) {
            agg.valueTitles.add(valueTitle.trim());
          }
        }
      }

      if (aggregates.isEmpty) return;

      final selections = <AttributeSelectionController>[];

      // Index for variant normalization.
      final Map<int, Map<int, values_model.AttributeValue>> valuesById = {};
      final Map<int, Map<String, values_model.AttributeValue>> valuesByTitle = {};

      for (final agg in aggregates.values) {
        attr_model.Attribute? attribute;

        if (agg.attrId != null) {
          attribute = _findAttributeById(allAttributes, agg.attrId!);
        }

        if (attribute == null && agg.attrSlug != null) {
          attribute = _findAttributeBySlug(allAttributes, agg.attrSlug!);
        }

        if (attribute == null && agg.attrName.trim().isNotEmpty) {
          attribute = _findAttributeByTitle(allAttributes, agg.attrName);
        }

        // Fallback: attribute not in first page of AttributesBloc results.
        if (attribute == null) {
          final query = (agg.attrSlug ?? agg.attrName).trim();
          if (query.isNotEmpty) {
            try {
              final resp = await _attributesRepo.getAttributes(
                page: 1,
                perPage: 100,
                search: query,
              );
              final parsed = attr_model.AttributesResponse.fromJson(resp);
              final items = parsed.data?.attributes ?? [];
              if (items.isNotEmpty) {
                attribute = (agg.attrSlug != null)
                    ? _findAttributeBySlug(items, agg.attrSlug!)
                    : null;
                attribute ??=
                    _findAttributeByTitle(items, agg.attrName.trim());
                attribute ??= items.first;
              }
            } catch (_) {
              // ignore
            }
          }
        }

        if (attribute == null) continue;

        // Ensure dropdown can render this attribute even if it's not in Bloc's
        // first page.
        final attrId = attribute.id;
        final alreadyInAll = allAttributes.any((a) => a.id == attrId);
        if (!alreadyInAll) {
          final exists =
              _extraAvailableAttributes.any((a) => a.id == attrId);
          if (!exists) _extraAvailableAttributes.add(attribute);
        }

        final controller =
            AttributeSelectionController(onChanged: _generateVariantsAuto);
        controller.selectedAttributeId = attribute.id;
        controller.selectedAttributeName = attribute.title;

        try {
          final response = await _attributesRepo.getAttributeValues(attribute.id);
          final valuesResponse =
              values_model.AttributeValuesResponse.fromJson(response);
          controller.availableValues = valuesResponse.data?.values ?? [];

          // Selected by id (preferred) or by title.
          controller.selectedValues = controller.availableValues.where((v) {
            if (agg.valueIds.contains(v.id)) return true;
            if (agg.valueTitles.isEmpty) return false;
            final t = _norm(v.title);
            for (final wanted in agg.valueTitles) {
              if (_norm(wanted) == t) return true;
            }
            return false;
          }).toList();

          valuesById[attribute.id] = {
            for (final v in controller.availableValues) v.id: v,
          };
          valuesByTitle[attribute.id] = {
            for (final v in controller.availableValues) _norm(v.title): v,
          };
        } catch (_) {
          // ignore fetch failures; UI will still show the attribute selector.
        }

        selections.add(controller);
      }

      if (!mounted) return;

      // Update local UI state.
      setState(() {
        _attributeSelections
          ..clear()
          ..addAll(selections);
      });

      // Normalize variants so future auto-generation can preserve existing
      // variants by attributeValueIds.
      final allAttrsNow = _mergeAvailableAttributes(allAttributes);
      final Map<String, int> attrIdBySlug = {
        for (final a in allAttrsNow) _norm(a.slug): a.id,
      };
      final Map<int, String> attrNameById = {
        for (final a in allAttrsNow) a.id: a.title,
      };

      bool anyVariantUpdated = false;

      for (final vc in _variantControllers) {
        if (vc.attributes.isEmpty) continue;

        final newIds = <int>[];
        final newAttrs = <Map<String, dynamic>>[];

        for (final raw in vc.attributes) {
          final rawAttrId = raw['attribute_id'];

          int? attrId;
          if (rawAttrId is int) {
            attrId = rawAttrId;
          } else if (rawAttrId is String) {
            final parsed = int.tryParse(rawAttrId);
            if (parsed != null) {
              attrId = parsed;
            } else {
              attrId = attrIdBySlug[_norm(rawAttrId)];
            }
          } else if (rawAttrId != null) {
            final asString = rawAttrId.toString();
            final parsed = int.tryParse(asString);
            if (parsed != null) {
              attrId = parsed;
            } else {
              attrId = attrIdBySlug[_norm(asString)];
            }
          }

          if (attrId == null) {
            final rawAttrName = raw['attribute_name'];
            final attrName = (rawAttrName ?? '').toString().trim();
            if (attrName.isNotEmpty) {
              attrId = _findAttributeByTitle(allAttrsNow, attrName)?.id;
            }
          }

          if (attrId == null) continue;

          values_model.AttributeValue? value;

          final rawValueId = raw['value_id'];
          if (rawValueId is int) {
            value = valuesById[attrId]?[rawValueId];
          } else if (rawValueId is String) {
            final parsed = int.tryParse(rawValueId);
            if (parsed != null) {
              value = valuesById[attrId]?[parsed];
            }
          } else if (rawValueId != null) {
            final asString = rawValueId.toString();
            final parsed = int.tryParse(asString);
            if (parsed != null) {
              value = valuesById[attrId]?[parsed];
            }
          }

          if (value == null) {
            final rawValueName = raw['value_name'] ?? raw['value_id'];
            final valueName = (rawValueName ?? '').toString().trim();
            if (valueName.isNotEmpty) {
              value = valuesByTitle[attrId]?[_norm(valueName)];
            }
          }

          if (value == null) continue;

          newIds.add(value.id);
          newAttrs.add({
            "attribute_id": attrId,
            "value_id": value.id,
            "attribute_name": attrNameById[attrId] ?? raw['attribute_name'] ?? "",
            "value_name": value.title,
          });
        }

        if (newIds.isNotEmpty &&
            (vc.attributeValueIds.isEmpty || vc.attributes != newAttrs)) {
          vc.attributeValueIds = newIds;
          if (newAttrs.isNotEmpty) vc.attributes = newAttrs;
          anyVariantUpdated = true;
        }
      }

      if (anyVariantUpdated) {
        setState(() {});
        _updateBloc();
      }
    } finally {
      _didHydrateAttributeSelections = true;
      _isHydratingAttributeSelections = false;
    }
  }

  void _removeAttribute(int index) {
    setState(() {
      _attributeSelections[index].dispose();
      _attributeSelections.removeAt(index);
      _generateVariantsAuto();
    });
  }

  void _updateBloc() {
    if (!mounted) return;
    final bloc = context.read<AddProductBloc>();
    final currentData = bloc.state.productData;

    // Sync local dimensions for Simple product to the single variant
    if (_productType == 'simple' && _variantControllers.isNotEmpty) {
      final v = _variantControllers.first;
      v.barcodeController.text = _barcodeController.text;
      v.weightController.text = _weightController.text;
      v.heightController.text = _heightController.text;
      v.lengthController.text = _lengthController.text;
      v.breadthController.text = _breadthController.text;
    }

    final variants = _variantControllers
        .map(
          (vc) => VariantData(
            id: vc.id,
            title: vc.title,
            name: vc.nameController.text,
            attributeValueIds: vc.attributeValueIds,
            attributes: vc.attributes,
            barcode: vc.barcodeController.text,
            weight: vc.weightController.text,
            height: vc.heightController.text,
            length: vc.lengthController.text,
            breadth: vc.breadthController.text,
            isAvailable: vc.isAvailable,
            isDefault: vc.isDefault,
            image: vc.image,
          ),
        )
        .toList();

    bloc.add(
      UpdateProductData(
        currentData.copyWith(
          type: _productType,
          barcode: _barcodeController.text,
          variants: variants,
        ),
      ),
    );
  }

  void _generateVariantsAuto() {
    // Collect all selected values and their names for each attribute
    final List<List<values_model.AttributeValue>> allOptions = [];
    final List<String> attributeNames = [];
    for (var selection in _attributeSelections) {
      if (selection.selectedValues.isNotEmpty) {
        allOptions.add(selection.selectedValues);
        attributeNames.add(selection.selectedAttributeName ?? "");
      }
    }

    if (allOptions.isEmpty) {
      setState(() {
        _variantControllers = [];
      });
      _updateBloc();
      return;
    }

    // Cartesian product of allOptions
    final List<List<values_model.AttributeValue>> cartesian =
        _getCartesianProduct(allOptions);

    final List<VariantController> newVariants = [];
    for (int i = 0; i < cartesian.length; i++) {
      final combo = cartesian[i];
      final title = combo.map((v) => v.title).join(", ");
      final ids = combo.map((v) => v.id).toList();

      // Try to find existing variant to preserve data
      final existingIndex = _variantControllers.indexWhere(
        (v) =>
            v.attributeValueIds.length == ids.length &&
            v.attributeValueIds.every((id) => ids.contains(id)),
      );

      if (existingIndex != -1) {
        newVariants.add(_variantControllers[existingIndex]);
      } else {
        final id = "v_${DateTime.now().microsecondsSinceEpoch}_$i";
        // Map to standard detailed attribute structure
        final attributesMapping = List.generate(combo.length, (j) {
          final cv = combo[j];
          return {
            "attribute_id": cv.globalAttributeId,
            "value_id": cv.id,
            "attribute_name": attributeNames[j],
            "value_name": cv.title,
          };
        }).toList();

        final v = VariantController(
          id: id,
          title: title,
          attributeValueIds: ids,
          attributes: attributesMapping,
        );
        v.barcodeController.addListener(_updateBloc);
        v.weightController.addListener(_updateBloc);
        v.heightController.addListener(_updateBloc);
        v.lengthController.addListener(_updateBloc);
        v.breadthController.addListener(_updateBloc);
        newVariants.add(v);
      }
    }

    setState(() {
      _variantControllers = newVariants;
    });
    _updateBloc();
  }

  List<List<T>> _getCartesianProduct<T>(List<List<T>> lists) {
    List<List<T>> result = [[]];
    for (var list in lists) {
      List<List<T>> temp = [];
      for (var prefix in result) {
        for (var item in list) {
          temp.add([...prefix, item]);
        }
      }
      result = temp;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomDropdown<String>(
          label: AppLocalizations.of(context)!.productType,
          isRequired: true,
          value: _productType,
          items: [
            CustomDropdownItem(
              label: AppLocalizations.of(context)!.simpleProduct,
              value: "simple",
            ),
            CustomDropdownItem(
              label: AppLocalizations.of(context)!.variableProduct,
              value: "variant",
            ),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() {
                final previousType = _productType;
                _productType = val;

                if (_productType == 'simple' && _variantControllers.isEmpty) {
                  // Create Simple variant only when switching TO simple
                  _variantControllers.add(
                    VariantController(
                      id: 's_${DateTime.now().microsecondsSinceEpoch}',
                      title:
                          AppLocalizations.of(context)?.simpleVariantTitle ??
                          "Simple",
                      attributeValueIds: [],
                    ),
                  );
                } else if (_productType == 'variant' &&
                    previousType == 'simple') {
                  // Clear variants when switching FROM simple TO variant
                  for (var vc in _variantControllers) {
                    vc.dispose();
                  }
                  _variantControllers = [];
                  // Also clear attribute selections
                  for (var selection in _attributeSelections) {
                    selection.dispose();
                  }
                  _attributeSelections.clear();
                }
              });
              _updateBloc();
            }
          },
        ),
        const SizedBox(height: 20),

        if (_productType == 'simple') _buildSimpleProductUI(),
        if (_productType == 'variant') _buildVariableProductUI(),
      ],
    );
  }

  Widget _buildSimpleProductUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          label: AppLocalizations.of(context)!.barcode,
          isRequired: true,
          hint: AppLocalizations.of(context)!.enterBarcode,
          focusNode: _barcodeFocus,
          controller: _barcodeController,
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: _buildDimensionField(
                AppLocalizations.of(context)!.weight,
                _weightController,
                _weightFocus,
                _weightUnit,
                (v) {
                  setState(() => _weightUnit = v!);
                  _updateBloc();
                },
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildDimensionField(
                AppLocalizations.of(context)!.height,
                _heightController,
                _heightFocus,
                _heightUnit,
                (v) {
                  setState(() => _heightUnit = v!);
                  _updateBloc();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _buildDimensionField(
                AppLocalizations.of(context)!.length,
                _lengthController,
                _lengthFocus,
                _lengthUnit,
                (v) {
                  setState(() => _lengthUnit = v!);
                  _updateBloc();
                },
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildDimensionField(
                AppLocalizations.of(context)!.breadth,
                _breadthController,
                _breadthFocus,
                _breadthUnit,
                (v) {
                  setState(() => _breadthUnit = v!);
                  _updateBloc();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDimensionField(
    String label,
    TextEditingController controller,
    FocusNode focusNode,
    String unit,
    ValueChanged<String?> onUnitChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.tertiary,
              fontSize: 14,
            ),
            children: const [
              TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: CustomTextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _updateBloc(),
                  hint: "0",
                ),
              ),

              Expanded(
                flex: 1,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: unit,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.tertiary,
                      fontSize: 13,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    items: ["kg", "g", "cm", "m"]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: onUnitChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVariableProductUI() {
    return BlocBuilder<AttributesBloc, AttributesState>(
      builder: (context, attributesState) {
        final isLoadingAttributes = attributesState.isInitialLoading;
        final availableAttributes =
            _mergeAvailableAttributes(attributesState.items);

        if (!isLoadingAttributes) {
          _maybeHydrateAttributeSelections(availableAttributes);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.attributes,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (!isLoadingAttributes)
                  OutlinedButton.icon(
                    onPressed: _addAttribute,
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(AppLocalizations.of(context)!.addAttribute),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryColor,
                      side: const BorderSide(color: AppColors.primaryColor),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  )
                else
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CustomLoadingIndicator(size: 20, strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            ..._attributeSelections.asMap().entries.map((entry) {
              int index = entry.key;
              var controller = entry.value;
              return _buildAttributeSelector(
                index,
                controller,
                availableAttributes,
              );
            }),
            const SizedBox(height: 25),
            Text(
              "${AppLocalizations.of(context)!.productVariants} (${_variantControllers.length})",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 10),
            ..._variantControllers.asMap().entries.map((entry) {
              return _buildVariantTile(entry.key, entry.value);
            }),
          ],
        );
      },
    );
  }

  Widget _buildAttributeSelector(
    int index,
    AttributeSelectionController controller,
    List<attr_model.Attribute> availableAttributes,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${AppLocalizations.of(context)!.attribute} ${index + 1}",
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 20,
                ),
                onPressed: () => _removeAttribute(index),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          CustomDropdown<int>(
            label: AppLocalizations.of(context)!.attribute,
            isRequired: true,
            hint: AppLocalizations.of(context)!.selectAttribute,
            value: controller.selectedAttributeId,
            items: availableAttributes
                .map(
                  (attr) =>
                      CustomDropdownItem(label: attr.title, value: attr.id),
                )
                .toList(),
            onChanged: (val) async {
              if (val != null) {
                controller.selectedAttributeId = val;
                controller.selectedAttributeName =
                    _findAttributeById(availableAttributes, val)?.title ??
                    controller.selectedAttributeName;
                controller.selectedValues = [];
                controller.availableValues = [];
                setState(() {});

                // Fetch values
                try {
                  final response = await _attributesRepo.getAttributeValues(
                    val,
                  );
                  final valuesResponse =
                      values_model.AttributeValuesResponse.fromJson(response);
                  controller.availableValues =
                      valuesResponse.data?.values ?? [];
                  setState(() {});
                } catch (e) {
                  // Handle error
                }
              }
            },
          ),
          if (controller.selectedAttributeId != null) ...[
            const SizedBox(height: 15),
            Text(
              AppLocalizations.of(context)!.values,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: controller.availableValues.map((val) {
                final isSelected = controller.selectedValues.any(
                  (v) => v.id == val.id,
                );
                return FilterChip(
                  label: Text(val.title),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        controller.selectedValues.add(val);
                      } else {
                        controller.selectedValues.removeWhere(
                          (v) => v.id == val.id,
                        );
                      }
                      _generateVariantsAuto();
                    });
                  },
                  selectedColor: AppColors.primaryColor.withValues(alpha: 0.2),
                  checkmarkColor: AppColors.primaryColor,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVariantTile(int index, VariantController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        title: Text(
          controller.title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
        trailing: const Icon(Icons.keyboard_arrow_down),
        showTrailingIcon: true,
        childrenPadding: const EdgeInsets.all(12),
        children: [
          CustomTextField(
            label: AppLocalizations.of(context)!.variantName,
            hint: AppLocalizations.of(context)!.enterName,
            isRequired: true,
            controller: controller.nameController,
          ),
          const SizedBox(height: 15),
          CustomTextField(
            label: AppLocalizations.of(context)!.barcode,
            hint: "123456",
            isRequired: true,
            controller: controller.barcodeController,
            focusNode: controller.barcodeFocus,
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildDimensionField(
                  AppLocalizations.of(context)!.weight,
                  controller.weightController,
                  controller.weightFocus,
                  "kg",
                  (v) {},
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDimensionField(
                  AppLocalizations.of(context)!.height,
                  controller.heightController,
                  controller.heightFocus,
                  "cm",
                  (v) {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildDimensionField(
                  AppLocalizations.of(context)!.length,
                  controller.lengthController,
                  controller.lengthFocus,
                  "cm",
                  (v) {},
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDimensionField(
                  AppLocalizations.of(context)!.breadth,
                  controller.breadthController,
                  controller.breadthFocus,
                  "cm",
                  (v) {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              AppLocalizations.of(context)!.availability,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            value: controller.isAvailable,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primaryColor,
            onChanged: (v) {
              setState(() => controller.isAvailable = v);
              _updateBloc();
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              AppLocalizations.of(context)!.setAsDefaultVariant,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            value: controller.isDefault,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primaryColor,
            onChanged: (v) {
              setState(() {
                if (v) {
                  // Only one can be default
                  for (var vc in _variantControllers) {
                    vc.isDefault = false;
                  }
                }
                controller.isDefault = v;
              });
              _updateBloc();
            },
          ),
          const SizedBox(height: 15),
          Text(
            AppLocalizations.of(context)!.variantImage,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          CustomUploadArea(
            hint: AppLocalizations.of(context)!.uploadVariantImage,
            fileName: controller.image,
            height: 100,
            onTap: () async {
              final path = await ImagePickerUtils.pickMedia(
                context,
                mediaType: MediaType.image,
              );
              if (path != null) {
                setState(() => controller.image = path);
                _updateBloc();
              }
            },
            onRemove: () {
              setState(() => controller.image = null);
              _updateBloc();
            },
          ),
        ],
      ),
    );
  }
}

// Helper Classes for Controllers
class _VariantAttributeAggregate {
  final int? attrId;
  final String? attrSlug;
  final String attrName;
  final Set<int> valueIds = {};
  final Set<String> valueTitles = {};

  _VariantAttributeAggregate({
    required this.attrId,
    required this.attrSlug,
    required this.attrName,
  });
}

class AttributeSelectionController {
  int? selectedAttributeId;
  String? selectedAttributeName;
  List<values_model.AttributeValue> availableValues = [];
  List<values_model.AttributeValue> selectedValues = [];
  final VoidCallback onChanged;

  AttributeSelectionController({required this.onChanged});

  void dispose() {}
}

class VariantController {
  String id;

  String title;
  List<int> attributeValueIds;
  List<Map<String, dynamic>> attributes;
  final TextEditingController nameController = TextEditingController(); // Added
  final TextEditingController barcodeController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController breadthController = TextEditingController();
  final TextEditingController lengthController = TextEditingController();

  final FocusNode barcodeFocus = FocusNode();
  final FocusNode weightFocus = FocusNode();
  final FocusNode heightFocus = FocusNode();
  final FocusNode breadthFocus = FocusNode();
  final FocusNode lengthFocus = FocusNode();

  bool isAvailable = true;
  bool isDefault = false;
  String? image;

  VariantController({
    required this.id,
    required this.title,
    required this.attributeValueIds,
    this.attributes = const [],
    this.image,
  });

  void dispose() {
    nameController.dispose();
    barcodeController.dispose();
    weightController.dispose();
    heightController.dispose();
    breadthController.dispose();
    lengthController.dispose();

    barcodeFocus.dispose();
    weightFocus.dispose();
    heightFocus.dispose();
    breadthFocus.dispose();
    lengthFocus.dispose();
  }
}

// Dashed Painter for consistency
class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedRectPainter({
    this.color = Colors.grey,
    this.strokeWidth = 1.0,
    this.gap = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    Path path = Path();
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(8),
      ),
    );

    double dashWidth = 5, dashSpace = 5;
    final Path dashedPath = Path();
    for (PathMetric measurePath in path.computeMetrics()) {
      double distance = 0;
      while (distance < measurePath.length) {
        dashedPath.addPath(
          measurePath.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
