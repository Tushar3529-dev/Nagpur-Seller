import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/service/external_link.dart';
import 'package:hyper_local_seller/utils/time_utils.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/widgets/custom/custom_card.dart';
import 'package:hyper_local_seller/widgets/custom/custom_svg.dart';
import 'package:hyper_local_seller/utils/image_path.dart';
import 'package:hyper_local_seller/extensions/l10n_extensions.dart';

class StoreCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final ScreenType screenType;

  const StoreCard({super.key, required this.data, required this.screenType});

  @override
  Widget build(BuildContext context) {
    final imageUrl = data['logo'] ?? data['image'];
    final hasImage = imageUrl != null && imageUrl.toString().isNotEmpty;
    final isOpen = data['status'] is Map
        ? data['status']['is_open'] ?? false
        : false;
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage) ...[
              _buildImage(),
              SizedBox(width: UIUtils.gapMD(screenType)),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['name'] ?? 'Unnamed Store',
                    style: TextStyle(
                      fontSize: UIUtils.tileTitle(screenType),
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: UIUtils.gapXS(screenType)),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (data['verification_status'] != null)
                        _buildStatusChip(
                          l10n?.translateEnum(data['verification_status']) ??
                              data['verification_status'],
                          isActive:
                              data['verification_status']
                                  .toString()
                                  .toLowerCase() ==
                              'approved',
                        ),
                      if (data['visibility_status'] != null)
                        _buildStatusChip(
                          l10n?.translateEnum(data['visibility_status']) ??
                              data['visibility_status'],
                          isActive:
                              data['visibility_status']
                                  .toString()
                                  .toLowerCase() ==
                              'visible',
                        ),
                      _buildStatusChip(
                        isOpen
                            ? l10n?.open ?? 'Open'
                            : l10n?.closed ?? 'Closed',
                        isActive: isOpen,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        SizedBox(height: UIUtils.gapMD(screenType)),

        // Location & date row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Row(
                children: [
                  CustomSvg(
                    svgPath: ImagesPath.locationSvg,
                    color: AppColors.darkOutline,
                    height: 16,
                    width: 16,
                  ),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      data['address'] ?? data['location'] ?? 'No address',
                      style: TextStyle(
                        fontSize: UIUtils.body(screenType),
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16),
            Text(
              TimeUtils.formatTimeAgo(
                data['created_at'] ?? data['date'],
                context,
                type: TimeFormatType.store,
              ),
              style: TextStyle(
                fontSize: UIUtils.caption(screenType),
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),

        SizedBox(height: UIUtils.gapMD(screenType)),

        // Phone
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CustomSvg(
                  svgPath: ImagesPath.phoneSvg,
                  color: AppColors.darkOutline,
                  height: 16,
                  width: 16,
                ),
                SizedBox(width: 8),
                Text(
                  data['contact_number'] ?? data['phone'] ?? '—',
                  style: TextStyle(
                    fontSize: UIUtils.body(screenType),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: () {
                final phone = data['contact_number'] ?? data['phone'] ?? '';
                if (phone.isNotEmpty && phone != '—') {
                  ExternalLink.makePhoneCall(context, phone);
                }
              },
              child: Text(
                "Call",
                style: TextStyle(
                  fontSize: UIUtils.body(screenType),
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImage() {
    final imageUrl = data['logo'] ?? data['image'];
    return ClipRRect(
      borderRadius: BorderRadius.circular(UIUtils.radiusSM(screenType)),
      child: CachedNetworkImage(
        imageUrl: imageUrl ?? '',
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
          child: const Icon(Icons.store, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, {bool isActive = false}) {
    Color bgColor = isActive ? Colors.green.shade50 : Colors.grey.shade100;
    Color textColor = isActive ? Colors.green.shade800 : Colors.grey.shade700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: UIUtils.caption(screenType),
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
