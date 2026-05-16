// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';

class FaqCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final ScreenType screenType;

  const FaqCard({
    super.key,
    required this.data,
    required this.screenType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final question = data['question'] ?? '';
    final answer = data['answer'] ?? '';
    final status = data['status'] ?? 'pending';
    final productName = data['product_name'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (productName != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              productName,
              style: TextStyle(
                fontSize: UIUtils.caption(screenType),
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: UIUtils.gapSM(screenType)),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                question,
                style: TextStyle(
                  fontSize: UIUtils.tileTitle(screenType),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildStatusChip(status),
          ],
        ),
        SizedBox(height: UIUtils.gapMD(screenType)),
        Text(
          l10n?.answerLabel ?? 'Answer:',
          style: TextStyle(
            fontSize: UIUtils.body(screenType),
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        SizedBox(height: UIUtils.gapXS(screenType)),
        Text(
          answer,
          style: TextStyle(
            fontSize: UIUtils.body(screenType),
            color: theme.textTheme.bodyMedium?.color,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    final bool isActive = status.toLowerCase() == 'active';
    final Color bgColor = isActive ? Colors.green.shade50 : Colors.orange.shade50;
    final Color textColor = isActive ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: UIUtils.caption(screenType),
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
