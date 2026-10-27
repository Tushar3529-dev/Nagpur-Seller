import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:hyper_local_seller/config/app_permissions.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/router/app_routes.dart';
import 'package:hyper_local_seller/utils/image_path.dart';
import 'package:hyper_local_seller/utils/permission_checker.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/card_shimmers.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/widgets/custom/custom_shimmer.dart';
import 'package:hyper_local_seller/widgets/ui/empty_state_widget.dart';
import '../cubit/dispatch_cubit.dart';
import '../cubit/rider_availability_cubit.dart';
import '../widgets/dispatch_alert_banner.dart';
import '../widgets/dispatch_order_card.dart';
import '../widgets/dispatch_summary_row.dart';
import '../widgets/rider_availability_section.dart';
import 'dispatch_visibility.dart';

class DispatchCenterPage extends StatefulWidget {
  const DispatchCenterPage({super.key});
  @override
  State<DispatchCenterPage> createState() => _DispatchCenterPageState();
}

class _DispatchCenterPageState extends State<DispatchCenterPage>
    with WidgetsBindingObserver, DispatchVisibility<DispatchCenterPage> {
  late final DispatchCubit _dispatch;
  late final RiderAvailabilityCubit _availability;
  @override
  Set<String> get dispatchVisiblePaths => {AppRoutes.dispatchCenter};
  @override
  void initState() {
    super.initState();
    _dispatch = context.read<DispatchCubit>();
    _availability = context.read<RiderAvailabilityCubit>();
  }

  @override
  void dispatchVisibilityChanged(bool visible) {
    // Each visible page owns a reference to the single dashboard poller.
    if (visible && _dispatch.state.dashboard == null) _dispatch.load();
    _dispatch.setPollingOwner(this, visible: visible);
    _availability.setPollingOwner(this, visible: visible);
  }

  Future<void> _refresh() async {
    await Future.wait([
      _dispatch.refresh(silent: false),
      _availability.refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canView = PermissionChecker.hasPermission(AppPermissions.orderView);
    return CustomScaffold(
      title: l10n?.dispatchCenter ?? 'Dispatch center',
      showAppbar: true,
      centerTitle: true,
      appBarActions: [
        if (canView)
          IconButton(
            onPressed: _refresh,
            tooltip: l10n?.refresh ?? 'Refresh',
            icon: const Icon(Icons.refresh),
          ),
      ],
      body: !canView
          ? EmptyStateWidget(
              svgPath: ImagesPath.noSearchFoundSvg,
              title:
                  l10n?.dispatchNoViewPermission ??
                  "You don't have permission to view orders",
            )
          : BlocBuilder<DispatchCubit, DispatchState>(
              builder: (context, state) {
                final screenType = context.screenType;
                final dashboard = state.dashboard;
                final orders = state.visibleOrders;
                return RefreshIndicator(
                  onRefresh: _refresh,
                  color: AppColors.primaryColor,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: UIUtils.cardsPadding(screenType),
                    children: [
                      if (state.lastUpdated != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            l10n?.dispatchAutoRefresh(
                                  DateFormat(
                                    'HH:mm:ss',
                                  ).format(state.lastUpdated!),
                                ) ??
                                'Updated ${DateFormat('HH:mm:ss').format(state.lastUpdated!)} · auto-refresh every 15s',
                            style: TextStyle(
                              fontSize: UIUtils.caption(screenType),
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      if (dashboard?.summary.hasAlert == true)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: DispatchAlertBanner(
                            count: dashboard!.summary.noNearbyRiders,
                            onTap: () =>
                                _dispatch.setFilter(DispatchFilter.needsAction),
                          ),
                        ),
                      if (dashboard != null)
                        DispatchSummaryRow(
                          summary: dashboard.summary,
                          onFilter: _dispatch.setFilter,
                        )
                      else if (state.isLoading || state.error == null)
                        const CustomShimmer(width: double.infinity, height: 64),
                      RiderAvailabilitySection(
                        hasDispatchAlert: dashboard?.summary.hasAlert ?? false,
                      ),
                      if (dashboard != null) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            for (final filter in DispatchFilter.values)
                              ChoiceChip(
                                label: Text(
                                  '${switch (filter) {
                                    DispatchFilter.all => l10n?.dispatchFilterAll ?? 'All',
                                    DispatchFilter.needsAction => l10n?.dispatchFilterNeedsAction ?? 'Needs action',
                                    DispatchFilter.awaiting => l10n?.dispatchFilterAwaiting ?? 'Awaiting',
                                    DispatchFilter.assigned => l10n?.dispatchFilterAssigned ?? 'Assigned',
                                  }} (${state.copyWith(filter: filter).visibleOrders.length})',
                                ),
                                selected: state.filter == filter,
                                onSelected: (_) => _dispatch.setFilter(filter),
                              ),
                          ],
                        ),
                        SizedBox(height: UIUtils.gapMD(screenType)),
                      ],
                      if (dashboard == null &&
                          (state.isLoading || state.error == null))
                        for (var i = 0; i < 6; i++)
                          CardShimmer(type: 'order', screenType: screenType)
                      else if (dashboard == null && state.error != null)
                        EmptyStateWidget(
                          svgPath: ImagesPath.noSearchFoundSvg,
                          title: state.error!.isEmpty
                              ? l10n?.somethingWentWrong ??
                                    'Something went wrong'
                              : state.error!,
                          actionText: l10n?.retry ?? 'Retry',
                          onAction: _dispatch.load,
                        )
                      else if (dashboard!.orders.isEmpty)
                        EmptyStateWidget(
                          svgPath: ImagesPath.noOrderFoundSvg,
                          title:
                              l10n?.dispatchEmptyTitle ??
                              'No orders waiting for dispatch',
                          subtitle:
                              l10n?.dispatchEmptyBody ??
                              'Bagged orders will appear here while riders are being assigned.',
                          actionText: l10n?.refresh ?? 'Refresh',
                          onAction: _refresh,
                        )
                      else if (orders.isEmpty) ...[
                        Text(
                          l10n?.dispatchEmptyFilter ??
                              'No orders in this filter',
                        ),
                        TextButton(
                          onPressed: () =>
                              _dispatch.setFilter(DispatchFilter.all),
                          child: Text(l10n?.dispatchShowAll ?? 'Show all'),
                        ),
                      ] else
                        for (final order in orders)
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: UIUtils.gapMD(screenType),
                            ),
                            child: DispatchOrderCard(
                              order: order,
                              isPending: state.pendingSelfDeliver.contains(
                                order.orderId,
                              ),
                            ),
                          ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
