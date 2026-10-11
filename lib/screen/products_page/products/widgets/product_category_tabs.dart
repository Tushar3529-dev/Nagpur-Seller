import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/screen/products_page/products/model/product_category_tree.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';

/// Two level filter for the products list: a scrollable row of category tabs
/// and, under it, a scrollable row of subcategory chips with an "All" chip
/// first. A [selectedSubcategoryId] of null means "All".
class ProductCategoryTabs extends StatefulWidget {
  final List<ProductCategoryGroup> categories;
  final ScreenType screenType;
  final int selectedCategoryId;
  final int? selectedSubcategoryId;
  final ValueChanged<int> onCategorySelected;
  final ValueChanged<int?> onSubcategorySelected;

  const ProductCategoryTabs({
    super.key,
    required this.categories,
    required this.screenType,
    required this.selectedCategoryId,
    required this.selectedSubcategoryId,
    required this.onCategorySelected,
    required this.onSubcategorySelected,
  });

  @override
  State<ProductCategoryTabs> createState() => _ProductCategoryTabsState();
}

class _ProductCategoryTabsState extends State<ProductCategoryTabs> {
  final Map<int, GlobalKey> _tabKeys = {};

  /// Chip keys; the "All" chip is stored under null.
  final Map<int?, GlobalKey> _chipKeys = {};

  @override
  void didUpdateWidget(ProductCategoryTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategoryId != widget.selectedCategoryId) {
      _chipKeys.clear();
      _reveal(_tabKeys[widget.selectedCategoryId]);
    } else if (oldWidget.selectedSubcategoryId !=
        widget.selectedSubcategoryId) {
      _reveal(_chipKeys[widget.selectedSubcategoryId]);
    }
  }

  /// Scrolls the selected tab or chip towards the middle of its row.
  void _reveal(GlobalKey? key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final itemContext = key?.currentContext;
      if (itemContext == null || !itemContext.mounted) return;
      Scrollable.ensureVisible(
        itemContext,
        alignment: 0.5,
        duration: UIUtils.normalAnim,
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenType = widget.screenType;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final divider = isDark
        ? AppColors.darkExtraCardColor
        : AppColors.lightSecondary;
    final selected = widget.categories.firstWhere(
      (c) => c.id == widget.selectedCategoryId,
      orElse: () => widget.categories.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: divider)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(
              horizontal: UIUtils.gapSM(screenType),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final category in widget.categories)
                  _CategoryTab(
                    key: _tabKeys.putIfAbsent(category.id, GlobalKey.new),
                    category: category,
                    isSelected: category.id == selected.id,
                    screenType: screenType,
                    onTap: () => widget.onCategorySelected(category.id),
                  ),
              ],
            ),
          ),
        ),
        if (selected.subcategories.isNotEmpty)
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: divider)),
            ),
            child: SingleChildScrollView(
              // A new key per category starts its chip row scrolled to the start.
              key: ValueKey('subcategories-${selected.id}'),
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(
                horizontal: UIUtils.gapLG(screenType),
                vertical: UIUtils.gapSM(screenType) + 2,
              ),
              child: Row(
                children: [
                  _SubcategoryChip(
                    key: _chipKeys.putIfAbsent(null, GlobalKey.new),
                    label:
                        AppLocalizations.of(context)?.productCategoryAll ??
                        'All',
                    count: selected.products.length,
                    isSelected: widget.selectedSubcategoryId == null,
                    screenType: screenType,
                    onTap: () => widget.onSubcategorySelected(null),
                  ),
                  for (final sub in selected.subcategories) ...[
                    SizedBox(width: UIUtils.gapSM(screenType)),
                    _SubcategoryChip(
                      key: _chipKeys.putIfAbsent(sub.id, GlobalKey.new),
                      label: sub.title,
                      count: sub.products.length,
                      isSelected: widget.selectedSubcategoryId == sub.id,
                      screenType: screenType,
                      onTap: () => widget.onSubcategorySelected(sub.id),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _CategoryTab extends StatelessWidget {
  final ProductCategoryGroup category;
  final bool isSelected;
  final ScreenType screenType;
  final VoidCallback onTap;

  const _CategoryTab({
    super.key,
    required this.category,
    required this.isSelected,
    required this.screenType,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final muted = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.6);
    final color = isSelected ? AppColors.primaryColor : muted;
    final subCount = category.subcategories.length;
    final caption = subCount > 0
        ? (l10n?.productSubcategoryCount(subCount) ?? '$subCount subcategories')
        : (l10n?.productCategoryProductCount(category.products.length) ??
              '${category.products.length} products');
    final iconSize = UIUtils.avatarSM(screenType);

    return Semantics(
      selected: isSelected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: UIUtils.fastAnim,
          constraints: BoxConstraints(minWidth: iconSize + 40),
          padding: EdgeInsets.fromLTRB(
            UIUtils.gapMD(screenType),
            UIUtils.gapSM(screenType),
            UIUtils.gapMD(screenType),
            UIUtils.gapSM(screenType),
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.primaryColor : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: iconSize,
                height: iconSize,
                child: category.icon.isNotEmpty
                    // Category icons are single colour line art, so they are
                    // tinted to match the tab like the fallback icon.
                    ? CachedNetworkImage(
                        imageUrl: category.icon,
                        width: iconSize,
                        height: iconSize,
                        fit: BoxFit.contain,
                        color: color,
                        colorBlendMode: BlendMode.srcIn,
                        placeholder: (_, _) => const SizedBox.shrink(),
                        errorWidget: (_, _, _) => Icon(
                          Icons.category_outlined,
                          color: color,
                          size: UIUtils.sectionIcon(screenType) + 4,
                        ),
                      )
                    : Icon(
                        Icons.category_outlined,
                        color: color,
                        size: UIUtils.sectionIcon(screenType) + 4,
                      ),
              ),
              SizedBox(height: UIUtils.gapXS(screenType)),
              Text(
                category.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: UIUtils.tileSubtitle(screenType),
                  fontWeight: isSelected ? UIUtils.bold : UIUtils.semiBold,
                  color: isSelected ? AppColors.primaryColor : null,
                ),
              ),
              Text(
                caption,
                maxLines: 1,
                style: TextStyle(
                  fontSize: UIUtils.caption(screenType),
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubcategoryChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final ScreenType screenType;
  final VoidCallback onTap;

  const _SubcategoryChip({
    super.key,
    required this.label,
    required this.count,
    required this.isSelected,
    required this.screenType,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final radius = BorderRadius.circular(999);

    return Semantics(
      selected: isSelected,
      button: true,
      child: Material(
        color: isSelected
            ? AppColors.primaryColor.withValues(alpha: isDark ? 0.25 : 0.1)
            : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: isSelected
                ? AppColors.primaryColor
                : (isDark
                      ? AppColors.darkExtraCardColor
                      : AppColors.lightSecondary),
          ),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: UIUtils.gapMD(screenType),
              vertical: UIUtils.gapSM(screenType),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: UIUtils.tileSubtitle(screenType),
                    fontWeight: isSelected ? UIUtils.bold : UIUtils.regular,
                    color: isSelected ? AppColors.primaryColor : null,
                  ),
                ),
                SizedBox(width: UIUtils.gapXS(screenType) + 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryColor
                        : onSurface.withValues(alpha: 0.08),
                    borderRadius: radius,
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: UIUtils.caption(screenType),
                      fontWeight: UIUtils.semiBold,
                      color: isSelected
                          ? Colors.white
                          : onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
