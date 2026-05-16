import 'package:flutter/material.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/model/system_users_model.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/utils/time_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_drop_menu.dart';

class SystemUserCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final ScreenType screenType;

  const SystemUserCard({
    super.key,
    required this.data,
    required this.screenType,
  });

  @override
  Widget build(BuildContext context) {
    final screenType = context.screenType;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              data['name'] ?? '',
              style: TextStyle(
                fontSize: UIUtils.tileTitle(screenType),
                fontWeight: FontWeight.bold,
              ),
            ),
            if (data['accessPanel'] != null) ...[
              const SizedBox(width: 8),
              Text(
                '(${data['accessPanel']})',
                style: TextStyle(
                  fontSize: UIUtils.body(screenType),
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: UIUtils.gapMD(screenType)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                data['email'] ?? '',
                style: TextStyle(
                  fontSize: UIUtils.body(screenType),
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              data['mobile'],
              style: TextStyle(
                fontSize: UIUtils.body(screenType),
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        SizedBox(height: UIUtils.gapMD(screenType)),
        Text(
          TimeUtils.formatTimeAgo(data['date'] ?? '', context),
          style: TextStyle(
            fontSize: UIUtils.body(screenType),
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
