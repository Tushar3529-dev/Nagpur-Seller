import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/utils/time_utils.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';

class RolesCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final ScreenType screenType;

  const RolesCard({super.key, required this.data, required this.screenType});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data['name'] ?? 'Unnamed Role',
          style: TextStyle(
            fontSize: UIUtils.tileTitle(screenType),
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        SizedBox(height: UIUtils.gapMD(screenType)),

        RichText(
          text: TextSpan(
            text:  l10n?.guardName ?? 'Guard Name: ',
            style: TextStyle(
              fontSize: UIUtils.caption(screenType),
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            children: [
              TextSpan(
                text: data['guard_name'] ?? 'Unnamed Guard',
                style: TextStyle(
                  fontSize: UIUtils.caption(screenType),
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: UIUtils.gapMD(screenType)),

        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  context.pushNamed(
                    '/permissions',
                    queryParameters: {
                      'role': (data['name'] ?? '').toString(),
                      'roleId': (data['id'] ?? '').toString(),
                    },
                  );
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.login_outlined,
                      color: AppColors.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n?.permission ?? 'Permission',
                      style: TextStyle(
                        fontSize: UIUtils.caption(screenType),
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Text(
              TimeUtils.formatTimeAgo(data['created_at'] ?? '', context),
              style: TextStyle(
                fontSize: UIUtils.caption(screenType),
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
