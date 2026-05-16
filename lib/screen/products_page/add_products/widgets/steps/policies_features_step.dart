import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/bloc/add_product_bloc/add_product_bloc.dart';
import 'package:hyper_local_seller/widgets/custom/custom_dropdown.dart';
import 'package:hyper_local_seller/widgets/custom/custom_textfield.dart';

class PoliciesFeaturesStep extends StatefulWidget {
  const PoliciesFeaturesStep({super.key});

  @override
  State<PoliciesFeaturesStep> createState() => _PoliciesFeaturesStepState();
}

class _PoliciesFeaturesStepState extends State<PoliciesFeaturesStep> {
  final TextEditingController _minOrderController = TextEditingController(
    text: "1",
  );
  final TextEditingController _stepSizeController = TextEditingController(
    text: "1",
  );
  final TextEditingController _totalAllowedController = TextEditingController(
    text: "",
  );
  final TextEditingController _returnableDaysController = TextEditingController(
    text: "",
  );
  final TextEditingController _warrantyController = TextEditingController(
    text: "",
  );
  final TextEditingController _guaranteeController = TextEditingController(
    text: "",
  );

  final FocusNode _minOrderFocus = FocusNode();
  final FocusNode _stepSizeFocus = FocusNode();
  final FocusNode _totalAllowedFocus = FocusNode();
  final FocusNode _returnableDaysFocus = FocusNode();
  final FocusNode _warrantyFocus = FocusNode();
  final FocusNode _guaranteeFocus = FocusNode();

  bool _isReturnable = false;
  bool _isCancelable = false;
  bool _requiredOTP = false;
  bool _featuredProduct = false;
  bool _isAttachmentRequired = false;
  String? _cancelableTill;
  String _warrantyUnit = "Month";
  String _guaranteeUnit = "Month";

  void _updateBloc() {
    final bloc = context.read<AddProductBloc>();
    final currentData = bloc.state.productData;
    bloc.add(
      UpdateProductData(
        currentData.copyWith(
          minimumOrderQuantity: int.tryParse(_minOrderController.text) ?? 1,
          quantityStepSize: int.tryParse(_stepSizeController.text) ?? 1,
          totalAllowedQuantity: int.tryParse(_totalAllowedController.text) ?? 0,
          isReturnable: _isReturnable,
          returnableDays: int.tryParse(_returnableDaysController.text) ?? 0,
          isCancelable: _isCancelable,
          cancelableTill: _cancelableTill,
          requiresOtp: _requiredOTP,
          featured: _featuredProduct,
          isAttachmentRequired: _isAttachmentRequired,
          warrantyPeriod: _warrantyController.text.isNotEmpty
              ? "${_warrantyController.text} $_warrantyUnit"
              : null,
          guaranteePeriod: _guaranteeController.text.isNotEmpty
              ? "${_guaranteeController.text} $_guaranteeUnit"
              : null,
        ),
      ),
    );
  }

  void _updateController(TextEditingController controller, int delta) {
    int current = int.tryParse(controller.text) ?? 0;
    int newValue = current + delta;
    if (newValue < 0) newValue = 0;
    setState(() {
      controller.text = newValue.toString();
    });
    _updateBloc();
  }

  @override
  void initState() {
    super.initState();
    // Initialize from existing state
    final productData = context.read<AddProductBloc>().state.productData;

    _totalAllowedController.text = productData.totalAllowedQuantity.toString();
    _returnableDaysController.text = productData.returnableDays > 0
        ? productData.returnableDays.toString()
        : "";

    _isReturnable = productData.isReturnable;
    _isCancelable = productData.isCancelable;
    _requiredOTP = productData.requiresOtp;
    _featuredProduct = productData.featured;
    _isAttachmentRequired = productData.isAttachmentRequired;
    _cancelableTill = productData.cancelableTill;

    // Parse Warranty
    if (productData.warrantyPeriod != null &&
        productData.warrantyPeriod!.isNotEmpty) {
      final parts = productData.warrantyPeriod!.trim().split(' ');
      if (parts.isNotEmpty) _warrantyController.text = parts[0];
      if (parts.length > 1) {
        final unit = parts[1].toLowerCase();
        if (unit.contains('day')) {
          _warrantyUnit = "Days";
        } else if (unit.contains('month')) {
          _warrantyUnit = "Month";
        } else if (unit.contains('year')) {
          _warrantyUnit = "Year";
        }
      }
    }

    // Parse Guarantee
    if (productData.guaranteePeriod != null &&
        productData.guaranteePeriod!.isNotEmpty) {
      final parts = productData.guaranteePeriod!.trim().split(' ');
      if (parts.isNotEmpty) _guaranteeController.text = parts[0];
      if (parts.length > 1) {
        final unit = parts[1].toLowerCase();
        if (unit.contains('day')) {
          _guaranteeUnit = "Days";
        } else if (unit.contains('month')) {
          _guaranteeUnit = "Month";
        } else if (unit.contains('year')) {
          _guaranteeUnit = "Year";
        }
      }
    }

    _minOrderController.addListener(_updateBloc);
    _stepSizeController.addListener(_updateBloc);
    _totalAllowedController.addListener(_updateBloc);
    _returnableDaysController.addListener(_updateBloc);
    _warrantyController.addListener(_updateBloc);
    _guaranteeController.addListener(_updateBloc);
  }

  @override
  void dispose() {
    _minOrderController.dispose();
    _stepSizeController.dispose();
    _totalAllowedController.dispose();
    _returnableDaysController.dispose();
    _warrantyController.dispose();
    _guaranteeController.dispose();
    _minOrderFocus.dispose();
    _stepSizeFocus.dispose();
    _totalAllowedFocus.dispose();
    _returnableDaysFocus.dispose();
    _warrantyFocus.dispose();
    _guaranteeFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildNumericField(
          label: AppLocalizations.of(context)!.minimumOrderQuantity,
          isRequired: true,
          controller: _minOrderController,
          focusNode: _minOrderFocus,
          hint: "1",
          subLabel: AppLocalizations.of(context)!.byDefaultMinimumQuantity,
        ),
        const SizedBox(height: 20),
        _buildNumericField(
          label: AppLocalizations.of(context)!.quantityStepSize,
          isRequired: true,
          controller: _stepSizeController,
          focusNode: _stepSizeFocus,
          hint: "1",
        ),
        const SizedBox(height: 20),
        _buildNumericField(
          label: AppLocalizations.of(context)!.totalAllowedQuantity,
          isRequired: true,
          controller: _totalAllowedController,
          focusNode: _totalAllowedFocus,
          hint: AppLocalizations.of(context)!.enterQuantity,
          subLabel: AppLocalizations.of(
            context,
          )!.leaveEmptyForUnlimitedQuantity,
        ),
        const SizedBox(height: 25),

        Wrap(
          spacing: 40,
          runSpacing: 20,
          children: [
            _buildSwitchTile(
              AppLocalizations.of(context)!.isReturnable,
              _isReturnable,
              (val) {
                setState(() => _isReturnable = val);
                _updateBloc();
              },
            ),
            _buildSwitchTile(
              AppLocalizations.of(context)!.isCancelable,
              _isCancelable,
              (val) {
                setState(() => _isCancelable = val);
                _updateBloc();
              },
            ),
            _buildSwitchTile(
              AppLocalizations.of(context)!.requiredOtp,
              _requiredOTP,
              (val) => setState(() {
                _requiredOTP = val;
                _updateBloc();
              }),
            ),
            _buildSwitchTile(
              AppLocalizations.of(context)!.featuredProduct,
              _featuredProduct,
              (val) => setState(() {
                _featuredProduct = val;
                _updateBloc();
              }),
            ),
            _buildSwitchTile(
              AppLocalizations.of(context)!.isAttachmentRequired,
              _isAttachmentRequired,
              (val) => setState(() {
                _isAttachmentRequired = val;
                _updateBloc();
              }),
            ),
          ],
        ),

        const SizedBox(height: 25),

        if (_isCancelable) ...[
          CustomDropdown<String>(
            label: AppLocalizations.of(context)!.cancelableTill,
            hint: AppLocalizations.of(context)!.selectOption,
            value: _cancelableTill,
            items: [
              CustomDropdownItem(
                label: AppLocalizations.of(context)!.pending,
                value: "pending",
              ),
              CustomDropdownItem(
                label: AppLocalizations.of(context)!.awaitingStoreResponse,
                value: "awaiting_store_response",
              ),
              CustomDropdownItem(
                label: AppLocalizations.of(context)!.approved,
                value: "accepted",
              ),
              CustomDropdownItem(
                label: AppLocalizations.of(context)!.preparing,
                value: "preparing",
              ),
            ],
            onChanged: (val) {
              setState(() => _cancelableTill = val);
              _updateBloc();
            },
          ),
          const SizedBox(height: 20),
        ],

        if (_isReturnable) ...[
          _buildNumericField(
            label: AppLocalizations.of(context)!.returnableDays,
            controller: _returnableDaysController,
            focusNode: _returnableDaysFocus,
            hint: AppLocalizations.of(context)!.eg7,
            subLabel: AppLocalizations.of(context)!.requiredIfReturnable,
          ),
          const SizedBox(height: 20),
        ],

        _buildPeriodField(
          label: AppLocalizations.of(context)!.warrantyPeriod,
          controller: _warrantyController,
          focusNode: _warrantyFocus,
          unitValue: _warrantyUnit,
          onUnitChanged: (val) => setState(() => _warrantyUnit = val!),
          hint: "0",
        ),
        const SizedBox(height: 20),
        _buildPeriodField(
          label: AppLocalizations.of(context)!.guaranteePeriod,
          controller: _guaranteeController,
          focusNode: _guaranteeFocus,
          unitValue: _guaranteeUnit,
          onUnitChanged: (val) => setState(() => _guaranteeUnit = val!),
          hint: "0",
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPeriodField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String unitValue,
    required ValueChanged<String?> onUnitChanged,
    required String hint,
  }) {
    String helperText = "";
    if (controller.text.isNotEmpty) {
      double? value = double.tryParse(controller.text);
      if (value != null) {
        if (unitValue == "Year") {
          int years = value.floor();
          int months = ((value - years) * 12).round();
          if (months == 12) {
            years++;
            months = 0;
          }

          List<String> parts = [];
          if (years > 0) {
            parts.add(
              "$years ${years > 1 ? AppLocalizations.of(context)!.years : AppLocalizations.of(context)!.year}",
            );
          }
          if (months > 0) {
            parts.add(
              "$months ${months > 1 ? AppLocalizations.of(context)!.months : AppLocalizations.of(context)!.month}",
            );
          }

          if (parts.isNotEmpty) {
            helperText =
                "$label ${AppLocalizations.of(context)!.isFor} ${parts.join(' ${AppLocalizations.of(context)!.and} ')}";
          } else {
            helperText =
                "$label ${AppLocalizations.of(context)!.isFor} 0 ${AppLocalizations.of(context)!.months}";
          }
        } else {
          // Month logic
          int months = value.round();
          helperText =
              "$label ${AppLocalizations.of(context)!.isFor} $months ${months != 1 ? AppLocalizations.of(context)!.months : AppLocalizations.of(context)!.month}";
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.tertiary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomTextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: TextInputType.number,
                  hint: hint,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 1,
              child: CustomDropdown<String>(
                value: unitValue,
                items: [
                  CustomDropdownItem(
                    label: AppLocalizations.of(context)!.days,
                    value: "Days",
                  ),
                  CustomDropdownItem(
                    label: AppLocalizations.of(context)!.month,
                    value: "Month",
                  ),
                  CustomDropdownItem(
                    label: AppLocalizations.of(context)!.year,
                    value: "Year",
                  ),
                ],
                onChanged: onUnitChanged,
              ),
            ),
          ],
        ),
        if (helperText.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            helperText,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ],
    );
  }

  Widget _buildSwitchTile(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.tertiary,
          ),
        ),
        const SizedBox(height: 8),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: AppColors.primaryColor,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: Colors.grey.shade300,
          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          trackOutlineWidth: WidgetStateProperty.all(0),
        ),
      ],
    );
  }

  Widget _buildNumericField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    String? subLabel,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
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
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
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
                child: CustomTextField(
                  controller: controller,
                  focusNode: focusNode,
                  hint: hint,
                  // decoration: InputDecoration(
                  //   hintText: hint,
                  //   border: InputBorder.none,
                  //   contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  // ),
                  keyboardType: TextInputType.number,
                  suffixIcon: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        child: const Icon(
                          Icons.arrow_drop_up,
                          size: 25,
                          color: Colors.grey,
                        ),
                        onTap: () => _updateController(controller, 1),
                      ),
                      GestureDetector(
                        child: const Icon(
                          Icons.arrow_drop_down,
                          size: 25,
                          color: Colors.grey,
                        ),
                        onTap: () => _updateController(controller, -1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (subLabel != null) ...[
          const SizedBox(height: 4),
          Text(
            subLabel,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ],
    );
  }
}
