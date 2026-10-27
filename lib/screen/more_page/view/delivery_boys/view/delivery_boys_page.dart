import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/router/app_routes.dart';
import 'package:hyper_local_seller/screen/more_page/view/delivery_boys/bloc/delivery_boy_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/delivery_boys/model/delivery_boy_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/delivery_boys/widgets/available_rider_card.dart';
import 'package:hyper_local_seller/screen/more_page/view/delivery_boys/widgets/rider_card.dart';
import 'package:hyper_local_seller/screen/more_page/view/delivery_boys/widgets/rider_actions_sheet.dart';
import 'package:hyper_local_seller/screen/more_page/view/delivery_zone/bloc/delivery_zone_bloc.dart';
import 'package:hyper_local_seller/service/demo_guard.dart';
import 'package:hyper_local_seller/utils/image_path.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/card_shimmers.dart';
import 'package:hyper_local_seller/widgets/custom/custom_alert_dialog.dart';
import 'package:hyper_local_seller/widgets/custom/custom_loading_indicator.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';
import 'package:hyper_local_seller/widgets/ui/empty_state_widget.dart';

class DeliveryBoysPage extends StatefulWidget {
  const DeliveryBoysPage({super.key});
  @override
  State<DeliveryBoysPage> createState() => _DeliveryBoysPageState();
}

class _DeliveryBoysPageState extends State<DeliveryBoysPage>
    with WidgetsBindingObserver {
  final _assignedScroll = ScrollController();
  final _availableScroll = ScrollController();
  final _search = TextEditingController();
  Timer? _debounce;
  Timer? _refreshTimer;
  bool _foreground = true;
  bool _covered = false;
  bool get _visible =>
      mounted &&
      _foreground &&
      !_covered &&
      (ModalRoute.of(context)?.isCurrent ?? false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _search.text = context.read<DeliveryBoyBloc>().state.search;
    _assignedScroll.addListener(() => _loadMore(_assignedScroll, true));
    _availableScroll.addListener(() => _loadMore(_availableScroll, false));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DeliveryBoyBloc>().add(const FetchRiders());
      final zones = context.read<DeliveryZoneBloc>();
      if (zones.state.items.isEmpty && !zones.state.isInitialLoading) {
        zones.add(LoadDeliveryZonesInitial());
      }
      _startTimer();
    });
  }

  void _loadMore(ScrollController controller, bool assigned) {
    if (controller.hasClients &&
        controller.position.pixels >=
            controller.position.maxScrollExtent * .9) {
      context.read<DeliveryBoyBloc>().add(
        assigned ? LoadMoreAssigned() : LoadMoreAvailable(),
      );
    }
  }

  void _startTimer() {
    _refreshTimer?.cancel();
    if (!_visible) return;
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (_visible) _refresh();
    });
  }

  void _refresh() {
    if (mounted) {
      context.read<DeliveryBoyBloc>().add(const FetchRiders(silent: true));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_visible) {
      _refresh();
      _startTimer();
    } else {
      _refreshTimer?.cancel();
    }
  }

  Future<void> _open(String route, {DeliveryBoy? rider}) async {
    _covered = true;
    _refreshTimer?.cancel();
    try {
      await context.pushNamed<bool>(route, extra: rider);
    } finally {
      if (mounted) {
        _covered = false;
        _refresh();
        _startTimer();
      }
    }
  }

  Future<void> _actions(DeliveryBoy rider, String? zoneName) async {
    if (!DeliveryBoyBloc.canManage) return;
    final action = await showModalBottomSheet<RiderAction>(
      context: context,
      isScrollControlled: true,
      builder: (_) => RiderActionsSheet(rider: rider, zoneName: zoneName),
    );
    if (!mounted || !DeliveryBoyBloc.canManage) return;
    switch (action) {
      case RiderAction.approve:
        await RiderActionsSheet.approve(context, rider);
      case RiderAction.reject:
        await RiderActionsSheet.reject(context, rider);
      case RiderAction.delete:
        await RiderActionsSheet.delete(context, rider);
      case RiderAction.edit:
        await _open(AppRoutes.addEditRider, rider: rider);
      case RiderAction.qr:
        if (rider.isVerified) await _open(AppRoutes.riderLoginQr, rider: rider);
      case null:
        break;
    }
  }

  Future<void> _claim(DeliveryBoy rider) async {
    if (!DeliveryBoyBloc.canManage) return;
    final l10n = AppLocalizations.of(context);
    await showAppAlertDialog(
      context: context,
      title: l10n?.riderAddToTeam ?? 'Add to my team',
      message:
          l10n?.riderClaimConfirmation ??
          "This rider will be added to your team. Their login approval and QR will be reset and they'll be logged out.",
      onConfirm: () {
        if (mounted &&
            DeliveryBoyBloc.canManage &&
            DemoGuard.shouldProceed(context)) {
          context.read<DeliveryBoyBloc>().add(ClaimRider(rider.id));
        }
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    _refreshTimer?.cancel();
    _assignedScroll.dispose();
    _availableScroll.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canManage = DeliveryBoyBloc.canManage;
    return CustomScaffold(
      showAppbar: true,
      centerTitle: true,
      title: l10n?.deliveryBoys ?? 'Delivery Boys',
      isHaveSearch: DeliveryBoyBloc.canView,
      searchController: _search,
      searchHint: l10n?.riderSearchHint ?? 'Search name, email or mobile',
      onSearchChanged: (query) {
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 400), () {
          if (mounted) {
            context.read<DeliveryBoyBloc>().add(SearchChanged(query));
          }
        });
      },
      appBarActions: [
        if (canManage)
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n?.riderAddTitle ?? 'Add Delivery Boy',
            onPressed: () => _open(AppRoutes.addEditRider),
          ),
      ],
      body: !DeliveryBoyBloc.canView
          ? EmptyStateWidget(
              svgPath: ImagesPath.noSearchFoundSvg,
              title:
                  l10n?.riderNoViewPermission ??
                  "You don't have permission to view delivery boys",
            )
          : BlocConsumer<DeliveryBoyBloc, DeliveryBoyState>(
              listenWhen: (previous, current) =>
                  previous.errorMessage != current.errorMessage ||
                  previous.actionMessage != current.actionMessage,
              listener: (context, state) {
                if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;
                if (state.errorMessage != null) {
                  showCustomSnackbar(
                    context: context,
                    isError: true,
                    message: state.errorStatusCode == 403
                        ? l10n?.riderNoManagePermission ??
                              "You don't have permission to manage delivery boys"
                        : state.errorMessage!.isEmpty
                        ? l10n?.somethingWentWrong ?? 'Something went wrong'
                        : state.errorMessage!,
                  );
                }
                if (state.actionMessage != null) {
                  showCustomSnackbar(
                    context: context,
                    message: state.actionMessage!,
                  );
                }
                if (state.errorMessage != null || state.actionMessage != null) {
                  context.read<DeliveryBoyBloc>().add(ClearMessages());
                }
              },
              builder: (context, state) => DefaultTabController(
                length: canManage ? 2 : 1,
                child: Column(
                  children: [
                    TabBar(
                      labelColor: AppColors.primaryColor,
                      tabs: [
                        Tab(
                          text:
                              l10n?.riderAssignedTab(state.assignedTotal) ??
                              'My riders (${state.assignedTotal})',
                        ),
                        if (canManage)
                          Tab(
                            text:
                                l10n?.riderAvailableTab(state.availableTotal) ??
                                'Available (${state.availableTotal})',
                          ),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _list(state, true),
                          if (canManage) _list(state, false),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _list(DeliveryBoyState state, bool assigned) {
    final l10n = AppLocalizations.of(context);
    final screenType = context.screenType;
    final riders = assigned ? state.assigned : state.available;
    final loadingMore = assigned
        ? state.isLoadingMoreAssigned
        : state.isLoadingMoreAvailable;
    if ((state.status == DeliveryBoyStatus.initial ||
            state.status == DeliveryBoyStatus.loading) &&
        riders.isEmpty) {
      return ListView.builder(
        padding: UIUtils.cardsPadding(screenType),
        itemCount: 4,
        itemBuilder: (_, _) =>
            CardShimmer(type: 'system_user', screenType: screenType),
      );
    }
    return RefreshIndicator(
      color: AppColors.primaryColor,
      onRefresh: () async {
        final bloc = context.read<DeliveryBoyBloc>();
        bloc.add(const FetchRiders());
        await bloc.stream.firstWhere(
          (value) =>
              value.status != DeliveryBoyStatus.loading && !value.isRefreshing,
        );
      },
      child: ListView.separated(
        key: PageStorageKey(assigned ? 'assigned-riders' : 'available-riders'),
        controller: assigned ? _assignedScroll : _availableScroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: UIUtils.cardsPadding(screenType),
        itemCount: riders.isEmpty ? 1 : riders.length + (loadingMore ? 1 : 0),
        separatorBuilder: (_, _) => SizedBox(height: UIUtils.gapMD(screenType)),
        itemBuilder: (context, index) {
          if (riders.isEmpty) {
            return EmptyStateWidget(
              svgPath: ImagesPath.noSearchFoundSvg,
              title: state.status == DeliveryBoyStatus.failure
                  ? l10n?.somethingWentWrong ?? 'Something went wrong'
                  : state.search.isNotEmpty
                  ? l10n?.riderNoSearchResults ?? 'No riders match your search'
                  : assigned
                  ? l10n?.riderNoAssigned ?? 'No riders yet'
                  : l10n?.riderNoAvailable ?? 'No available riders',
              actionText: state.status == DeliveryBoyStatus.failure
                  ? l10n?.tryAgain ?? 'Try Again'
                  : null,
              onAction: state.status == DeliveryBoyStatus.failure
                  ? () =>
                        context.read<DeliveryBoyBloc>().add(const FetchRiders())
                  : null,
            );
          }
          if (index >= riders.length) {
            return const Center(child: CustomLoadingIndicator());
          }
          final rider = riders[index];
          final busy = state.busyRiderIds.contains(rider.id);
          if (!assigned) {
            return AvailableRiderCard(
              rider: rider,
              isBusy: busy,
              onClaim: () => _claim(rider),
            );
          }
          return BlocBuilder<DeliveryZoneBloc, DeliveryZoneState>(
            builder: (context, zones) {
              String? zoneName;
              for (final zone in zones.items) {
                if (zone.id == rider.deliveryZoneId) {
                  zoneName = zone.name;
                  break;
                }
              }
              return RiderCard(
                rider: rider,
                zoneName: zoneName,
                canManage: DeliveryBoyBloc.canManage,
                isBusy: busy,
                onTap: () => _actions(rider, zoneName),
                onApprove: () => RiderActionsSheet.approve(context, rider),
                onReject: () => RiderActionsSheet.reject(context, rider),
              );
            },
          );
        },
      ),
    );
  }
}
