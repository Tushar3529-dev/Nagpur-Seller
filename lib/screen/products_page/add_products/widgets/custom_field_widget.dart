import 'package:flutter/material.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/bloc/add_product_bloc/add_product_bloc.dart';
import 'package:hyper_local_seller/utils/image_picker_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_textfield.dart';
import 'package:hyper_local_seller/widgets/custom/custom_upload_area.dart';

class CustomProductFieldWidget extends StatefulWidget {
  final int sectionIndex;
  final int fieldIndex;
  final CustomProductField field;
  final VoidCallback onRemove;
  final Function(CustomProductField) onChanged;

  const CustomProductFieldWidget({
    super.key,
    required this.sectionIndex,
    required this.fieldIndex,
    required this.field,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<CustomProductFieldWidget> createState() =>
      _CustomProductFieldWidgetState();
}

class _CustomProductFieldWidgetState extends State<CustomProductFieldWidget> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _sortOrderController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.field.title);
    _descriptionController =
        TextEditingController(text: widget.field.description);
    _sortOrderController =
        TextEditingController(text: widget.field.sortOrder.toString());
  }

  @override
  void didUpdateWidget(CustomProductFieldWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.field.title != _titleController.text) {
      _titleController.text = widget.field.title ?? "";
    }
    if (widget.field.description != _descriptionController.text) {
      _descriptionController.text = widget.field.description ?? "";
    }
    if (widget.field.sortOrder.toString() != _sortOrderController.text) {
      _sortOrderController.text = widget.field.sortOrder.toString();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha:0.05),
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
                "Field #${widget.fieldIndex + 1}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              TextButton(
                onPressed: widget.onRemove,
                child: const Text("Remove", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    CustomTextField(
                      label: AppLocalizations.of(context)!.title,
                      hint: "Enter title",
                      controller: _titleController,
                      onChanged: (val) =>
                          widget.onChanged(widget.field.copyWith(title: val)),
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: AppLocalizations.of(context)!.shortDescription,
                      hint: "Enter description",
                      controller: _descriptionController,
                      onChanged: (val) => widget.onChanged(
                          widget.field.copyWith(description: val)),
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: "Sort Order",
                      hint: "0",
                      keyboardType: TextInputType.number,
                      controller: _sortOrderController,
                      onChanged: (val) => widget.onChanged(
                        widget.field
                            .copyWith(sortOrder: int.tryParse(val) ?? 0),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Image",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CustomUploadArea(
                      height: 120,
                      hint: "Browse",
                      fileName: widget.field.image,
                      onTap: () async {
                        final path = await ImagePickerUtils.pickMedia(
                          context,
                          mediaType: MediaType.image,
                        );
                        if (path != null) {
                          widget.onChanged(widget.field.copyWith(image: path));
                        }
                      },
                      onRemove: () => widget
                          .onChanged(widget.field.copyWith(clearImage: true)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
