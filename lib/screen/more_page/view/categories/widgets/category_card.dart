import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';

class CategoryCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final ScreenType screenType;

  const CategoryCard({super.key, required this.data, required this.screenType});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Image + Name + Status chips in one row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(context),
            SizedBox(width: UIUtils.gapMD(screenType)),

            // Name + chips
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['name'] ?? 'Unnamed Category',
                    style: TextStyle(
                      fontSize: UIUtils.tileTitle(screenType),
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      if (data['status'] != null)
                        _buildStatusChip(
                          context,
                          label: data['status'],
                          isActive:
                              data['status'].toString().toLowerCase() ==
                              'active',
                        ),
                      if (data['status'] != null &&
                          data['optional_status'] != null)
                        const SizedBox(width: 8),
                      if (data['optional_status'] != null)
                        _buildStatusChip(
                          context,
                          label: data['optional_status'],
                          isActive: false,
                          isWarning: true,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        SizedBox(height: 12),

        // Subcategory count
        _buildKeyValueRow(
          context,
          key: "Commission",
          value: '${data['commission']?.toString() ?? 0} %',
        ), // Subcategory count
        // Optional: show parent if exists and is useful
        if (data['parent'] != null && data['parent'] != 'N/A')
          _buildKeyValueRow(context, key: "Parent", value: data['parent']),
        _buildKeyValueRow(
          context,
          key: "Subcategories",
          value: data['subcategory_count']?.toString() ?? '0',
        ),
      ],
    );
  }

  // Reused from CustomCard – you can keep them here or extract to shared file
  Widget _buildImage(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(UIUtils.radiusSM(screenType)),
      child: CachedNetworkImage(
        imageUrl: data['image'] ?? 'https://via.placeholder.com/150',
        width: UIUtils.avatarXL(screenType),
        height: UIUtils.avatarXL(screenType),
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: UIUtils.avatarXL(screenType),
          height: UIUtils.avatarXL(screenType),
          color: Colors.grey.shade100,
        ),
        errorWidget: (context, url, error) => Container(
          width: UIUtils.avatarXL(screenType),
          height: UIUtils.avatarXL(screenType),
          color: Colors.grey.shade200,
          child: const Icon(Icons.image, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildStatusChip(
    BuildContext context, {
    required String label,
    bool isActive = false,
    bool isWarning = false,
  }) {
    Color bgColor = isActive
        ? Colors.green.shade50
        : (isWarning ? Colors.orange.shade50 : Colors.grey.shade100);
    Color textColor = isActive
        ? Colors.green
        : (isWarning ? Colors.orange : Colors.grey);

    if (label == "Not Required") {
      bgColor = Colors.orange.shade50;
      textColor = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _capitalizeWords(label),
        style: TextStyle(
          fontSize: UIUtils.caption(screenType),
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildKeyValueRow(
    BuildContext context, {
    required String key,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "$key:",
            style: TextStyle(
              fontSize: UIUtils.body(screenType),
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: UIUtils.body(screenType),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _capitalizeWords(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : word[0].toUpperCase() + word.substring(1).toLowerCase(),
        )
        .join(' ');
  }
}
