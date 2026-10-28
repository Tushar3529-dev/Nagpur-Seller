import 'package:flutter/material.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';

/// Highlights where a product sits in the store (its `rack_number`).
///
/// Renders nothing for a null/blank rack so callers can drop it in
/// unconditionally. The label is seller-entered free text — show it as-is.
class RackBadge extends StatelessWidget {
  final String? rackNumber;

  /// Prefix the value with the localized "Rack" word, e.g. "Rack A-12".
  final bool showLabel;
  final double fontSize;

  const RackBadge({
    super.key,
    required this.rackNumber,
    this.showLabel = false,
    this.fontSize = 11.5,
  });

  static const Color _light = Color(0xFFE1F5EE);
  static const Color _lightText = Color(0xFF085041);
  static const Color _dark = Color(0xFF0B3D31);
  static const Color _darkText = Color(0xFF9FE1CB);

  static bool hasRack(String? rackNumber) =>
      rackNumber != null && rackNumber.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (!hasRack(rackNumber)) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? _darkText : _lightText;
    final value = rackNumber!.trim();
    final label = showLabel
        ? '${AppLocalizations.of(context)?.rackLabel ?? 'Rack'} $value'
        : value;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? _dark : _light,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.place_outlined, size: fontSize + 2, color: textColor),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
