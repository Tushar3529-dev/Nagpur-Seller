// ignore_for_file: deprecated_member_use

import 'dart:developer';
import 'package:hyper_local_seller/l10n/app_localizations.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/attributes/model/attributes_model.dart'
    as attr_model;
import 'package:hyper_local_seller/screen/more_page/view/attributes/model/attribute_values_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/attributes/bloc/attribute_values_bloc/attribute_values_bloc.dart';
import 'package:hyper_local_seller/service/demo_guard.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';
import 'package:hyper_local_seller/widgets/custom/custom_textfield.dart';
import 'package:hyper_local_seller/widgets/custom/custom_buttons.dart';
import 'package:hyper_local_seller/bloc/screen_size/screen_size_bloc.dart';
import 'package:hyper_local_seller/widgets/custom/custom_upload_area.dart';
import 'package:hyper_local_seller/widgets/custom/image_source_sheet.dart';
import 'package:image_picker/image_picker.dart';

class AddAttributeValueDialog extends StatefulWidget {
  final attr_model.Attribute attribute;
  final AttributeValue? value;

  const AddAttributeValueDialog({
    super.key,
    required this.attribute,
    this.value,
  });

  @override
  State<AddAttributeValueDialog> createState() =>
      _AddAttributeValueDialogState();
}

class _AddAttributeValueDialogState extends State<AddAttributeValueDialog> {
  final _formKey = GlobalKey<FormState>();
  final List<ValueRowController> _rows = [];

  @override
  void initState() {
    super.initState();
    if (widget.value != null) {
      _rows.add(
        ValueRowController(
          value: widget.value!.title,
          swatch: widget.value!.swatcheValue,
        ),
      );
    } else {
      _rows.add(ValueRowController());
    }
  }

  @override
  void dispose() {
    for (var row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  void _addRow() {
    setState(() {
      _rows.add(ValueRowController());
    });
  }

  void _removeRow(int index) {
    if (_rows.length > 1) {
      setState(() {
        _rows[index].dispose();
        _rows.removeAt(index);
      });
    }
  }

  // ==================== NEW: Duplicate Check ====================
  String? _validateNoDuplicates() {
    final values = _rows
        .map((row) => row.valueController.text.trim())
        .where((v) => v.isNotEmpty)
        .toList();

    final seen = <String>{};
    for (final value in values) {
      if (!seen.add(value.toLowerCase())) {
        return "Duplicate value detected: '$value'. Each value must be unique.";
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final screenType = context.read<ScreenSizeBloc>().state.screenType;
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.value == null
                        ? l10n?.addValue ?? "Create New Attribute Value"
                        : "${l10n?.update ?? 'Edit'} ${l10n?.value ?? 'Value'}",
                    style: TextStyle(
                      fontSize: UIUtils.body(screenType),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              SizedBox(height: UIUtils.gapMD(screenType)),
              Text(
                "${l10n?.attribute ?? "Attribute"}: ${widget.attribute.title}",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: UIUtils.body(screenType),
                ),
              ),
              SizedBox(height: UIUtils.gapMD(screenType)),
              ..._rows.asMap().entries.map((entry) {
                int index = entry.key;
                ValueRowController row = entry.value;

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${l10n?.attribute} ${l10n?.value} #${index + 1}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_rows.length > 1)
                                TextButton.icon(
                                  onPressed: () => _removeRow(index),
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.red,
                                    size: 16,
                                  ),
                                  label: Text(
                                    l10n?.remove ?? "Remove",
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const Divider(),
                          CustomTextField(
                            label: l10n?.value,
                            controller: row.valueController,
                            hint: "e.g., Red",
                            isRequired: true,
                            validator: (v) =>
                                v!.isEmpty ? l10n?.fieldRequired : null,
                          ),
                          SizedBox(height: UIUtils.gapMD(screenType)),
                          if (widget.attribute.swatcheType == 'image')
                            CustomUploadArea(
                              hint: AppLocalizations.of(
                                context,
                              )!.selectSwatchImage,
                              fileName: row.imagePath,
                              icon: Icons.image_outlined,
                              onTap: () => _pickImage(row),
                              onRemove: () =>
                                  setState(() => row.imagePath = null),
                            )
                          else
                            CustomTextField(
                              label: l10n?.swatchValue,
                              controller: row.swatchController,
                              hint: widget.attribute.swatcheType == 'color'
                                  ? "e.g., #FF0000"
                                  : l10n?.enterSwatch ?? "Enter swatch",
                              isRequired: true,
                              validator: (v) =>
                                  v!.isEmpty ? l10n?.fieldRequired : null,
                              suffixIcon:
                                  widget.attribute.swatcheType == 'color'
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.color_lens_outlined,
                                      ),
                                      onPressed: () =>
                                          _showColorPicker(row, l10n),
                                    )
                                  : null,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              }),
              if (widget.value == null)
                SecondaryButton(
                  text: l10n?.addMoreValues ?? "Add More Values",
                  onPressed: _addRow,
                  width: double.infinity,
                ),
              SizedBox(height: UIUtils.gapLG(screenType)),
              PrimaryButton(
                text: widget.value == null
                    ? l10n?.addValue ?? "Add value"
                    : "${l10n?.update ?? "Edit"} ${l10n?.value ?? "Value"}",
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ValueRowController row) async {
    final ImageSourceType? source = await showModalBottomSheet<ImageSourceType>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const ImageSourceSheet(),
    );

    if (source != null) {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source == ImageSourceType.camera
            ? ImageSource.camera
            : ImageSource.gallery,
      );

      if (image != null) {
        setState(() {
          row.imagePath = image.path;
        });
      }
    }
  }

  void _showColorPicker(ValueRowController row, AppLocalizations? l10n) {
    final List<Color> colors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
      Colors.blueGrey,
      Colors.black,
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.selectColor ?? "Select Color"),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: colors.length,
            itemBuilder: (context, index) {
              final color = colors[index];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    row.swatchController.text =
                        '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
                  });
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final duplicateError = _validateNoDuplicates();
      if (duplicateError != null) {
        showCustomSnackbar(
          context: context,
          message: duplicateError,
          isError: true,
        );
        return;
      }

      if (widget.value == null) {
        final List<String> values = _rows
            .map((row) => row.valueController.text)
            .toList();
        final List<String> swatches = _rows.map((row) {
          if (widget.attribute.swatcheType == 'image') {
            return row.imagePath ?? "";
          } else {
            return row.swatchController.text;
          }
        }).toList();

        final data = {
          "attribute_id": widget.attribute.id,
          "values": values,
          "swatche_value": swatches,
          "swatche_type": widget.attribute.swatcheType,
        };

        if (!DemoGuard.shouldProceed(context)) {
          Navigator.pop(context);
          return;
        }

        context.read<AttributeValuesBloc>().add(
          AddAttributeValue(widget.attribute.id, data),
        );
      } else {
        final data = {
          "attribute_id": widget.attribute.id,
          "values": [_rows[0].valueController.text],
          "swatche_value": [
            widget.attribute.swatcheType == 'image'
                ? (_rows[0].imagePath ?? "")
                : _rows[0].swatchController.text,
          ],
          "swatche_type": widget.attribute.swatcheType,
        };
        if (!DemoGuard.shouldProceed(context)) {
          Navigator.pop(context);
          return;
        }

        context.read<AttributeValuesBloc>().add(
          UpdateAttributeValue(widget.attribute.id, widget.value!.id, data),
        );
      }
      Navigator.pop(context);
    }
  }
}

class ValueRowController {
  final TextEditingController valueController;
  final TextEditingController swatchController;
  String? imagePath;

  ValueRowController({String? value, String? swatch})
    : valueController = TextEditingController(text: value),
      swatchController = TextEditingController(text: swatch),
      imagePath = swatch != null && swatch.startsWith('http') ? null : swatch;

  void dispose() {
    valueController.dispose();
    swatchController.dispose();
  }
}
