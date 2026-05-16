import 'package:flutter/material.dart';
import 'package:hyper_local_seller/widgets/custom/custom_selection_sheet.dart';

class CustomDropdown<T> extends StatelessWidget {
  final String? label;
  final String? hint;
  final T? value;
  final List<CustomDropdownItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool isRequired;
  final Widget? prefixIcon;

  const CustomDropdown({
    super.key,
    this.label,
    this.hint,
    this.value,
    required this.items,
    this.onChanged,
    this.isRequired = false,
    this.prefixIcon,
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
        GestureDetector(
          onTap: () => _showSelection(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0D1117) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                if (prefixIcon != null) ...[
                  prefixIcon!,
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    value != null
                        ? items.firstWhere(
                          (item) => item.value == value,
                      orElse: () => CustomDropdownItem(label: "—", value: value as T), // fallback
                    ).label
                        : hint ?? "Select Option",
                    style: TextStyle(
                      fontSize: 15,
                      color: value != null
                          ? tertiary
                          : Colors.grey.shade500,
                      fontWeight: value != null ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.grey,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showSelection(BuildContext context) {
    CustomSelectionSheet.show<T>(
      context: context,
      title: label ?? hint ?? "Select Option",
      items: items
          .map((item) => SelectionItem<T>(
                label: item.label,
                value: item.value,
              ))
          .toList(),
      onSelected: (val) => onChanged?.call(val),
      selectedValue: value,
    );
  }
}

class CustomDropdownItem<T> {
  final String label;
  final T value;

  CustomDropdownItem({required this.label, required this.value});
}
