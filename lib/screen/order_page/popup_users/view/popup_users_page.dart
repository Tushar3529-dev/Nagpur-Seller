import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/router/app_routes.dart';
import 'package:hyper_local_seller/screen/order_page/dispatch/view/dispatch_visibility.dart';
import 'package:hyper_local_seller/screen/order_page/dispatch/widgets/dispatch_summary_row.dart';
import 'package:hyper_local_seller/utils/image_path.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/widgets/custom/custom_shimmer.dart';
import 'package:hyper_local_seller/widgets/ui/empty_state_widget.dart';
import '../cubit/popup_users_cubit.dart';
import '../widgets/popup_user_tile.dart';

/// Main seller owner only: which system users can receive incoming-order
/// popups right now, and why the others can't. Refreshes every 30 seconds
/// while on screen.
class PopupUsersPage extends StatefulWidget {
  const PopupUsersPage({super.key});

  @override
  State<PopupUsersPage> createState() => _PopupUsersPageState();
}

class _PopupUsersPageState extends State<PopupUsersPage>
    with WidgetsBindingObserver, DispatchVisibility<PopupUsersPage> {
  late final PopupUsersCubit _cubit;

  @override
  Set<String> get dispatchVisiblePaths => {AppRoutes.popupUsers};

  @override
  void initState() {
    super.initState();
    _cubit = context.read<PopupUsersCubit>();
  }

  @override
  void dispatchVisibilityChanged(bool visible) {
    if (visible) {
      _cubit.startPolling();
    } else {
      _cubit.stopPolling();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CustomScaffold(
      title: l10n?.popupUsersTitle ?? 'System user availability',
      showAppbar: true,
      centerTitle: true,
      appBarActions: [
        IconButton(
          onPressed: _cubit.refresh,
          tooltip: l10n?.refresh ?? 'Refresh',
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: BlocBuilder<PopupUsersCubit, PopupUsersState>(
        builder: (context, state) {
          final screenType = context.screenType;
          final data = state.data;
          if (state.isForbidden) {
            return EmptyStateWidget(
              svgPath: ImagesPath.noSearchFoundSvg,
              title:
                  l10n?.popupUsersOwnerOnly ??
                  'Only the store owner can view system user availability',
            );
          }
          if (data == null && state.error != null) {
            return EmptyStateWidget(
              svgPath: ImagesPath.noSearchFoundSvg,
              title: state.error!.isEmpty
                  ? l10n?.somethingWentWrong ?? 'Something went wrong'
                  : state.error!,
              actionText: l10n?.retry ?? 'Retry',
              onAction: _cubit.refresh,
            );
          }
          final summary = data?.summary;
          return RefreshIndicator(
            onRefresh: _cubit.refresh,
            color: AppColors.primaryColor,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: UIUtils.cardsPadding(screenType),
              children: [
                if (state.lastUpdated != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      l10n?.popupUsersAutoRefresh(
                            DateFormat('HH:mm:ss').format(state.lastUpdated!),
                          ) ??
                          'Updated ${DateFormat('HH:mm:ss').format(state.lastUpdated!)} · auto-refresh every 30s',
                      style: TextStyle(
                        fontSize: UIUtils.caption(screenType),
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                if (summary == null)
                  const CustomShimmer(width: double.infinity, height: 64)
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final (i, (label, count, color)) in <(
                        String,
                        int,
                        Color?,
                      )>[
                        (
                          l10n?.popupUsersTotal ?? 'Total',
                          summary.totalSystemUsers,
                          null,
                        ),
                        (
                          l10n?.popupUsersEligible ?? 'Eligible',
                          summary.eligibleUsers,
                          summary.eligibleUsers > 0
                              ? Colors.green
                              : Colors.red,
                        ),
                        (
                          l10n?.popupUsersActive ?? 'Active',
                          summary.activeUsers,
                          null,
                        ),
                        (
                          l10n?.popupUsersBusy ?? 'Busy',
                          summary.busyUsers,
                          Colors.blue,
                        ),
                        (
                          l10n?.popupUsersInactive ?? 'Inactive',
                          summary.inactiveUsers,
                          Colors.grey,
                        ),
                      ].indexed) ...[
                        if (i > 0) const SizedBox(width: 6),
                        Expanded(
                          child: DispatchCountTile(
                            label: label,
                            count: count,
                            color: color,
                          ),
                        ),
                      ],
                    ],
                  ),
                if (data != null) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: UIUtils.gapMD(screenType),
                    ),
                    child: Text(
                      l10n?.popupUsersRules(
                            data.pickupRadiusMeters,
                            data.locationFreshnessMinutes,
                          ) ??
                          'New orders go to one eligible system user within '
                              '${data.pickupRadiusMeters} m of the order\'s '
                              'store whose location was updated in the last '
                              '${data.locationFreshnessMinutes} min. You get '
                              'them only when no system user is eligible.',
                      style: TextStyle(
                        fontSize: UIUtils.caption(screenType),
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (data.users.isEmpty)
                    EmptyStateWidget(
                      svgPath: ImagesPath.noSearchFoundSvg,
                      title: l10n?.popupUsersEmpty ?? 'No system users yet',
                    )
                  else
                    for (final user in state.sortedUsers)
                      PopupUserTile(
                        user: user,
                        pickupRadiusMeters: data.pickupRadiusMeters,
                      ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
