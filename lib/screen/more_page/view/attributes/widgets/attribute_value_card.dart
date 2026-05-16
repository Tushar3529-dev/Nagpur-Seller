import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_loading_indicator.dart';
import 'package:hyper_local_seller/utils/time_utils.dart';

class AttributeValueCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final ScreenType screenType;

  const AttributeValueCard({
    super.key,
    required this.data,
    required this.screenType,
  });

  @override
  Widget build(BuildContext context) {
    final swatchType = data['swatch_type']?.toString() ?? 'text';
    final swatchValue = data['swatch_value']?.toString();

    return Row(
      children: [
        if (swatchType.toLowerCase() == 'color' && swatchValue != null)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildColorSwatch(swatchValue),
          )
        else if (swatchType.toLowerCase() == 'image' && swatchValue != null)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildImageSwatch(swatchValue),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 4),
              Text(
                TimeUtils.formatTimeAgo(
                  data['date'],
                  context,
                  type: TimeFormatType.attributeValues,
                ),
                style: TextStyle(
                  fontSize: UIUtils.caption(screenType),
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColorSwatch(String hex) {
    try {
      final cleanHex = hex.replaceAll('#', '');
      final color = Color(int.parse('FF$cleanHex', radix: 16));
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300),
        ),
      );
    } catch (e) {
      return const Icon(Icons.error, color: Colors.red, size: 32);
    }
  }

  Widget _buildImageSwatch(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: CachedNetworkImage(
        imageUrl: url,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        placeholder: (context, url) =>
            const CustomLoadingIndicator(size: 20, strokeWidth: 2),
        errorWidget: (context, url, error) =>
            const Icon(Icons.broken_image, size: 32),
      ),
    );
  }
}
