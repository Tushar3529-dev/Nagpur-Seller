import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/bloc/add_product_bloc/add_product_bloc.dart';
import 'package:hyper_local_seller/widgets/custom/custom_textfield.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';

class ProductDescriptionStep extends StatefulWidget {
  const ProductDescriptionStep({super.key});

  @override
  State<ProductDescriptionStep> createState() => _ProductDescriptionStepState();
}

class _ProductDescriptionStepState extends State<ProductDescriptionStep> {
  final TextEditingController _shortDescController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final List<String> _tags = [];

  final FocusNode _shortDescFocus = FocusNode();
  final FocusNode _tagFocus = FocusNode();
  final FocusNode _fullDescFocus = FocusNode();

  final QuillController _quillController = QuillController.basic();

  void _updateBloc() {
    final bloc = context.read<AddProductBloc>();
    final currentData = bloc.state.productData;
    // Get Delta → convert to JSON-compatible list of maps
    final deltaOps = _quillController.document
        .toDelta()
        .toJson(); // ← this is List<Map<String, dynamic>>

    final converter = QuillDeltaToHtmlConverter(
      deltaOps, // ← pass this instead of delta.toList()
      ConverterOptions(),
    );

    final html = converter.convert();

    bloc.add(
      UpdateProductData(
        currentData.copyWith(
          shortDescription: _shortDescController.text,
          description: html.trim().isEmpty ? "" : html,
          tags: _tags,
        ),
      ),
    );
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
      _updateBloc();
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
    _updateBloc();
  }

  @override
  void initState() {
    super.initState();
    final productData = context.read<AddProductBloc>().state.productData;
    _shortDescController.text = productData.shortDescription ?? "";
    if (productData.tags.isNotEmpty) {
      _tags.addAll(productData.tags);
    }

    if (productData.description != null &&
        productData.description!.isNotEmpty) {
      final delta = HtmlToDelta().convert(
        productData.description!,
        // optional params like transformTableAsEmbed: false, etc.
      );
      _quillController.document = Document.fromDelta(delta);
    }

    _shortDescController.addListener(_updateBloc);
    _quillController.addListener(_updateBloc);
  }

  @override
  void dispose() {
    _shortDescController.dispose();
    _tagController.dispose();
    _shortDescFocus.dispose();
    _tagFocus.dispose();
    _quillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          label: AppLocalizations.of(context)!.shortDescription,
          isRequired: true,
          hint: AppLocalizations.of(context)!.enterShortDescription,
          maxLines: 2,
          focusNode: _shortDescFocus,
          controller: _shortDescController,
        ),
        const SizedBox(height: 20),

        _buildEditorLabel(
          "${AppLocalizations.of(context)!.productDescription} ",
          isRequired: true
        ),
        const SizedBox(height: 8),
        _buildEditor(),
        const SizedBox(height: 20),

        _buildEditorLabel(AppLocalizations.of(context)!.tags),
        const SizedBox(height: 8),
        _buildTagsInput(),
        const SizedBox(height: 12),
        _buildTagsList(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildEditorLabel(String label, {bool isRequired = false}) {
    return RichText(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.tertiary,
        ),
        children: [
          if (isRequired)
          const TextSpan(
            text: ' *',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildEditor() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFC4C4C4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          QuillSimpleToolbar(
            controller: _quillController,
            config: QuillSimpleToolbarConfig(
              showFontFamily: false,
              showFontSize: false,
              showSearchButton: false,
              showInlineCode: false,
              showSubscript: false,
              showSuperscript: false,
              toolbarSectionSpacing: 4,
              multiRowsDisplay: false,
              decoration: BoxDecoration(
                border: const Border.symmetric(
                  horizontal: BorderSide(color: Color(0xFFC4C4C4)),
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8.0),
                  topRight: Radius.circular(8.0),
                ),
              ),
              buttonOptions: const QuillSimpleToolbarButtonOptions(
                base: QuillToolbarBaseButtonOptions(
                  iconTheme: QuillIconTheme(
                    iconButtonSelectedData: IconButtonData(
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1),
          Expanded(
            child: QuillEditor.basic(
              controller: _quillController,
              focusNode: _fullDescFocus,
              config: QuillEditorConfig(
                showCursor: true,
                expands: true,
                padding: const EdgeInsets.all(12),
                textSelectionThemeData: TextSelectionThemeData(
                  cursorColor: AppColors.primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsInput() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _tagController,
              focusNode: _tagFocus,
              cursorColor: AppColors.primaryColor,
              decoration: InputDecoration(
                hintText: 'Enter tags',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: (_) => _addTag(),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _tagController,
            builder: (context, value, child) {
              final bool hasText = value.text.trim().isNotEmpty;
              return IconButton(
                onPressed: hasText ? _addTag : null,
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: hasText
                        ? AppColors.primaryColor
                        : Colors.grey.shade300,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildTagsList() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _tags
          .map(
            (tag) => Chip(
              label: Text(
                tag,
                style: TextStyle(fontSize: 12, color: Colors.black),
              ),
              onDeleted: () => _removeTag(tag),
              deleteIconColor: Colors.red,
              backgroundColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              side: BorderSide(color: Colors.grey.shade300),
            ),
          )
          .toList(),
    );
  }
}
