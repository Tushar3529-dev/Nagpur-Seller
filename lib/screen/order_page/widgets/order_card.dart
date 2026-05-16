// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/utils/time_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_buttons.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_card.dart';
import 'package:hyper_local_seller/widgets/custom/custom_network_image.dart';
import 'package:hyper_local_seller/extensions/l10n_extensions.dart';

class OrderCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final ScreenType screenType;
  final Function(String status)? onStatusUpdate;

  const OrderCard({
    super.key,
    required this.data,
    required this.screenType,
    this.onStatusUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final status = (data['status'] ?? '').toString().toLowerCase();

    // Status colors
    Color statusColor = Colors.grey;
    Color statusBgColor = Colors.grey.withValues(alpha:0.1);

    switch (status) {
      case 'pending':
      case 'awaiting_store_response':
      case 'partially_accepted':
        statusColor = Colors.orange;
        statusBgColor = Colors.orange.withValues(alpha:0.1);
        break;
      case 'accepted':
        statusColor = Colors.green;
        statusBgColor = Colors.green.withValues(alpha:0.1);
        break;
      case 'processing':
      case 'preparing':
        statusColor = Colors.blue;
        statusBgColor = Colors.blue.withValues(alpha:0.1);
        break;
      case 'rejected':
      case 'cancelled': // Corrected 'calcelled' to 'cancelled'
        statusColor = Colors.red;
        statusBgColor = Colors.red.withValues(alpha:0.1);
        break;
      case 'completed':
      case 'delivered':
        statusColor = Colors.green;
        statusBgColor = Colors.green.withValues(alpha:0.1);
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Info
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(),
            SizedBox(width: UIUtils.gapMD(screenType)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          data['title'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: UIUtils.body(screenType),
                            fontWeight: UIUtils.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          l10n?.translateEnum(status) ?? status,
                          style: TextStyle(
                            fontSize: UIUtils.caption(screenType),
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${l10n?.qtyWithCount(data['quantity']) ?? 'Qty: ${data['quantity']}'} × ${data['subtotal']}',
                    style: TextStyle(
                      fontSize: UIUtils.caption(screenType),
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n?.deliveryType ?? 'Delivery Type: ',
              style: TextStyle(
                fontSize: UIUtils.caption(screenType),
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            Text(
              data['isRushOrder'] == true
                  ? (l10n?.rushDelivery ?? 'Rush Delivery')
                  : (l10n?.standardDelivery ?? 'Standard Delivery'),
              style: TextStyle(
                fontSize: UIUtils.caption(screenType),
                color: Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              TimeUtils.formatTimeAgo(
                data['created_at'],
                context,
                type: TimeFormatType.order,
              ),
              style: TextStyle(
                fontSize: UIUtils.caption(screenType),
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),


        // Buttons
        if (status == 'pending' ||
            status == 'awaiting_store_response' ||
            status == 'partially_accepted') ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  text: l10n?.reject ?? 'Reject',
                  onPressed: () => onStatusUpdate?.call('reject'),
                  foregroundColor: Colors.red,
                  borderColor: Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  text: l10n?.accept ?? 'Accept',
                  onPressed: () => onStatusUpdate?.call('accept'),
                  backgroundColor: Colors.green,
                ),
              ),
            ],
          ),
        ] else if (status == 'accepted') ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              text: l10n?.markAsPreparing ?? 'Mark as Preparing',
              onPressed: () => onStatusUpdate?.call('preparing'),
              backgroundColor: Colors.blue,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(UIUtils.radiusSM(screenType)),
      child: CustomNetworkImage(
        imageUrl: data['image'] ?? '',
        width: UIUtils.avatarXL(screenType),
        height: UIUtils.avatarXL(screenType),
        fit: BoxFit.cover,
      ),
    );
  }
}
