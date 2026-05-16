import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/bloc/store_switcher/store_switcher_cubit.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/model/store_model.dart';
import 'package:hyper_local_seller/utils/image_path.dart';
import 'package:hyper_local_seller/widgets/custom/custom_filter_sheet.dart';
import 'package:hyper_local_seller/widgets/custom/custom_selection_sheet.dart';
import 'package:hyper_local_seller/widgets/custom/custom_svg.dart';

class CustomSearchField extends StatelessWidget {
  final String? hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool enabled;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final FocusNode? focusNode;
  final EdgeInsetsGeometry? padding;
  final Color? fillColor;
  final double? height;
  final bool? showFilters;
  final bool? showStore;
  final FilterType filterType;

  const CustomSearchField({
    super.key,
    this.hint,
    this.controller,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.enabled = true,
    this.suffixIcon,
    this.prefixIcon,
    this.focusNode,
    this.padding,
    this.fillColor,
    this.height,
    this.showFilters = false,
    this.showStore = false,
    this.filterType = FilterType.order,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tertiary = theme.colorScheme.tertiary;

    final effectiveController = controller ?? TextEditingController();

    return Row(
      children: [
        Expanded(
          child: Container(
            height: height ?? 48,
            padding: padding,
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: effectiveController,
              builder: (context, value, child) {
                final bool hasText = value.text.isNotEmpty;
                final bool shouldHighlight =
                    hasText || (focusNode?.hasFocus ?? false);

                final iconColor = shouldHighlight
                    ? tertiary
                    : const Color(0xFFC4C4C4);

                return TextField(
                  controller: effectiveController,
                  onChanged: onChanged,
                  onTap: onTap,
                  readOnly: readOnly,
                  enabled: enabled,
                  focusNode: focusNode,
                  style: TextStyle(
                    fontSize: 16,
                    color: enabled ? tertiary : Colors.grey.shade500,
                  ),
                  cursorColor: AppColors.primaryColor,
                  decoration: InputDecoration(
                    hintText: hint ?? "Search",
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                    prefixIcon:
                        prefixIcon ??
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: CustomSvg(
                            svgPath: ImagesPath.searchSvg,
                            width: 18,
                            height: 18,
                            fit: BoxFit.contain,
                            color: iconColor,
                          ),
                        ),
                    suffixIcon: suffixIcon,
                    filled: true,
                    fillColor:
                        fillColor ??
                        (isDark
                            ? const Color(0xFF21262D)
                            : const Color(0xFFFFFFFF)),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 0,
                    ),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: shouldHighlight
                            ? tertiary
                            : const Color(0xFFC4C4C4),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        width: 1,
                        color: shouldHighlight
                            ? tertiary
                            : const Color(0xFFC4C4C4),
                      ),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFFC4C4C4),
                        width: 1,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // ── Only show filter button when fromOrder is true ──
        if (showFilters == true) ...[
          Padding(
            padding: EdgeInsetsDirectional.only(
              start: 8,
              end: (showStore == true) ? 0 : 8,
            ),
            child: GestureDetector(
              onTap: () => _showFilterSheet(context),
              child: Container(
                width: height ?? 48,
                height: height ?? 48,
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFC4C4C4),
                    width: 1.2,
                  ),
                ),
                alignment: Alignment.center,
                child: CustomSvg(
                  svgPath: ImagesPath.filtersSvg,
                  width: 24,
                  height: 24,
                ),
              ),
            ),
          ),
        ],

        if (showStore == true)
          BlocBuilder<StoreSwitcherCubit, StoreSwitcherState>(
            builder: (context, state) {
              // Optional: you can show loading shimmer here if needed
              // but for icon button usually we keep it simple

              final storeId = HiveStorage.selectedStoreId;

              return Padding(
                // Always some start spacing from previous element (filter or search field)
                // No end spacing — it's the last item in the row
                padding: const EdgeInsetsDirectional.only(start: 8, end: 0),
                child: GestureDetector(
                  onTap: () {
                    CustomSelectionSheet.show<Store>(
                      context: context,
                      title:
                          AppLocalizations.of(context)?.switchStore ??
                          'Switch Store',
                      selectedValue:  state.selectedStore,
                      items: state.stores
                          .where(
                            (s) =>
                                s.verificationStatus != 'not_approved' &&
                                s.visibilityStatus != 'draft',
                          )
                          .map(
                            (s) => SelectionItem<Store>(
                              label: s.name,
                              sublabel: s.address,
                              value: s,
                              image: s.logo,
                            ),
                          )
                          .toList(),
                      onSelected: (selected) {
                        context.read<StoreSwitcherCubit>().selectStore(
                          selected,
                        );
                      },
                    );
                  },
                  child: Container(
                    width: height ?? 48,
                    height: height ?? 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFC4C4C4),
                        width: 1.2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: CustomSvg(
                      svgPath: ImagesPath.storeSvg,
                      width: 24,
                      height: 24,
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FilterSheet(type: filterType),
    );
  }
}

class CustomSearchFieldWrapper extends StatelessWidget {
  final String? hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final Widget? suffixIcon;

  const CustomSearchFieldWrapper({
    super.key,
    this.hint,
    this.controller,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: CustomSearchField(
        hint: hint,
        controller: controller,
        onChanged: onChanged,
        onTap: onTap,
        readOnly: readOnly,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
