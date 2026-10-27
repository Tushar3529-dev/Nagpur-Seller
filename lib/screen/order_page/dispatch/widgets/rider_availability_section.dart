import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_shimmer.dart';
import '../cubit/rider_availability_cubit.dart';
import 'dispatch_summary_row.dart';
import 'rider_availability_tile.dart';

class RiderAvailabilitySection extends StatelessWidget {
  final bool hasDispatchAlert;
  const RiderAvailabilitySection({super.key, required this.hasDispatchAlert});
  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<RiderAvailabilityCubit, RiderAvailabilityState>(
    builder: (context, state) {
      if (state.isForbidden) return const SizedBox.shrink();
      final l10n = AppLocalizations.of(context);
      final cubit = context.read<RiderAvailabilityCubit>();
      final summary = state.data?.summary;
      return Padding(
        padding: EdgeInsets.symmetric(
          vertical: UIUtils.gapMD(context.screenType),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: cubit.toggleExpanded,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n?.dispatchRidersNearStores ??
                                'Riders near your stores',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (state.lastUpdated != null)
                            Text(
                              l10n?.dispatchAvailabilityUpdated(
                                    DateFormat(
                                      'HH:mm:ss',
                                    ).format(state.lastUpdated!),
                                  ) ??
                                  'Updated ${DateFormat('HH:mm:ss').format(state.lastUpdated!)}',
                              style: TextStyle(
                                fontSize: UIUtils.caption(context.screenType),
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      state.expanded ? Icons.expand_less : Icons.expand_more,
                    ),
                  ],
                ),
              ),
            ),
            if (state.isLoading || (state.data == null && state.error == null))
              const CustomShimmer(width: double.infinity, height: 64)
            else if (state.error != null && state.data == null) ...[
              Text(
                state.error!.isEmpty
                    ? l10n?.somethingWentWrong ?? 'Something went wrong'
                    : state.error!,
                style: const TextStyle(color: Colors.red),
              ),
              TextButton(
                onPressed: cubit.load,
                child: Text(l10n?.retry ?? 'Retry'),
              ),
            ] else if (summary != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: DispatchCountTile(
                      label: l10n?.dispatchActiveRiders ?? 'Active',
                      count: summary.activeRiders,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DispatchCountTile(
                      label:
                          l10n?.dispatchAvailableNearby ?? 'Available nearby',
                      count: summary.availableRidersInRadius,
                      color: summary.availableRidersInRadius > 0
                          ? Colors.green
                          : hasDispatchAlert
                          ? Colors.red
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DispatchCountTile(
                      label: l10n?.dispatchOfflineRiders ?? 'Offline',
                      count: summary.inactiveRiders,
                    ),
                  ),
                ],
              ),
              if (state.expanded)
                if (state.data!.riders.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      l10n?.dispatchNoRidersFound ??
                          'No riders found for your stores and delivery zones.',
                    ),
                  )
                else ...[
                  for (final rider in state.sortedRiders)
                    RiderAvailabilityTile(rider: rider),
                ],
            ],
          ],
        ),
      );
    },
  );
}
