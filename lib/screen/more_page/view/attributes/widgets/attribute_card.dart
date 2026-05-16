import 'package:flutter/material.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/utils/time_utils.dart';

class AttributeCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final ScreenType screenType;

  const AttributeCard({
    super.key,
    required this.data,
    required this.screenType,
  });

  @override
  Widget build(BuildContext context) {
    final swatchType = data['swatch_type']?.toString() ?? 'text';
    final l10n = AppLocalizations.of(context);


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              data['name'] ?? '—',
              style: TextStyle(
                fontSize: UIUtils.tileTitle(screenType),
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _getSwatchBgColor(swatchType),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                swatchType.toUpperCase(),
                style: TextStyle(
                  fontSize: UIUtils.caption(screenType),
                  fontWeight: FontWeight.w600,
                  color: _getSwatchTextColor(swatchType),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n?.valueCount ??  "Values count:",
              style: TextStyle(color: Colors.grey.shade700),
            ),
            Text(
              "${data['values_count'] ?? 0}",
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              TimeUtils.formatTimeAgo(
                data['date'],
                context,
                type: TimeFormatType.attribute,
              ),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Color _getSwatchBgColor(String type) {
    switch (type.toLowerCase()) {
      case 'color':
        return Colors.purple.shade50;
      case 'image':
        return Colors.blue.shade50;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _getSwatchTextColor(String type) {
    switch (type.toLowerCase()) {
      case 'color':
        return Colors.purple.shade800;
      case 'image':
        return Colors.blue.shade800;
      default:
        return Colors.grey.shade700;
    }
  }
}
