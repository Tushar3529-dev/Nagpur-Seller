import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local_seller/bloc/screen_size/screen_size_bloc.dart';
import 'package:hyper_local_seller/bloc/store_switcher/store_switcher_cubit.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/router/app_routes.dart';
import 'package:hyper_local_seller/screen/home_page/bloc/home_page/home_page_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/add_store/view/add_store_page.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/bloc/stores_bloc.dart';
import 'package:hyper_local_seller/service/demo_guard.dart';
import 'package:hyper_local_seller/utils/permission_checker.dart';
import 'package:hyper_local_seller/config/app_permissions.dart';
import 'package:hyper_local_seller/service/external_link.dart';
import 'package:hyper_local_seller/utils/image_path.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/card_shimmers.dart';
import 'package:hyper_local_seller/widgets/custom/custom_buttons.dart';
import 'package:hyper_local_seller/widgets/custom/custom_card.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/widgets/custom/custom_shimmer.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';
import 'package:hyper_local_seller/utils/debouncer.dart';
import 'package:hyper_local_seller/widgets/custom/custom_filter_sheet.dart';
import 'package:hyper_local_seller/widgets/ui/empty_state_widget.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/service/subscription_limit_service.dart';

class StoresPage extends StatefulWidget {
  const StoresPage({super.key});

  @override
  State<StoresPage> createState() => _StoresPageState();
}

class _StoresPageState extends State<StoresPage> {
  final Debouncer _debouncer = Debouncer(milliseconds: 500);
  final SubscriptionLimitService _limitService = SubscriptionLimitService();

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    context.read<StoresBloc>().add(LoadStoresInitial());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocListener<StoresBloc, StoresState>(
      listenWhen: (previous, current) =>
          previous.operationSuccess != current.operationSuccess &&
          current.operationSuccess != null,
      listener: (context, state) {
        if (state.operationSuccess == true && state.operationMessage != null) {
          showCustomSnackbar(
            context: context,
            message: state.operationMessage!,
          );
          context.read<StoresBloc>().add(ClearStoresOperation());
        } else if (state.operationSuccess == false &&
            state.operationMessage != null) {
          showCustomSnackbar(
            context: context,
            message: state.operationMessage!,
            isError: true,
          );
          context.read<StoresBloc>().add(ClearStoresOperation());
        }
      },
      child: BlocBuilder<ScreenSizeBloc, ScreenSizeState>(
        builder: (context, screenSizeState) {
          final screenType = screenSizeState.screenType;

          return CustomScaffold(
            showAppbar: true,
            title: l10n?.stores ?? "Stores",
            centerTitle: true,
            isHaveSearch: true,
            onSearchChanged: (value) {
              _debouncer.run(() {
                context.read<StoresBloc>().add(SearchStores(value));
              });
            },
            showFilters: true,
            filterType: FilterType.store,
            body: BlocBuilder<StoresBloc, StoresState>(
              builder: (context, state) {
                if (!state.isInitialLoading && state.items.isEmpty) {
                  return EmptyStateWidget(
                    svgPath: ImagesPath.noProductFoundSvg,
                    title: l10n?.noStoresFound ?? 'No Store Found',
                    subtitle:
                    l10n?.noStoresAddedYet ??
                        'You have not added any store yet.',
                    actionText: l10n?.addStore ?? 'Add Store',
                    onAction: () {
                      if (!PermissionChecker.hasPermission(
                        AppPermissions.storeCreate,
                      )) {
                        showCustomSnackbar(
                          context: context,
                          message:
                          l10n?.noPermissionCreateStore ??
                              "You don't have permission to create stores",
                          isWarning: true,
                        );
                        return;
                      }
                      if (!DemoGuard.shouldProceed(context)) return;

                      _limitService.canCreateStore().then((canCreate) {
                        if (!context.mounted) return;
                        if (!canCreate) {
                          if (HiveStorage.activePlanId == null) {
                            showCustomSnackbar(
                              context: context,
                              message: "you don't have any active plan please buy one",
                              isError: true,
                              actionLabel: 'view',
                              onAction: () {
                                context.push(AppRoutes.subscriptionPlans);
                              },
                            );
                          } else {
                            showCustomSnackbar(
                              context: context,
                              message:
                              l10n?.limitReached ??
                                  "You have reached your plan limit",
                              isWarning: true,
                            );
                          }
                          return;
                        }
                        context.push(AppRoutes.addStore);
                      });
                    },
                  );
                }

                return Column(
                  children: [
                    Padding(
                      padding: UIUtils.pagePadding(screenType),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          state.isInitialLoading && state.items.isEmpty
                              ? CustomShimmer(
                            width: 150,
                            height: UIUtils.sectionTitle(screenType),
                          )
                              : Text(
                            "${l10n?.total ?? "Total"} ${l10n?.stores ?? "Stores"} (${state.total ?? state.items.length})",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: UIUtils.body(screenType),
                            ),
                          ),
                          state.isInitialLoading && state.items.isEmpty
                              ? CustomShimmer(
                            width: 120,
                            height: 40,
                            borderRadius: BorderRadius.circular(
                              UIUtils.radiusMD(screenType),
                            ),
                          )
                              : SecondaryButton(
                            text: l10n?.addStore ?? "Add Store",
                            icon: Icons.add,
                            onPressed: () async {
                              if (!PermissionChecker.hasPermission(
                                AppPermissions.storeCreate,
                              )) {
                                showCustomSnackbar(
                                  context: context,
                                  message:
                                  l10n?.noPermissionCreateStore ??
                                      "You don't have permission to create stores",
                                  isWarning: true,
                                );
                                return;
                              }
                              if (!DemoGuard.shouldProceed(context)) {
                                return;
                              }
                              _limitService.fetchUsageCounts();
                              final canCreate = await _limitService
                                  .canCreateStore();
                              if (!context.mounted) return;

                              if (!canCreate) {
                                if (HiveStorage.activePlanId == null) {
                                  showCustomSnackbar(
                                    context: context,
                                    message:
                                    "you don't have any active plan please buy one",
                                    isError: true,
                                    actionLabel: 'view',
                                    onAction: () {
                                      context.push(
                                        AppRoutes.subscriptionPlans,
                                      );
                                    },
                                  );
                                } else {
                                  showCustomSnackbar(
                                    context: context,
                                    message:
                                    l10n?.limitReached ??
                                        "You have reached your plan limit",
                                    isWarning: true,
                                  );
                                }
                                return;
                              }

                              final result = await context.push(
                                AppRoutes.addStore,
                              );
                              if (result == true) {
                                if (context.mounted) {
                                  // Refresh Stores list in the current page
                                  context.read<StoresBloc>().add(
                                    RefreshStores(),
                                  );

                                  // Refresh the global store switcher
                                  context.read<StoreSwitcherCubit>().loadStores();

                                  // Refresh current home page data
                                  final selectedStore = context
                                      .read<StoreSwitcherCubit>()
                                      .state
                                      .selectedStore;
                                  if (selectedStore != null) {
                                    context.read<HomePageBloc>().add(
                                      FetchHomePageData(
                                        storeId: selectedStore.id,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                            height: 35,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        color: AppColors.primaryColor,
                        onRefresh: () async {
                          context.read<StoresBloc>().add(RefreshStores());
                        },
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (notification) {
                            if (notification is ScrollEndNotification &&
                                notification.metrics.extentAfter == 0) {
                              context.read<StoresBloc>().add(LoadMoreStores());
                            }
                            return false;
                          },
                          child: state.isInitialLoading
                              ? ListView.separated(
                            padding: UIUtils.cardsPadding(screenType),
                            separatorBuilder: (context, index) =>
                                SizedBox(
                                  height: UIUtils.gapMD(screenType),
                                ),
                            itemCount: 10,
                            itemBuilder: (context, index) => CardShimmer(
                              type: 'store',
                              screenType: screenType,
                            ),
                          )
                              : ListView.separated(
                            padding: UIUtils.cardsPadding(screenType),
                            separatorBuilder: (context, index) =>
                                SizedBox(
                                  height: UIUtils.gapMD(screenType),
                                ),
                            itemCount:
                            state.items.length +
                                (state.hasMore
                                    ? (state.isPaginating ? 10 : 1)
                                    : 0),
                            itemBuilder: (context, index) {
                              if (index >= state.items.length) {
                                return CardShimmer(
                                  type: 'store',
                                  screenType: screenType,
                                );
                              }

                              final store = state.items[index];
                              return CustomCard(
                                type: CardType.store,
                                data: store.toJson(),
                                screenType: screenType,
                                onEdit: () async {
                                  if (!PermissionChecker.hasPermission(
                                    AppPermissions.storeEdit,
                                  )) {
                                    showCustomSnackbar(
                                      context: context,
                                      message:
                                      l10n?.noPermissionEditStore ??
                                          "You don't have permission to edit stores",
                                      isWarning: true,
                                    );
                                    return;
                                  }
                                  if (!DemoGuard.shouldProceed(context)) {
                                    return;
                                  }

                                  final result =
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          AddStorePage(store: store),
                                    ),
                                  );
                                  if (result == true) {
                                    if (context.mounted) {
                                      // Refresh Stores list in the current page
                                      context.read<StoresBloc>().add(
                                        RefreshStores(),
                                      );

                                      // Refresh the global store switcher
                                      context.read<StoreSwitcherCubit>().loadStores();

                                      // Refresh current home page data
                                      final selectedStore = context
                                          .read<StoreSwitcherCubit>()
                                          .state
                                          .selectedStore;
                                      if (selectedStore != null) {
                                        context.read<HomePageBloc>().add(
                                          FetchHomePageData(
                                            storeId: selectedStore.id,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                                onDelete: () {
                                  if (!PermissionChecker.hasPermission(
                                    AppPermissions.storeDelete,
                                  )) {
                                    showCustomSnackbar(
                                      context: context,
                                      message:
                                      l10n?.noPermissionDeleteStore ??
                                          "You don't have permission to delete stores",
                                      isWarning: true,
                                    );
                                    return;
                                  }
                                  if (!DemoGuard.shouldProceed(context)) {
                                    return;
                                  }

                                  context.read<StoresBloc>().add(
                                    DeleteStore(store.id),
                                  );
                                },
                                onToggleStatus: (status) {
                                  if (!PermissionChecker.hasPermission(
                                    AppPermissions.storeEdit,
                                  )) {
                                    showCustomSnackbar(
                                      context: context,
                                      message:
                                      l10n?.noPermissionEditStore ??
                                          "You don't have permission to update store status",
                                      isWarning: true,
                                    );
                                    return;
                                  }
                                  if (!DemoGuard.shouldProceed(context)) {
                                    return;
                                  }

                                  context.read<StoresBloc>().add(
                                    ToggleStoreStatus(store.id, status),
                                  );
                                },
                                extraWidgets: Padding(
                                  padding: UIUtils.cardPadding(
                                    screenType,
                                  ),
                                  child: Row(
                                    children: [
                                      if (store.verificationStatus !=
                                          'not_approved' &&
                                          store.visibilityStatus !=
                                              'draft')
                                        Expanded(
                                          child: (() {
                                            final isOnline =
                                                store.status?.status
                                                    ?.toLowerCase() ==
                                                    'online';
                                            return SecondaryButton(
                                              text: isOnline
                                                  ? l10n?.goOffline ??
                                                  'Go Offline'
                                                  : l10n?.goOnline ??
                                                  'Go Online',
                                              icon: isOnline
                                                  ? Icons.signal_wifi_off
                                                  : Icons.wifi,
                                              onPressed: () {
                                                if (!DemoGuard.shouldProceed(
                                                  context,
                                                )) {
                                                  return;
                                                } else {
                                                  context
                                                      .read<StoresBloc>()
                                                      .add(
                                                    ToggleStoreStatus(
                                                      store.id,
                                                      isOnline
                                                          ? 'offline'
                                                          : 'online',
                                                    ),
                                                  );
                                                }
                                              },
                                              foregroundColor: isOnline
                                                  ? Colors.orange
                                                  : Colors.green,
                                              borderColor: isOnline
                                                  ? Colors.orange
                                                  : Colors.green,
                                            );
                                          })(),
                                        ),
                                      if (store.verificationStatus !=
                                          'not_approved' &&
                                          store.visibilityStatus !=
                                              'draft')
                                        const SizedBox(width: 12),
                                      Expanded(
                                        child: PrimaryButton(
                                          text:
                                          l10n?.storeConfig ??
                                              "Store Config",
                                          icon: Icons.build_outlined,
                                          onPressed: () {
                                            if (!DemoGuard.shouldProceed(
                                              context,
                                            )) {
                                              return;
                                            } else {
                                              ExternalLink.toStoreConfiguration(
                                                context,
                                                store.id.toString(),
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
