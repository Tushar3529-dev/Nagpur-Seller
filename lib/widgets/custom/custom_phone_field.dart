import 'package:flutter/material.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:hyper_local_seller/config/colors.dart';

class CustomPhoneField extends StatelessWidget {
  final String? label;
  final String? hint;
  final bool isRequired;
  final TextEditingController? controller;
  final ValueChanged<PhoneNumber>? onChanged;
  final String? Function(PhoneNumber?)? validator;
  final bool enabled;
  final FocusNode? focusNode;
  final AutovalidateMode? autovalidateMode;
  final String initialCountryCode;
  final ValueChanged<String>? onCountryChanged;

  const CustomPhoneField({
    super.key,
    this.label,
    this.hint,
    this.isRequired = false,
    this.controller,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.focusNode,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.initialCountryCode = 'IN',
    this.onCountryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tertiary = theme.colorScheme.tertiary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          RichText(
            text: TextSpan(
              text: label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: tertiary,
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
        ],
        IntlPhoneField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          autovalidateMode: autovalidateMode,
          initialCountryCode: initialCountryCode,
          style: TextStyle(
            fontSize: 15,
            color: enabled ? tertiary : Colors.grey,
          ),
          cursorColor: AppColors.primaryColor,
          dropdownTextStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryColor,
          ),
          decoration: InputDecoration(
            hintText: hint ?? 'Enter your mobile number',
            hintStyle: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: enabled
                ? (isDark ? const Color(0xFF0D1117) : Colors.white)
                : (isDark ? const Color(0xFF161B22) : Colors.grey.shade100),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppColors.darkErrorColor,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppColors.darkErrorColor,
                width: 1.5,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
          ),
          languageCode: "en",
          onChanged: (phone) {
            onChanged?.call(phone);
            onCountryChanged?.call(phone.countryCode);
          },
          onCountryChanged: (country) {
            onCountryChanged?.call(country.code);
          },
          validator: validator,
          // Customize the country picker dialog
          flagsButtonPadding: const EdgeInsets.only(left: 12),
          dropdownIcon: const Icon(
            Icons.keyboard_arrow_down,
            size: 18,
            color: Colors.grey,
          ),
          showDropdownIcon: true,
          dropdownIconPosition: IconPosition.trailing,
          // Custom country picker theme
          pickerDialogStyle: PickerDialogStyle(
            backgroundColor: theme.colorScheme.surface,
            searchFieldCursorColor: AppColors.primaryColor,
            searchFieldInputDecoration: InputDecoration(
              hintText: 'Search country',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF0D1117)
                  : Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
      ],
    );
  }
}