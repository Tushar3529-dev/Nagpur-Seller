import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/screen/more_page/view/brands/bloc/brands_bloc.dart';
import 'package:country_picker/country_picker.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/bloc/add_product_bloc/add_product_bloc.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_dropdown.dart';
import 'package:hyper_local_seller/widgets/custom/custom_textfield.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/widgets/brand_selection_sheet.dart';

class ProductInfoStep extends StatefulWidget {
  const ProductInfoStep({super.key});

  @override
  State<ProductInfoStep> createState() => _ProductInfoStepState();
}

class _ProductInfoStepState extends State<ProductInfoStep> {
  final TextEditingController _brandController = TextEditingController();
  final List<Map<String, dynamic>> _customFields = [];
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _hsnController = TextEditingController();
  final TextEditingController _madeInController = TextEditingController();
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _hsnFocus = FocusNode();

  String? _selectedIndicator;
  int? _selectedBrandId;
  int _basePrepTime = 20;

  @override
  void initState() {
    super.initState();
    // Load brands
    context.read<BrandsBloc>().add(LoadBrandsInitial());

    // Initialize from existing state
    final productData = context.read<AddProductBloc>().state.productData;
    _titleController.text = productData.title ?? "";
    _hsnController.text = productData.hsnCode ?? "";
    _madeInController.text = productData.madeIn ?? "";
    _selectedIndicator = productData.indicator;
    _selectedBrandId = productData.brandId;
    _brandController.text = productData.brandName ?? "";
    _basePrepTime = productData.prepTime;

    if (productData.customFields.isNotEmpty) {
      for (var field in productData.customFields) {
        if (field.containsKey('key') && field.containsKey('value')) {
          _customFields.add({
            'key': TextEditingController(text: field['key']),
            'value': TextEditingController(text: field['value']),
            'keyFocus': FocusNode(),
            'valueFocus': FocusNode(),
          });
        }
      }
    }
  }

  void _showBrandSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BrandSelectionSheet(
        selectedBrandId: _selectedBrandId,
        onSelected: (brand) {
          setState(() {
            _selectedBrandId = brand.id;
            _brandController.text = brand.title;
          });
          _updateBloc();
        },
      ),
    );
  }

  void _addCustomField() {
    setState(() {
      _customFields.add({
        'key': TextEditingController(),
        'value': TextEditingController(),
        'keyFocus': FocusNode(),
        'valueFocus': FocusNode(),
      });
    });
  }

  void _removeCustomField(int index) {
    setState(() {
      _customFields[index]['key']?.dispose();
      _customFields[index]['value']?.dispose();
      _customFields[index]['keyFocus']?.dispose();
      _customFields[index]['valueFocus']?.dispose();
      _customFields.removeAt(index);
    });
  }

  void _showCustomTimePickerDialog() {
    final controller = TextEditingController(text: _basePrepTime.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.basePrepTime),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            suffixText: AppLocalizations.of(context)?.minutesShort ?? "Min",
            hintText:
                AppLocalizations.of(context)?.enterTimeInMinutes ??
                "Enter time in minutes",
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val >= 0) {
                setState(() {
                  _basePrepTime = val;
                });
                _updateBloc();
                Navigator.pop(context);
              }
            },
            child: Text(AppLocalizations.of(context)!.ok),
          ),
        ],
      ),
    );
  }

  void _showCountryPicker() {
    showCountryPicker(
      context: context,
      useSafeArea: true,
      showSearch: true,
      countryListTheme: CountryListThemeData(
        backgroundColor: Theme.of(context).cardColor,
        inputDecoration: InputDecoration(
          hintText: 'Search',

          hintStyle: TextStyle(
            color: Colors.black54,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          filled: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
        ),
        searchTextStyle: TextStyle(color: AppColors.primaryColor),
      ),
      showPhoneCode: false,
      searchAutofocus: true,
      onSelect: (Country country) {
        setState(() {
          _madeInController.text = country.name;
        });
        _updateBloc();
      },
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _hsnController.dispose();
    _madeInController.dispose();
    _brandController.dispose();
    _titleFocus.dispose();
    _hsnFocus.dispose();
    for (var field in _customFields) {
      field['key']?.dispose();
      field['value']?.dispose();
      field['keyFocus']?.dispose();
      field['valueFocus']?.dispose();
    }
    super.dispose();
  }

  void _updateBloc() {
    final bloc = context.read<AddProductBloc>();
    final currentData = bloc.state.productData;

    final List<Map<String, String>> customFieldsData = [];
    for (var field in _customFields) {
      final key = (field['key'] as TextEditingController).text;
      final value = (field['value'] as TextEditingController).text;
      if (key.isNotEmpty || value.isNotEmpty) {
        customFieldsData.add({'key': key, 'value': value});
      }
    }

    bloc.add(
      UpdateProductData(
        currentData.copyWith(
          title: _titleController.text,
          brandId: _selectedBrandId,
          brandName: _brandController.text,
          madeIn: _madeInController.text,
          hsnCode: _hsnController.text,
          indicator: _selectedIndicator,
          prepTime: _basePrepTime,
          customFields: customFieldsData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenType = context.screenType;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          label: AppLocalizations.of(context)!.title,
          isRequired: true,
          hint: AppLocalizations.of(context)!.enterProductTitle,
          controller: _titleController,
          onChanged: (v) => _updateBloc(),
        ),
        const SizedBox(height: 20),

        GestureDetector(
          onTap: _showBrandSelection,
          child: AbsorbPointer(
            child: CustomTextField(
              label: AppLocalizations.of(context)!.brand,
              hint: AppLocalizations.of(context)!.selectBrand,
              controller: _brandController,
              suffixIcon: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.grey,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        GestureDetector(
          onTap: _showCountryPicker,
          child: AbsorbPointer(
            child: CustomTextField(
              label: AppLocalizations.of(context)!.madeIn,
              hint: AppLocalizations.of(context)!.selectCountry,
              controller: _madeInController,
              // onChanged here won't trigger because of AbsorbPointer,
              // handled in _showCountryPicker
            ),
          ),
        ),
        const SizedBox(height: 20),

        CustomTextField(
          label: AppLocalizations.of(context)!.hsnCode,
          isRequired: false,
          hint: AppLocalizations.of(context)!.enterHsnCode,
          controller: _hsnController,
          onChanged: (v) => _updateBloc(),
        ),
        const SizedBox(height: 20),

        CustomDropdown<String>(
          label: AppLocalizations.of(context)!.indicator,
          isRequired: false,
          hint: AppLocalizations.of(context)!.selectIndicator,
          value: _selectedIndicator,
          items: [
            CustomDropdownItem(
              label: AppLocalizations.of(context)!.none,
              value: '',
            ),
            CustomDropdownItem(
              label: AppLocalizations.of(context)!.veg,
              value: "veg",
            ),
            CustomDropdownItem(
              label: AppLocalizations.of(context)!.nonVeg,
              value: "non-veg",
            ),
          ],
          onChanged: (val) {
            setState(() => _selectedIndicator = val);
            _updateBloc();
          },
        ),
        const SizedBox(height: 20),
        _buildBasePrepTime(context.screenType),
        const SizedBox(height: 30),
        Text(
          AppLocalizations.of(context)!.customFields,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.tertiary,
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(
          _customFields.length,
          (index) => _buildCustomFieldRow(index, screenType),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _addCustomField,
          icon: const Icon(Icons.add, size: 18),
          label: Text(AppLocalizations.of(context)!.addField),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryColor,
            side: const BorderSide(color: AppColors.primaryColor),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          AppLocalizations.of(context)!.addCustomFieldHelper,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildBasePrepTime(ScreenType screenType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: AppLocalizations.of(context)!.basePrepTime,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.tertiary,
            ),
            children: [
              const TextSpan(
                text: ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 4),
        Text(
          AppLocalizations.of(context)!.averageTimetoPrepareanorderinminutes,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.remove,
                        color: AppColors.primaryColor,
                      ),
                      onPressed: () {
                        if (_basePrepTime > 0) {
                          setState(() {
                            _basePrepTime -= 5;
                            _updateBloc();
                          });
                        }
                      },
                    ),
                    GestureDetector(
                      onTap: _showCustomTimePickerDialog,
                      child: Text(
                        "$_basePrepTime ${AppLocalizations.of(context)!.minutesShort}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.add,
                        color: AppColors.primaryColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _basePrepTime += 5;
                          _updateBloc();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomFieldRow(int index, ScreenType screenType) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            flex: 2,
            child: CustomTextField(
              controller: _customFields[index]['key'],
              focusNode: _customFields[index]['keyFocus'],
              hint: AppLocalizations.of(context)!.fieldName,
              onChanged: (v) => _updateBloc(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: CustomTextField(
              controller: _customFields[index]['value'],
              focusNode: _customFields[index]['valueFocus'],
              hint: AppLocalizations.of(context)!.value,
              onChanged: (v) => _updateBloc(),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _removeCustomField(index),
            child: Container(
              margin: const EdgeInsets.only(bottom: 2), // Align with textfield
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close, color: Colors.red, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}
