import 'package:flutter/material.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/screen/products_page/products/model/product_faq_model.dart';
import 'package:hyper_local_seller/service/demo_guard.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_textfield.dart';
import 'package:hyper_local_seller/widgets/custom/custom_buttons.dart';
import 'package:hyper_local_seller/widgets/custom/custom_selection_sheet.dart';
import 'package:hyper_local_seller/screen/products_page/products/widgets/product_selection_sheet.dart';

class AddFaqBottomSheet extends StatefulWidget {
  final ProductFaq? faq;
  final int? productId;
  final Function(
    int? id,
    int? productId,
    String question,
    String answer,
    String status,
  )?
  onSave;

  const AddFaqBottomSheet({super.key, this.faq, this.productId, this.onSave});

  @override
  State<AddFaqBottomSheet> createState() => _AddFaqBottomSheetState();

  static void show(
    BuildContext context, {
    ProductFaq? faq,
    int? productId,
    Function(
      int? id,
      int? productId,
      String question,
      String answer,
      String status,
    )?
    onSave,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddFaqBottomSheet(
          faq: faq,
          productId: productId,
          onSave: onSave,
        ),
      ),
    );
  }
}

class _AddFaqBottomSheetState extends State<AddFaqBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _questionController;
  late final TextEditingController _answerController;
  late String _status;
  int? _selectedProductId;
  String? _selectedProductName;

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController(text: widget.faq?.question);
    _answerController = TextEditingController(text: widget.faq?.answer);
    _status = widget.faq?.status ?? 'active';
    _selectedProductId = widget.productId ?? widget.faq?.productId;
    _selectedProductName = widget.faq?.product?.title;
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      if (!DemoGuard.shouldProceed(context)) {
        Navigator.pop(context);
        return;
      }
      if (_selectedProductId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a product')),
        );
        return;
      }

      widget.onSave?.call(
        widget.faq?.id,
        _selectedProductId,
        _questionController.text,
        _answerController.text,
        _status,
      );
      Navigator.pop(context);
    }
  }

  String _getLocalizedStatus(String status, AppLocalizations? l10n) {
    switch (status.toLowerCase()) {
      case 'active':
        return (l10n?.active ?? 'Active').toUpperCase();
      case 'inactive':
        return (l10n?.inactive ?? 'Inactive').toUpperCase();
      default:
        return status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenType = context.screenType;
    final theme = Theme.of(context);
    final isEdit = widget.faq != null;
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(UIUtils.radiusLG(screenType)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Padding(
            padding: UIUtils.pagePadding(screenType),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: UIUtils.gapMD(screenType)),
                Text(
                  isEdit
                      ? l10n?.editProductFaq ?? 'Edit Product FAQ'
                      : l10n?.addProductFaq ?? 'Add Product FAQ',
                  style: TextStyle(
                    fontSize: UIUtils.pageTitle(screenType),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: UIUtils.gapLG(screenType)),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (widget.productId == null && !isEdit) ...[
                        CustomTextField(
                          label: l10n?.product ?? 'Product',
                          hint: l10n?.selectProduct ?? 'Select product',
                          readOnly: true,
                          isRequired: true,
                          controller: TextEditingController(
                            text: _selectedProductName,
                          ),
                          onTap: () {
                            ProductSelectionSheet.show(
                              context,
                              onSelected: (product) {
                                setState(() {
                                  _selectedProductId = product.id;
                                  _selectedProductName = product.title;
                                });
                              },
                            );
                          },
                        ),
                        SizedBox(height: UIUtils.gapMD(screenType)),
                      ],
                      CustomTextField(
                        controller: _questionController,
                        label: l10n?.question ?? 'Question',
                        hint: l10n?.enterQuestion ?? 'Enter question',
                        isRequired: true,
                        maxLines: 2,
                        maxLength: 1000,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n?.pleaseEnterAnswer ??
                                'Please enter a question';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: UIUtils.gapMD(screenType)),
                      CustomTextField(
                        controller: _answerController,
                        label: l10n?.answer ?? 'Answer',
                        hint: l10n?.enterAnswer ?? 'Enter answer',
                        isRequired: true,
                        maxLines: 4,
                        maxLength: 4000,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n?.pleaseEnterAnswer ??
                                'Please enter an answer';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: UIUtils.gapMD(screenType)),
                      CustomTextField(
                        label: l10n?.status ?? 'Status',
                        hint: l10n?.selectStatus ?? 'Select status',
                        readOnly: true,
                        isRequired: true,
                        controller: TextEditingController(
                          text: _getLocalizedStatus(_status, l10n),
                        ),
                        suffixIcon: Icon(Icons.arrow_drop_down),
                        onTap: () {
                          CustomSelectionSheet.show(
                            context: context,
                            title: l10n?.selectStatus ?? 'Select Status',
                            items: [
                              SelectionItem(
                                label: l10n?.active.toUpperCase() ?? 'ACTIVE',
                                value: 'active',
                              ),
                              SelectionItem(
                                label:
                                    l10n?.inactive.toUpperCase() ?? 'INACTIVE',
                                value: 'inactive',
                              ),
                            ],
                            selectedValue: _status,
                            onSelected: (value) {
                              setState(() {
                                _status = value;
                              });
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),

                SizedBox(height: UIUtils.gapXL(screenType)),

                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    text: isEdit
                        ? l10n?.updateFaq ?? 'Update FAQ'
                        : l10n?.addFaq ?? 'Add FAQ',
                    onPressed: _handleSave,
                  ),
                ),

                SizedBox(height: UIUtils.gapMD(screenType)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
