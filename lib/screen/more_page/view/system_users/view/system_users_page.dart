import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local_seller/config/app_permissions.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/router/app_routes.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/service/subscription_limit_service.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/bloc/system_user_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/login_approvals/login_approvals_cubit.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/model/system_users_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/repo/system_users_repo.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/widgets/approve_login_bottom_sheet.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/widgets/manage_system_user_bottom_sheet.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/widgets/system_user_card.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/widgets/system_user_detail_bottom_sheet.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/widgets/system_user_status_badges.dart';
import 'package:hyper_local_seller/service/demo_guard.dart';
import 'package:hyper_local_seller/utils/debouncer.dart';
import 'package:hyper_local_seller/utils/image_path.dart';
import 'package:hyper_local_seller/utils/permission_checker.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/card_shimmers.dart';
import 'package:hyper_local_seller/widgets/custom/custom_buttons.dart';
import 'package:hyper_local_seller/widgets/custom/custom_card.dart';
import 'package:hyper_local_seller/widgets/custom/custom_loading_indicator.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/widgets/custom/custom_search_field.dart';
import 'package:hyper_local_seller/widgets/custom/custom_shimmer.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';
import 'package:hyper_local_seller/widgets/ui/empty_state_widget.dart';

class SystemUsersPage extends StatefulWidget {
  const SystemUsersPage({super.key});

  @override
  State<SystemUsersPage> createState() => _SystemUsersPage();
}

class _SystemUsersPage extends State<SystemUsersPage>
    with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _debouncer = Debouncer(milliseconds: 500);
  final Set<int> _choosingIds = {};
  final SubscriptionLimitService _limitService = SubscriptionLimitService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !LoginApprovalsCubit.canView) return;
      context.read<SystemUserBloc>().add(
        FetchSystemUsersEvent(isRefresh: true),
      );
      context.read<LoginApprovalsCubit>().fetch();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        mounted &&
        LoginApprovalsCubit.canView) {
      final bloc = context.read<SystemUserBloc>();
      bloc.add(
        FetchSystemUsersEvent(
          isRefresh: true,
          silent: true,
          search: bloc.state.search,
        ),
      );
      context.read<LoginApprovalsCubit>().fetch();
    }
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<SystemUserBloc>().add(LoadMoreSystemUsersEvent());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Builder(
      builder: (context) {
        return CustomScaffold(
          showAppbar: true,
          title: l10n?.systemUsers ?? 'System User',
          centerTitle: true,
          isHaveSearch: true,
          onSearchChanged: (value) {
            _searchController.text = value;
            _debouncer.run(() {
              context.read<SystemUserBloc>().add(
                FetchSystemUsersEvent(isRefresh: true, search: value),
              );
            });
          },
          body: !LoginApprovalsCubit.canView
              ? EmptyStateWidget(
                  svgPath: ImagesPath.noSearchFoundSvg,
                  title:
                      l10n?.noPermissionViewSystemUsers ??
                      "You don't have permission to view system users",
                )
              : Column(
                  children: [
                    const _PendingLoginApprovalsBanner(),
                    Expanded(child: _buildBody(context, l10n)),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations? l10n) {
    final screenType = context.screenType;

    return BlocConsumer<SystemUserBloc, SystemUserState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage ||
          previous.actionMessage != current.actionMessage,
      listener: (context, state) {
        if (state.errorMessage != null &&
            state.errorMessage!.isNotEmpty &&
            (state.approvalErrorId == null ||
                ModalRoute.of(context)?.isCurrent != false)) {
          showCustomSnackbar(
            context: context,
            message: systemUserErrorMessage(context, state.errorMessage!),
            isError: true,
          );
          context.read<SystemUserBloc>().add(ClearSystemUserMessages());
        }
        if (state.actionMessage != null &&
            state.actionMessage!.isNotEmpty &&
            (state.approvalResult == null ||
                ModalRoute.of(context)?.isCurrent != false)) {
          final result = state.approvalResult;
          showCustomSnackbar(
            context: context,
            message: result == null
                ? state.actionMessage!
                : loginApprovalMessage(context, result),
          );
          if (result != null && ModalRoute.of(context)?.isCurrent == true) {
            context.read<LoginApprovalsCubit>().fetch();
          }
          context.read<SystemUserBloc>().add(ClearSystemUserMessages());
        }
      },
      builder: (context, state) {
        final isLoading = state.status == SystemUserStatus.loading;
        final isFailure = state.status == SystemUserStatus.failure;
        final users = state.users;

        if (isLoading && users.isEmpty) {
          return _buildShimmerList(context);
        }

        if (isFailure && users.isEmpty) {
          return EmptyStateWidget(
            svgPath: ImagesPath.noOrderFoundSvg,
            title: l10n?.somethingWentWrong ?? 'Seems like there is some issue',
            subtitle: l10n?.tryAgainLater ?? 'Please try again later',
            actionText: l10n?.tryAgain ?? 'Try Again',
            onAction: () {
              context.read<SystemUserBloc>().add(
                FetchSystemUsersEvent(isRefresh: true),
              );
            },
          );
        }

        if (users.isEmpty) {
          return EmptyStateWidget(
            svgPath: ImagesPath.noProductFoundSvg,
            title: l10n?.noSystemUsersFound ?? 'No system users found',
            subtitle:
                l10n?.noSystemUsersMessage ??
                'You have not have any system users yet.',
            actionText: l10n?.addNewUser ?? 'Add New User',
            onAction:
                !PermissionChecker.hasPermission(
                  AppPermissions.systemUserCreate,
                )
                ? null
                : () {
                    if (!DemoGuard.shouldProceed(context)) return;

                    _limitService.canCreateSystemUser().then((canCreate) {
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
                              context.pushNamed(AppRoutes.subscriptionPlans);
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
                      _showManageUserBottomSheet(context);
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
                  isLoading && users.isEmpty
                      ? CustomShimmer(
                          width: 150,
                          height: UIUtils.body(screenType),
                        )
                      : Text(
                          l10n?.totalSystemUsersWithCount(state.total) ??
                              "Total System Users (${state.total})",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: UIUtils.body(screenType),
                          ),
                        ),
                  Row(
                    children: [
                      if (isLoading)
                        const Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: CustomLoadingIndicator(
                            size: 16,
                            strokeWidth: 2,
                          ),
                        ),

                      if (PermissionChecker.hasPermission(
                        AppPermissions.systemUserCreate,
                      ))
                        isLoading && users.isEmpty
                            ? CustomShimmer(
                                width: 60,
                                height: 35,
                                borderRadius: BorderRadius.circular(
                                  UIUtils.radiusMD(screenType),
                                ),
                              )
                            : SecondaryButton(
                                text: l10n?.addNewUser ?? "Add New User",
                                icon: Icons.add,
                                onPressed: () async {
                                  if (!DemoGuard.shouldProceed(context)) return;

                                  _limitService.fetchUsageCounts();
                                  final canCreate = await _limitService
                                      .canCreateSystemUser();
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

                                  _showManageUserBottomSheet(context);
                                },
                                height: 35,
                              ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primaryColor,
                onRefresh: () async {
                  context.read<LoginApprovalsCubit>().fetch();
                  context.read<SystemUserBloc>().add(
                    FetchSystemUsersEvent(
                      isRefresh: true,
                      search: _searchController.text,
                    ),
                  );
                },
                child: ListView.separated(
                  controller: _scrollController,
                  padding: UIUtils.cardsPadding(screenType),
                  separatorBuilder: (context, index) =>
                      SizedBox(height: UIUtils.gapMD(screenType)),
                  itemCount: users.length + (state.isActionLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= users.length) {
                      return CardShimmer(
                        type: 'system_user',
                        screenType: screenType,
                      );
                    }

                    final user = state.users[index];
                    return CustomCard(
                      type: CardType.systemUser,
                      screenType: screenType,
                      data: {
                        'id': user.id,
                        'name': user.name,
                        'accessPanel': user.accessPanel,
                        'email': user.email,
                        'mobile': user.mobile,
                        'date': user.createdAt,
                        'systemUserStatus': user.systemUserStatus,
                        'loginApprovalStatus': user.loginApprovalStatus,
                        'loginApprovedUntil': user.loginApprovedUntil,
                        'loginApprovalRequestedAt':
                            user.loginApprovalRequestedAt,
                      },
                      onTap: () =>
                          SystemUserDetailBottomSheet.show(context, user.id),
                      isProcessing: state.processingIds.contains(user.id),
                      onApprove: LoginApprovalsCubit.canManage
                          ? () => _approve(user)
                          : null,
                      onEdit:
                          !PermissionChecker.hasPermission(
                            AppPermissions.systemUserEdit,
                          )
                          ? null
                          : () {
                              if (!DemoGuard.shouldProceed(context)) return;

                              _showManageUserBottomSheet(context, user: user);
                            },
                      onDelete:
                          !PermissionChecker.hasPermission(
                            AppPermissions.systemUserDelete,
                          )
                          ? null
                          : () {
                              if (!DemoGuard.shouldProceed(context)) return;

                              context.read<SystemUserBloc>().add(
                                DeleteSystemUserEvent(id: user.id),
                              );
                            },
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _approve(SystemUser user) async {
    final bloc = context.read<SystemUserBloc>();
    if (_choosingIds.contains(user.id) ||
        bloc.state.processingIds.contains(user.id)) {
      return;
    }
    _choosingIds.add(user.id);
    try {
      final approved = await ApproveLoginBottomSheet.show(
        context,
        name: user.name ?? '',
      );
      if (approved && mounted) {
        bloc.add(ApproveSystemUserLoginEvent(id: user.id));
      }
    } finally {
      _choosingIds.remove(user.id);
    }
  }

  Widget _buildShimmerList(BuildContext context) {
    final screenType = context.screenType;
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: UIUtils.gapMD(screenType)),
      itemCount: 6,
      itemBuilder: (context, index) =>
          CardShimmer(type: 'system_user', screenType: screenType),
    );
  }

  void _showManageUserBottomSheet(BuildContext context, {SystemUser? user}) {
    final bloc = context.read<SystemUserBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ManageSystemUserBottomSheet(user: user, bloc: bloc),
    );
  }
}

/// Shows how many system users are waiting for login approval and opens the
/// approvals list. Hidden when nothing is pending.
class _PendingLoginApprovalsBanner extends StatelessWidget {
  const _PendingLoginApprovalsBanner();

  @override
  Widget build(BuildContext context) {
    final screenType = context.screenType;
    return BlocBuilder<LoginApprovalsCubit, LoginApprovalsState>(
      buildWhen: (previous, current) => previous.total != current.total,
      builder: (context, state) {
        if (!LoginApprovalsCubit.canView || state.total <= 0) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: UIUtils.pagePadding(
            screenType,
          ).copyWith(bottom: UIUtils.gapSM(screenType)),
          child: Material(
            color: Colors.orange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(UIUtils.radiusMD(screenType)),
            child: InkWell(
              borderRadius: BorderRadius.circular(UIUtils.radiusMD(screenType)),
              onTap: () async {
                await context.push(AppRoutes.loginApprovals);
                if (!context.mounted) return;
                final bloc = context.read<SystemUserBloc>();
                bloc.add(
                  FetchSystemUsersEvent(
                    isRefresh: true,
                    silent: true,
                    search: bloc.state.search,
                  ),
                );
                context.read<LoginApprovalsCubit>().fetch();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_clock_outlined, color: Colors.orange),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(
                              context,
                            )?.pendingLoginApprovalCount(state.total) ??
                            '${state.total} login requests awaiting your approval',
                        style: TextStyle(
                          fontSize: UIUtils.body(screenType),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)?.reviewLoginApprovals ??
                          'Review',
                      style: TextStyle(
                        fontSize: UIUtils.body(screenType),
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.primaryColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
