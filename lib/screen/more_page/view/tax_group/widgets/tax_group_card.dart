import 'package:flutter/material.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/screen/more_page/view/tax_group/model/tax_group_model.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';

class TaxGroupCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final ScreenType screenType;

  const TaxGroupCard({super.key, required this.data, required this.screenType});

  @override
  Widget build(BuildContext context) {
    final taxGroup = TaxGroup.fromJson(data);
    final l10n = AppLocalizations.of(context);
    final ratesString =
        taxGroup.taxRates != null && taxGroup.taxRates!.isNotEmpty
        ? taxGroup.taxRates!.map((e) => "${e.title} (${e.rate}%)").join(", ")
        : "—";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          taxGroup.title,
          style: TextStyle(
            fontSize: UIUtils.tileTitle(screenType),
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: UIUtils.gapSM(screenType)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n?.rate ?? "Rate:",
              style: TextStyle(
                fontSize: UIUtils.body(screenType),
                color: Colors.grey.shade700,
              ),
            ),
            Flexible(
              child: Text(
                ratesString,
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: UIUtils.body(screenType),
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade800,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
