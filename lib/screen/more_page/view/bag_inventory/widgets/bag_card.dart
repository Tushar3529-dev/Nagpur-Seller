import 'package:flutter/material.dart';
import 'package:hyper_local_seller/screen/more_page/view/bag_inventory/model/bag_model.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_drop_menu.dart';
import 'package:intl/intl.dart';

class BagCard extends StatelessWidget {
  final Bag bag;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  /// Tapping the lock on an assigned bag, which can't be edited or deleted.
  final VoidCallback onLockedTap;

  const BagCard({
    super.key,
    required this.bag,
    required this.onEdit,
    required this.onDelete,
    required this.onLockedTap,
  });

  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy, HH:mm');

  @override
  Widget build(BuildContext context) {
    final screenType = context.screenType;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = isDark ? Colors.white70 : Colors.grey.shade600;
    final createdAt = bag.createdAt;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainer
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(UIUtils.radiusLG(screenType)),
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: UIUtils.cardPadding(screenType),
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    bag.barcode,
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: UIUtils.body(screenType) + 1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _StatusChip(isAssigned: bag.isAssigned),
                const SizedBox(width: 6),
                if (bag.isAssigned)
                  IconButton(
                    tooltip: "Assigned bags can't be changed",
                    visualDensity: VisualDensity.compact,
                    onPressed: onLockedTap,
                    icon: Icon(Icons.lock_outline, size: 20, color: muted),
                  )
                else
                  CustomDropMenu(
                    dotsColor: muted,
                    items: [
                      MenuItem(label: 'Edit', icon: Icons.edit, onTap: onEdit),
                      MenuItem(
                        label: 'Delete',
                        icon: Icons.delete,
                        onTap: onDelete,
                        textColor: Colors.red,
                        iconColor: Colors.red,
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
          Padding(
            padding: UIUtils.cardPadding(screenType),
            child: DefaultTextStyle.merge(
              style: TextStyle(
                fontSize: UIUtils.caption(screenType) + 1,
                color: muted,
              ),
              child: Row(
                children: [
                  Icon(Icons.receipt_long_outlined, size: 15, color: muted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      bag.orderNumber ?? 'No order',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (createdAt != null)
                    Text(_dateFormat.format(createdAt.toLocal())),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isAssigned;

  const _StatusChip({required this.isAssigned});

  @override
  Widget build(BuildContext context) {
    final background = isAssigned ? Colors.blue.shade50 : Colors.green.shade50;
    final foreground = isAssigned
        ? Colors.blue.shade800
        : Colors.green.shade800;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isAssigned ? 'Assigned' : 'Available',
        style: TextStyle(
          fontSize: UIUtils.caption(context.screenType),
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}
