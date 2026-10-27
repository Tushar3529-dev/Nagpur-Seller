import 'package:flutter/material.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/screen/more_page/view/delivery_boys/model/delivery_boy_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/delivery_boys/widgets/rider_card.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';

class AvailableRiderCard extends StatelessWidget {
  final DeliveryBoy rider;
  final bool isBusy;
  final VoidCallback onClaim;
  const AvailableRiderCard({
    super.key,
    required this.rider,
    required this.isBusy,
    required this.onClaim,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      RiderCard(
        rider: rider,
        canManage: false,
        showApproval: false,
        isBusy: isBusy,
      ),
      Padding(
        padding: EdgeInsets.only(top: UIUtils.gapSM(context.screenType)),
        child: FilledButton(
          onPressed: isBusy ? null : onClaim,
          child: Text(
            AppLocalizations.of(context)?.riderAddToTeam ?? 'Add to my team',
          ),
        ),
      ),
    ],
  );
}
