import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/screen/more_page/view/attributes/widgets/attribute_card.dart';
import 'package:hyper_local_seller/screen/more_page/view/attributes/widgets/attribute_value_card.dart';
import 'package:hyper_local_seller/screen/more_page/view/brands/widgets/brand_card.dart';
import 'package:hyper_local_seller/screen/more_page/view/categories/widgets/category_card.dart';
import 'package:hyper_local_seller/screen/more_page/view/roles_and_permissions/widgets/roles_card.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/widgets/store_card.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/widgets/system_user_card.dart';
import 'package:hyper_local_seller/screen/more_page/view/tax_group/widgets/tax_group_card.dart';
import 'package:hyper_local_seller/screen/order_page/widgets/order_card.dart';
import 'package:hyper_local_seller/screen/products_page/products/bloc/products_bloc/products_bloc.dart';
import 'package:hyper_local_seller/screen/products_page/products/widgets/product_card.dart';
import 'package:hyper_local_seller/screen/products_page/products/widgets/faq_card.dart';
import 'package:hyper_local_seller/service/demo_guard.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_drop_menu.dart';

enum CardType {
  brand,
  category,
  taxGroup,
  product,
  store,
  attribute,
  attributeValue,
  order,
  faq,
  roles,
  systemUser,
}

class CustomCard extends StatelessWidget {
  final CardType type;
  final Map<String, dynamic> data;
  final ScreenType screenType;

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Function(String)? onToggleStatus;
  final VoidCallback? onTap;
  final Widget? extraWidgets;

  const CustomCard({
    super.key,
    required this.type,
    required this.data,
    required this.screenType,
    this.onEdit,
    this.onDelete,
    this.onToggleStatus,
    this.onTap,
    this.extraWidgets,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? Theme.of(context).colorScheme.surfaceContainer
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(UIUtils.radiusLG(screenType)),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: ID and More Options
            Padding(
              padding: UIUtils.cardPadding(screenType),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "ID: ${data['id'] ?? ''}",
                    style: TextStyle(
                      fontSize: UIUtils.body(screenType),
                      fontWeight: UIUtils.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),

                  if (onEdit != null || onDelete != null)
                    CustomDropMenu(
                      items: [
                        MenuItem(
                          label: l10n?.editLbl ?? 'Edit',
                          icon: Icons.edit,
                          onTap: () => onEdit!(),
                        ),
                        MenuItem(
                          label: l10n?.delete ?? 'Delete',
                          icon: Icons.delete,
                          onTap: () => onDelete!(),
                          textColor: Colors.red,
                          iconColor: Colors.red,
                        ),
                      ],
                      dotsColor: Colors.grey.shade600,
                    )
                  else
                    SizedBox.shrink(),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            Padding(
              padding: UIUtils.cardPadding(screenType),
              child: _buildBody(context),
            ),
            if (extraWidgets != null) ...[
              Divider(
                height: 1,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              extraWidgets ?? SizedBox.shrink(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (type) {
      case CardType.brand:
        return BrandCard(data: data, screenType: screenType);
      case CardType.category:
        return CategoryCard(data: data, screenType: screenType);
      case CardType.taxGroup:
        return TaxGroupCard(data: data, screenType: screenType);
      case CardType.product:
        return ProductCard(data: data, screenType: screenType);
      case CardType.store:
        return StoreCard(data: data, screenType: screenType);
      case CardType.attribute:
        return AttributeCard(data: data, screenType: screenType);
      case CardType.attributeValue:
        return AttributeValueCard(data: data, screenType: screenType);
      case CardType.order:
        return OrderCard(
          data: data,
          screenType: screenType,
          onStatusUpdate: onToggleStatus,
        );
      case CardType.faq:
        return FaqCard(data: data, screenType: screenType);
      case CardType.roles:
        return RolesCard(data: data, screenType: screenType);
      case CardType.systemUser:
        return SystemUserCard(data: data, screenType: screenType);
    }
  }
}

String capitalizeWords(String text) {
  return text
      .split(' ')
      .map(
        (word) =>
            word.isEmpty ? word : word[0].toUpperCase() + word.substring(1),
      )
      .join(' ');
}
