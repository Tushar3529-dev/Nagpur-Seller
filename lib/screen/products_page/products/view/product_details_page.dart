import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hyper_local_seller/bloc/store_switcher/store_switcher_cubit.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/extensions/l10n_extensions.dart';
import 'package:hyper_local_seller/screen/home_page/bloc/home_page/home_page_bloc.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/bloc/add_product_bloc/add_product_bloc.dart'
    as add_product;
import 'package:hyper_local_seller/screen/products_page/products/bloc/products_bloc/products_bloc.dart';
import 'package:hyper_local_seller/screen/products_page/products/model/product_model.dart';
import 'package:hyper_local_seller/screen/products_page/products/repo/products_repo.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/widgets/custom/custom_alert_dialog.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';
import 'package:hyper_local_seller/widgets/custom/custom_shimmer.dart';
import 'package:hyper_local_seller/service/demo_guard.dart';
import 'package:hyper_local_seller/utils/permission_checker.dart';
import 'package:hyper_local_seller/config/app_permissions.dart';
import 'package:hyper_local_seller/router/app_routes.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/bloc/selected_categories/selected_categories_cubit.dart';

class ProductDetailsPage extends StatefulWidget {
  final Product product;
  const ProductDetailsPage({super.key, required this.product});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage>
    with SingleTickerProviderStateMixin {
  late Product _product;
  bool _isLoading = false;
  final PageController _pageController = PageController();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  List<String> get _allImages {
    final images = [_product.mainImage];
    if (_product.additionalImages.isNotEmpty) {
      images.addAll(_product.additionalImages);
    }
    return images;
  }

  Future<void> _refreshProduct() async {
    setState(() => _isLoading = true);
    try {
      final repo = ProductsRepo();
      final response = await repo.getProductById(_product.id);
      if (response['success'] == true && response['data'] != null) {
        setState(() {
          _product = Product.fromJson(response['data']);
        });
        _fadeController
          ..reset()
          ..forward();
      }
    } catch (e) {
      if (mounted) {
        showCustomSnackbar(
          context: context,
          message:
              AppLocalizations.of(context)?.failedToRefreshProduct ??
              "Failed to refresh product details",
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenType = context.screenType;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return CustomScaffold(
      backgroundColor: isDark
          ? AppColors.mainDarkBackgroundColor
          : const Color(0xFFF8F8F8),
      body: _isLoading
          ? _buildShimmer(screenType, isDark)
          : FadeTransition(
              opacity: _fadeAnimation,
              child: RefreshIndicator(
                onRefresh: _refreshProduct,
                color: AppColors.primaryColor,
                child: SafeArea(
                  top: true,
                  bottom: false,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      _buildSliverAppBar(isDark, l10n),
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildProductHeader(screenType, isDark, l10n),
                            _buildPriceRow(screenType, isDark, l10n),
                            if (_product.tags.isNotEmpty)
                              _buildTags(screenType, isDark),
                            _buildDivider(isDark),
                            _buildQuickStats(screenType, isDark, l10n),
                            _buildDivider(isDark),
                            _buildActionRow(screenType, isDark, l10n),
                            _buildDivider(isDark),
                            if (_product.shortDescription?.isNotEmpty == true)
                              _buildDescriptionSection(
                                screenType,
                                isDark,
                                l10n,
                              ),
                            if (_product.customProductSections?.isNotEmpty ==
                                true)
                              _buildCustomSections(screenType, isDark),
                            _buildVariantsSection(screenType, isDark, l10n),
                            _buildProductInfoSection(screenType, isDark, l10n),
                            if (_product.customFields?.isNotEmpty == true)
                              _buildCustomFields(screenType, isDark, l10n),
                            _buildSellerRatingsSection(
                              screenType,
                              isDark,
                              l10n,
                            ),
                            const SizedBox(height: 48),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSliverAppBar(bool isDark, AppLocalizations? l10n) {
    return SliverAppBar(
      expandedHeight: 340,
      pinned: true,
      backgroundColor: isDark
          ? AppColors.mainDarkBackgroundColor
          : AppColors.mainLightBackgroundColor,
      foregroundColor: isDark ? Colors.white : Colors.black87,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: _CircleIconButton(
          icon: Platform.isAndroid
              ? Icons.arrow_back
              : Icons.arrow_back_ios_new_rounded,
          isDark: isDark,
          onTap: () => Navigator.of(context).pop(),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: _buildImageGrid(ScreenType.mobile, isDark, inAppBar: true),
      ),
    );
  }

  void _openFullScreen(int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenImageGallery(
          images: _allImages,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Widget _buildImageGrid(
    ScreenType screenType,
    bool isDark, {
    bool inAppBar = false,
  }) {
    final images = _allImages;
    if (images.isEmpty) return const SizedBox.shrink();

    // ── Slider for < 4 images ──
    if (images.length < 4) {
      return _ImageSlider(
        images: images,
        isDark: isDark,
        pageController: _pageController,
        openFullScreen: _openFullScreen,
        imageBuilder: _buildProductImage,
      );
    }

    // ── Original grid for ≥ 4 images ── (unchanged)
    return SizedBox(
      height: 340,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: () => _openFullScreen(0),
              child: _buildProductImage(images.first, isDark),
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            flex: 1,
            child: Column(
              children: List.generate(4, (index) {
                final imageIndex = index + 1;
                final bool hasImage = images.length > imageIndex;
                final bool isLastSlot = index == 3;
                final bool hasMore = images.length > 5;

                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(bottom: index == 3 ? 0 : 2),
                    child: hasImage
                        ? GestureDetector(
                            onTap: () => _openFullScreen(imageIndex),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                _buildProductImage(images[imageIndex], isDark),
                                if (isLastSlot && hasMore)
                                  Container(
                                    color: Colors.black45,
                                    child: Center(
                                      child: Text(
                                        '+${images.length - 5}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          )
                        : Container(
                            color: isDark
                                ? AppColors.mainDarkContainerBgColor
                                : Colors.grey.shade100,
                          ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(String url, bool isDark) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: _product.imageFit == 'contain' ? BoxFit.contain : BoxFit.cover,
      placeholder: (_, __) => Container(
        color: isDark
            ? AppColors.mainDarkContainerBgColor
            : Colors.grey.shade100,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 1.5)),
      ),
      errorWidget: (_, __, ___) => Container(
        color: isDark
            ? AppColors.mainDarkContainerBgColor
            : Colors.grey.shade100,
        child: const Icon(
          Icons.broken_image_outlined,
          size: 40,
          color: Colors.grey,
        ),
      ),
    );
  }

  // ─────────────────────────── HEADER ───────────────────────────

  Widget _buildProductHeader(
    ScreenType screenType,
    bool isDark,
    AppLocalizations? l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category + Brand row
          Row(
            children: [
              if (_product.categoryName != null)
                _Chip(
                  label: _product.categoryName!,
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                  textColor: AppColors.primaryColor,
                ),
              if (_product.categoryName != null && _product.brandName != null)
                const SizedBox(width: 6),
              if (_product.brandName != null)
                _Chip(
                  label: _product.brandName!,
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                  textColor: isDark
                      ? Colors.grey.shade300
                      : Colors.grey.shade700,
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Title
          Text(
            _product.title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.3,
              color: isDark ? Colors.white : Colors.black87,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),

          // Rating row
          if (_product.ratingCount > 0)
            Row(
              children: [
                ...List.generate(5, (i) {
                  return Icon(
                    i < _product.ratings
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 16,
                    color: Colors.amber.shade600,
                  );
                }),
                const SizedBox(width: 6),
                Text(
                  l10n?.reviewCount(_product.ratingCount) ??
                      '${_product.ratings.toStringAsFixed(1)} (${_product.ratingCount} reviews)',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ─────────────────────────── PRICE ───────────────────────────

  Widget _buildPriceRow(
    ScreenType screenType,
    bool isDark,
    AppLocalizations? l10n,
  ) {
    final firstVariant = _product.variants?.isNotEmpty == true
        ? _product.variants!.first
        : null;
    final store = firstVariant?.stores?.isNotEmpty == true
        ? firstVariant!.stores!.first
        : null;

    final price = store?.price ?? firstVariant?.price?.toDouble() ?? 0;
    final special =
        store?.specialPrice ?? firstVariant?.specialPrice?.toDouble() ?? 0;
    final hasDiscount = special > 0 && special < price;
    final displayPrice = hasDiscount ? special : price;
    final symbol = HiveStorage.currencySymbol;
    final discount = hasDiscount
        ? ((price - special) / price * 100).round()
        : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '$symbol${displayPrice.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryColor,
              letterSpacing: -0.5,
            ),
          ),
          if (hasDiscount) ...[
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '$symbol${price.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.green.shade600,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                l10n?.offPercent(discount) ?? '$discount% off',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const Spacer(),
          // Stock indicator
          if (store?.stock != null)
            _StockBadge(stock: store!.stock!, isDark: isDark),
        ],
      ),
    );
  }

  // ─────────────────────────── TAGS ───────────────────────────

  Widget _buildTags(ScreenType screenType, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: _product.tags.map((tag) {
          return _Chip(
            label: '#$tag',
            color: isDark
                ? AppColors.primaryColor.withValues(alpha: 0.15)
                : AppColors.primaryColor.withValues(alpha: 0.08),
            textColor: AppColors.primaryColor,
            fontSize: 11,
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────── QUICK STATS ───────────────────────────

  Widget _buildQuickStats(
    ScreenType screenType,
    bool isDark,
    AppLocalizations? l10n,
  ) {
    final stats = [
      _StatItem(
        icon: Icons.shopping_bag_outlined,
        label: l10n?.minOrderShort ?? 'Min Order',
        value:
            l10n?.qtyAmount(_product.minimumOrderQuantity ?? 1) ??
            '${_product.minimumOrderQuantity ?? 1} qty',
      ),
      _StatItem(
        icon: Icons.timer_outlined,
        label: l10n?.prepTimeShort ?? 'Prep Time',
        value:
            l10n?.minShort(_product.prepTime ?? 0) ??
            '${_product.prepTime ?? 0} min',
      ),
      _StatItem(
        icon: Icons.assignment_return_outlined,
        label: l10n?.returnsLabel ?? 'Returns',
        value: _product.isReturnable
            ? l10n?.daysShort(_product.returnableDays ?? 0) ??
                  '${_product.returnableDays}d'
            : (l10n?.no ?? 'No'),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: stats.map((s) {
          final isLast = s == stats.last;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        s.icon,
                        size: 18,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.value,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.label,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: isDark
                              ? Colors.grey.shade500
                              : Colors.grey.shade500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 1,
                    height: 36,
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────── ACTIONS ───────────────────────────

  Widget _buildActionRow(
    ScreenType screenType,
    bool isDark,
    AppLocalizations? l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              icon: Icons.edit_outlined,
              label: l10n?.editLbl ?? 'Edit',
              color: AppColors.primaryColor,
              isDark: isDark,
              onTap: _onEdit,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionButton(
              icon: _product.status == 'active'
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              label: _product.status == 'active'
                  ? (l10n?.disableLabel ?? 'Disable')
                  : (l10n?.enableLabel ?? 'Enable'),
              color: _product.status == 'active'
                  ? Colors.orange.shade700
                  : Colors.green.shade700,
              isDark: isDark,
              onTap: _onToggleStatus,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionButton(
              icon: Icons.help_outline_rounded,
              label: 'FAQs',
              color: Colors.purple.shade600,
              isDark: isDark,
              onTap: _onViewFAQs,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionButton(
              icon: Icons.delete_outline_rounded,
              label: l10n?.delete ?? 'Delete',
              color: Colors.red.shade600,
              isDark: isDark,
              onTap: _onDelete,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── DESCRIPTION ───────────────────────────

  Widget _buildDescriptionSection(
    ScreenType screenType,
    bool isDark,
    AppLocalizations? l10n,
  ) {
    return _Section(
      title: l10n?.productDescription ?? 'Description',
      isDark: isDark,
      child: Text(
        _product.shortDescription!,
        style: TextStyle(
          fontSize: 13.5,
          height: 1.65,
          color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
        ),
      ),
    );
  }

  // ─────────────────────────── CUSTOM SECTIONS ───────────────────────────

  Widget _buildCustomSections(ScreenType screenType, bool isDark) {
    final sections = _product.customProductSections!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections.map((section) {
        return _Section(
          title: section.title,
          subtitle: section.description,
          isDark: isDark,
          child: Column(
            children: section.fields.map((field) {
              return _CustomSectionFieldCard(field: field, isDark: isDark);
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  // ─────────────────────────── VARIANTS ───────────────────────────

  Widget _buildVariantsSection(
    ScreenType screenType,
    bool isDark,
    AppLocalizations? l10n,
  ) {
    final variants = _product.variants;
    if (variants == null || variants.isEmpty) return const SizedBox.shrink();

    return _Section(
      title: l10n?.variantsAndAvailability ?? 'Variants & Availability',
      isDark: isDark,
      child: Column(
        children: variants.map((variant) {
          return _VariantCard(
            variant: variant,
            isDark: isDark,
            currencySymbol: HiveStorage.currencySymbol,
            l10n: l10n,
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────── PRODUCT INFO ───────────────────────────

  Widget _buildProductInfoSection(
    ScreenType screenType,
    bool isDark,
    AppLocalizations? l10n,
  ) {
    final rows = <_InfoRowData>[
      _InfoRowData(
        Icons.branding_watermark_outlined,
        l10n?.brand ?? 'Brand',
        _product.brandName ?? (l10n?.notAvailable ?? 'N/A'),
      ),
      _InfoRowData(
        Icons.category_outlined,
        l10n?.categories ?? 'Category',
        _product.categoryName ?? (l10n?.notAvailable ?? 'N/A'),
      ),
      _InfoRowData(
        Icons.inventory_2_outlined,
        l10n?.productTypeLabel ?? 'Type',
        (l10n?.translateEnum(_product.type ?? 'simple') ??
                (_product.type ?? 'simple'))
            .toUpperCase(),
      ),
      if (_product.hsnCode != null && _product.hsnCode!.isNotEmpty)
        _InfoRowData(
          Icons.receipt_long_outlined,
          l10n?.hsnCode ?? 'HSN Code',
          _product.hsnCode!,
        ),
      _InfoRowData(
        Icons.assignment_return_outlined,
        l10n?.returnableLabel ?? 'Returnable',
        _product.isReturnable
            ? (l10n?.yesWithDays(_product.returnableDays ?? 0) ??
                  'Yes — ${_product.returnableDays} days')
            : (l10n?.no ?? 'No'),
      ),
      _InfoRowData(
        Icons.cancel_outlined,
        l10n?.cancelableLabel ?? 'Cancelable',
        _product.isCancelable == true
            ? (l10n?.yesTillTime(_product.cancelableTill ?? "") ??
                  'Yes${_product.cancelableTill != null ? ' (till ${_product.cancelableTill})' : ''}')
            : (l10n?.no ?? 'No'),
      ),
      if (_product.warrantyPeriod != null &&
          _product.warrantyPeriod!.isNotEmpty)
        _InfoRowData(
          Icons.security_outlined,
          l10n?.warrantyLabel ?? 'Warranty',
          _product.warrantyPeriod!,
        ),
      if (_product.guaranteePeriod != null &&
          _product.guaranteePeriod!.isNotEmpty)
        _InfoRowData(
          Icons.verified_outlined,
          l10n?.guaranteeLabel ?? 'Guarantee',
          _product.guaranteePeriod!,
        ),
      if (_product.madeIn != null && _product.madeIn!.isNotEmpty)
        _InfoRowData(
          Icons.public_outlined,
          l10n?.madeInLabel ?? 'Made In',
          _product.madeIn!,
        ),
      _InfoRowData(
        Icons.exposure_outlined,
        l10n?.taxLabel ?? 'Tax',
        _product.isInclusiveTax == true
            ? (l10n?.inclusive ?? 'Inclusive')
            : (l10n?.exclusive ?? 'Exclusive'),
      ),
      _InfoRowData(
        Icons.stars_outlined,
        l10n?.featuredLabel ?? 'Featured',
        _product.featured == '1' ? (l10n?.yes ?? 'Yes') : (l10n?.no ?? 'No'),
      ),
      if (_product.isAttachmentRequired == true)
        _InfoRowData(
          Icons.attach_file_outlined,
          l10n?.attachmentLabel ?? 'Attachment',
          l10n?.requiredLabel ?? 'Required',
        ),
      if (_product.requiresOtp == true)
        _InfoRowData(
          Icons.lock_outline_rounded,
          l10n?.otpLabel ?? 'OTP',
          l10n?.requiredLabel ?? 'Required',
        ),
    ];

    return _Section(
      title: l10n?.productDetails ?? 'Product Details',
      isDark: isDark,
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final i = entry.key;
          final row = entry.value;
          return Column(
            children: [
              _InfoRow(data: row, isDark: isDark),
              if (i < rows.length - 1)
                Divider(
                  height: 1,
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────── CUSTOM FIELDS ───────────────────────────

  Widget _buildCustomFields(
    ScreenType screenType,
    bool isDark,
    AppLocalizations? l10n,
  ) {
    final fields = _product.customFields!;
    final entries = fields.entries.toList();

    return _Section(
      title: l10n?.specificationsLabel ?? 'Specifications',
      isDark: isDark,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: entries.map((e) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.mainDarkContainerBgColor
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.key,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  e.value.toString(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────── SELLER RATINGS ───────────────────────────

  Widget _buildSellerRatingsSection(
    ScreenType screenType,
    bool isDark,
    AppLocalizations? l10n,
  ) {
    final storeStatus = _product.storeStatus;
    if (storeStatus == null) return const SizedBox.shrink();

    return _Section(
      title: l10n?.storeInfoLabel ?? 'Store Info',
      isDark: isDark,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: storeStatus.isOpen
                  ? Colors.green.withValues(alpha: 0.12)
                  : Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              storeStatus.isOpen
                  ? Icons.storefront_rounded
                  : Icons.store_outlined,
              color: storeStatus.isOpen
                  ? Colors.green.shade600
                  : Colors.red.shade600,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _product.sellerName ?? (l10n?.seller ?? 'Seller'),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: storeStatus.isOpen
                          ? Colors.green.shade500
                          : Colors.red.shade500,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    storeStatus.isOpen
                        ? (l10n?.storeIsOpen ?? 'Store is Open')
                        : (l10n?.storeIsClosed ?? 'Store is Closed'),
                    style: TextStyle(
                      fontSize: 12,
                      color: storeStatus.isOpen
                          ? Colors.green.shade600
                          : Colors.red.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── HELPERS ───────────────────────────

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark
          ? AppColors.darkOutline.withValues(alpha: 0.4)
          : Colors.grey.shade100,
    );
  }

  Widget _buildShimmer(ScreenType screenType, bool isDark) {
    return SingleChildScrollView(
      child: Column(
        children: [
          CustomShimmer(width: double.infinity, height: 340),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: List.generate(
                6,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: CustomShimmer(
                    width: double.infinity,
                    height: i == 0 ? 24 : 60,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── ACTIONS ───────────────────────────

  void _onEdit() {
    if (!PermissionChecker.hasPermission(AppPermissions.productEdit)) {
      showCustomSnackbar(
        context: context,
        message:
            AppLocalizations.of(context)?.noPermissionEditProduct ??
            "No permission to edit",
        isWarning: true,
      );
      return;
    }
    if (!DemoGuard.shouldProceed(context)) return;
    if (_product.categoryId != null) {
      context.read<SelectedCategoriesCubit>().select(_product.categoryId!);
    }
    context.read<add_product.AddProductBloc>().add(
      add_product.LoadProductForEdit(_product.id),
    );
    // context.push(AppRoutes.addProduct, extra: {'is_edit': true});

    context.push<bool>(AppRoutes.addProduct, extra: {'is_edit': true}).then((
      shouldRefresh,
    ) {
      if (shouldRefresh == true && context.mounted) {
        if (!mounted) return;
        context.read<ProductsBloc>().add(RefreshProducts());
        _refreshProduct();

        final selectedStore = context
            .read<StoreSwitcherCubit>()
            .state
            .selectedStore;
        if (selectedStore != null) {
          context.read<HomePageBloc>().add(
            FetchHomePageData(storeId: selectedStore.id),
          );
        }
      }
    });
  }

  void _onViewFAQs() {
    context.pushNamed(
      '/product-faqs',
      queryParameters: {'productId': _product.id.toString()},
    );
  }

  void _onToggleStatus() {
    if (!DemoGuard.shouldProceed(context)) return;
    final newStatus = _product.status == 'active' ? 'draft' : 'active';
    context.read<ProductsBloc>().add(
      UpdateProductStatus(productId: _product.id, status: newStatus),
    );
    setState(() => _product.status = newStatus);
    showCustomSnackbar(
      context: context,
      message: AppLocalizations.of(context)?.statusUpdated ?? "Status updated",
      isError: false,
    );
  }

  void _onDelete() {
    if (!PermissionChecker.hasPermission(AppPermissions.productDelete)) {
      showCustomSnackbar(
        context: context,
        message:
            AppLocalizations.of(context)?.noPermissionDeleteProduct ??
            "No permission to delete",
        isWarning: true,
      );
      return;
    }
    if (!DemoGuard.shouldProceed(context)) return;
    showAppAlertDialog(
      context: context,
      title: AppLocalizations.of(context)?.deleteProduct ?? "Delete Product",
      message:
          AppLocalizations.of(context)?.deleteProductConfirmation ??
          "Are you sure you want to delete this product?",
      confirmColor: AppColors.errorColor,
      onConfirm: () {
        context.read<ProductsBloc>().add(DeleteProduct(_product.id));
        context.pop(true);
        _refreshHomePage();
      },
    );
  }

  void _refreshHomePage() {
    final selectedStore = context
        .read<StoreSwitcherCubit>()
        .state
        .selectedStore;
    if (selectedStore != null) {
      context.read<HomePageBloc>().add(
        FetchHomePageData(storeId: selectedStore.id),
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════
//  HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════

class _ImageSlider extends StatefulWidget {
  final List<String> images;
  final bool isDark;
  final PageController pageController;
  final void Function(int) openFullScreen;
  final Widget Function(String, bool) imageBuilder;

  const _ImageSlider({
    required this.images,
    required this.isDark,
    required this.pageController,
    required this.openFullScreen,
    required this.imageBuilder,
  });

  @override
  State<_ImageSlider> createState() => _ImageSliderState();
}

class _ImageSliderState extends State<_ImageSlider> {
  late int _currentPage;
  late Timer? _timer;

  @override
  void initState() {
    super.initState();
    _currentPage = 0;
    widget.pageController.addListener(_onPageChanged);

    // Auto-play
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final nextPage = (_currentPage + 1) % widget.images.length;
      widget.pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  void _onPageChanged() {
    final newPage = widget.pageController.page?.round() ?? 0;
    if (newPage != _currentPage) {
      setState(() => _currentPage = newPage);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.pageController.removeListener(_onPageChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: widget.pageController,
          itemCount: widget.images.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () => widget.openFullScreen(index),
              child: widget.imageBuilder(widget.images[index], widget.isDark),
            );
          },
        ),

        if (widget.images.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.images.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == _currentPage
                        ? AppColors.primaryColor
                        : Colors.white.withValues(alpha: 0.6),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 0.8,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _CircleIconButton({
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final double fontSize;

  const _Chip({
    required this.label,
    required this.color,
    required this.textColor,
    this.fontSize = 11.5,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  final int stock;
  final bool isDark;

  const _StockBadge({required this.stock, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isLow = stock < 20;
    return Row(
      children: [
        Icon(
          isLow ? Icons.inventory_outlined : Icons.check_circle_outline_rounded,
          size: 13,
          color: isLow ? Colors.orange.shade600 : Colors.green.shade600,
        ),
        const SizedBox(width: 4),
        Text(
          '$stock in stock',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isLow ? Colors.orange.shade600 : Colors.green.shade600,
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final bool isDark;

  const _Section({
    required this.title,
    this.subtitle,
    required this.child,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: -0.2,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: child,
        ),
        const SizedBox(height: 4),
        Divider(
          height: 1,
          thickness: 1,
          color: isDark
              ? Colors.grey.shade800.withValues(alpha: 0.6)
              : Colors.grey.shade100,
        ),
      ],
    );
  }
}

class _CustomSectionFieldCard extends StatelessWidget {
  final CustomProductField field;
  final bool isDark;

  const _CustomSectionFieldCard({required this.field, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.mainDarkContainerBgColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (field.image != null && field.image!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: CachedNetworkImage(
                imageUrl: field.image!,
                width: 88,
                height: 88,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 88,
                  height: 88,
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 88,
                  height: 88,
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                  child: const Icon(
                    Icons.image_outlined,
                    color: Colors.grey,
                    size: 24,
                  ),
                ),
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    field.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (field.description != null &&
                      field.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      field.description!,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VariantCard extends StatelessWidget {
  final Variant variant;
  final bool isDark;
  final String currencySymbol;
  final AppLocalizations? l10n;

  const _VariantCard({
    required this.variant,
    required this.isDark,
    required this.currencySymbol,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final store = variant.stores?.isNotEmpty == true
        ? variant.stores!.first
        : null;
    final price = store?.price ?? variant.price?.toDouble() ?? 0;
    final special =
        store?.specialPrice ?? variant.specialPrice?.toDouble() ?? 0;
    final hasDiscount = special > 0 && special < price;
    final displayPrice = hasDiscount ? special : price;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.mainDarkContainerBgColor
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: variant.isDefault == true
              ? AppColors.primaryColor.withValues(alpha: 0.4)
              : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          width: variant.isDefault == true ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Variant image or icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: variant.image?.isNotEmpty == true
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: variant.image!,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(
                    Icons.style_outlined,
                    color: AppColors.primaryColor,
                    size: 20,
                  ),
          ),
          const SizedBox(width: 12),

          // Title + barcode
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        variant.title ?? 'Default',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (variant.isDefault == true)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Default',
                          style: TextStyle(
                            fontSize: 9,
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (store?.storeName != null)
                      Text(
                        store!.storeName!,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? Colors.grey.shade500
                              : Colors.grey.shade500,
                        ),
                      ),
                    if (variant.barcode != null) ...[
                      Text(
                        '  ·  ${variant.barcode}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? Colors.grey.shade600
                              : Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Price + stock
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$currencySymbol${displayPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppColors.primaryColor,
                ),
              ),
              if (hasDiscount)
                Text(
                  '$currencySymbol${price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              const SizedBox(height: 2),
              Text(
                '${store?.stock ?? variant.stock ?? 0}  left',
                style: TextStyle(
                  fontSize: 10.5,
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final _InfoRowData data;
  final bool isDark;

  const _InfoRow({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Icon(
            data.icon,
            size: 17,
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
          ),
          const SizedBox(width: 12),
          Text(
            data.label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const Spacer(),
          Text(
            data.value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 19),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Data classes
class _StatItem {
  final IconData icon;
  final String label;
  final String value;
  _StatItem({required this.icon, required this.label, required this.value});
}

class _InfoRowData {
  final IconData icon;
  final String label;
  final String value;
  _InfoRowData(this.icon, this.label, this.value);
}

class FullScreenImageGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullScreenImageGallery({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  @override
  State<FullScreenImageGallery> createState() => _FullScreenImageGalleryState();
}

class _FullScreenImageGalleryState extends State<FullScreenImageGallery> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isDark
        ? AppColors.mainDarkBackgroundColor
        : AppColors.mainLightBackgroundColor;
    final iconColor = isDark ? Colors.white : Colors.black87;
    final indicatorBgColor = isDark
        ? AppColors.primaryColor
        : AppColors.primaryColor.withValues(alpha: 0.05);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: iconColor, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full Screen Pager
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: widget.images[index],
                    fit: BoxFit.contain,
                    placeholder: (_, __) => CircularProgressIndicator(
                      color: AppColors.primaryColor,
                      strokeWidth: 2,
                    ),
                    errorWidget: (_, __, ___) => Icon(
                      Icons.broken_image,
                      color: isDark ? Colors.white54 : Colors.grey,
                      size: 50,
                    ),
                  ),
                ),
              );
            },
          ),

          // Index Indicator
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: indicatorBgColor,
                    borderRadius: BorderRadius.circular(20),
                    border: isDark ? null : Border.all(color: Colors.black12),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.images.length}',
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
