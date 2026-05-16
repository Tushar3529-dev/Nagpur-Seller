import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/utils/time_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_card.dart';

class BrandCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final ScreenType screenType;

  const BrandCard({super.key, required this.data, required this.screenType});

  @override
  Widget build(BuildContext context) {
    final hasImage =
        data['image'] != null && data['image'].toString().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (hasImage) ...[
              _buildImage(),
              SizedBox(width: UIUtils.gapMD(screenType)),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        data['name'] ?? 'Unnamed Brand',
                        style: TextStyle(
                          fontSize: UIUtils.tileTitle(screenType),
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(width: 6),
                      if (data['status'] != null)
                        _buildStatusChip(
                          data['status'],
                          isActive:
                              data['status'].toString().toLowerCase() ==
                              'active',
                        ),
                    ],
                  ),
                  SizedBox(height: UIUtils.gapSM(screenType)),
                  Text(
                    data['description'] ?? 'Unnamed Brand',
                    style: TextStyle(
                      fontSize: UIUtils.caption(screenType),
                      fontWeight: FontWeight.normal,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: UIUtils.gapMD(screenType)),
        if (data['date'] != null) ...[
          SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Created:",
                style: TextStyle(
                  fontSize: UIUtils.caption(screenType),
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                TimeUtils.formatTimeAgo(
                  data['date'],
                  context,
                  type: TimeFormatType.product,
                ),
                style: TextStyle(
                  fontSize: UIUtils.caption(screenType),
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(UIUtils.radiusSM(screenType)),
      child: CachedNetworkImage(
        imageUrl: data['image'] ?? 'https://via.placeholder.com/150',
        width: UIUtils.avatarXL(screenType),
        height: UIUtils.avatarXL(screenType),
        fit: BoxFit.contain,
        placeholder: (context, url) => Container(color: Colors.grey.shade100),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey.shade200,
          child: const Icon(Icons.branding_watermark, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, {bool isActive = false}) {
    final bgColor = isActive ? Colors.green.shade50 : Colors.grey.shade100;
    final textColor = isActive ? Colors.green.shade800 : Colors.grey.shade700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        capitalizeWords(label),
        style: TextStyle(
          fontSize: UIUtils.caption(screenType),
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
