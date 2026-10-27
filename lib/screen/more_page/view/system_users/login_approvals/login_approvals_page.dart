import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/bloc/system_user_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/login_approvals/login_approvals_cubit.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/model/login_approval_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/widgets/approve_login_bottom_sheet.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/widgets/system_user_detail_bottom_sheet.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/widgets/system_user_status_badges.dart';
import 'package:hyper_local_seller/service/demo_guard.dart';
import 'package:hyper_local_seller/utils/image_path.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/card_shimmers.dart';
import 'package:hyper_local_seller/widgets/custom/custom_loading_indicator.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';
import 'package:hyper_local_seller/widgets/ui/empty_state_widget.dart';
import 'package:intl/intl.dart';

/// Pending login requests from system users, with approve / disapprove.
class LoginApprovalsPage extends StatefulWidget {
  const LoginApprovalsPage({super.key});

  @override
  State<LoginApprovalsPage> createState() => _LoginApprovalsPageState();
}

class _LoginApprovalsPageState extends State<LoginApprovalsPage>
    with WidgetsBindingObserver {
  final Set<int> _choosingIds = {};
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      final position = _scrollController.position;
      if (position.pixels >= position.maxScrollExtent * 0.9) {
        context.read<LoginApprovalsCubit>().loadMore();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<LoginApprovalsCubit>().fetch();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<LoginApprovalsCubit>().fetch();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      showAppbar: true,
      title:
          AppLocalizations.of(context)?.loginApprovalsTitle ??
          'Login Approvals',
      centerTitle: true,
      body: LoginApprovalsCubit.canView
          ? _buildBody(context)
          : EmptyStateWidget(
              svgPath: ImagesPath.noSearchFoundSvg,
              title:
                  AppLocalizations.of(
                    context,
                  )?.noPermissionViewLoginApprovals ??
                  "You don't have permission to view login approvals",
            ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final screenType = context.screenType;

    return BlocConsumer<LoginApprovalsCubit, LoginApprovalsState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage ||
          previous.actionMessage != current.actionMessage ||
          previous.lastResult != current.lastResult,
      listener: (context, state) {
        final result = state.lastResult;
        if (result != null && state.actionMessage != null) {
          try {
            final bloc = context.read<SystemUserBloc>();
            bloc.add(ApplyLoginApprovalResultEvent(result));
            bloc.add(
              FetchSystemUsersEvent(
                isRefresh: true,
                silent: true,
                search: bloc.state.search,
              ),
            );
          } catch (_) {
            // The inbox can also be mounted without the app-wide users bloc.
          }
        }
        // Load failures are shown by the empty state instead.
        if (state.errorMessage != null &&
            (state.status != LoginApprovalsStatus.failure ||
                state.items.isNotEmpty)) {
          showCustomSnackbar(
            context: context,
            message: systemUserErrorMessage(context, state.errorMessage!),
            isError: true,
          );
          context.read<LoginApprovalsCubit>().clearMessages();
        } else if (state.actionMessage != null) {
          showCustomSnackbar(
            context: context,
            message: result == null
                ? state.actionMessage!
                : loginApprovalMessage(context, result),
          );
          context.read<LoginApprovalsCubit>().clearMessages();
        }
      },
      builder: (context, state) {
        final cubit = context.read<LoginApprovalsCubit>();

        if (state.items.isEmpty &&
            (state.status == LoginApprovalsStatus.loading ||
                state.status == LoginApprovalsStatus.initial)) {
          return ListView.builder(
            padding: UIUtils.cardsPadding(screenType),
            itemCount: 4,
            itemBuilder: (context, index) =>
                CardShimmer(type: 'system_user', screenType: screenType),
          );
        }

        if (state.items.isEmpty &&
            state.status == LoginApprovalsStatus.failure) {
          return EmptyStateWidget(
            svgPath: ImagesPath.noOrderFoundSvg,
            title: state.errorMessage != null
                ? systemUserErrorMessage(context, state.errorMessage!)
                : AppLocalizations.of(context)?.somethingWentWrong ??
                      'Seems like there is some issue',
            subtitle:
                AppLocalizations.of(context)?.tryAgainLater ??
                'Please try again later',
            actionText: AppLocalizations.of(context)?.tryAgain ?? 'Try Again',
            onAction: cubit.fetch,
          );
        }

        return RefreshIndicator(
          color: AppColors.primaryColor,
          onRefresh: cubit.fetch,
          child: state.items.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 60),
                    EmptyStateWidget(
                      svgPath: ImagesPath.noSearchFoundSvg,
                      title:
                          AppLocalizations.of(
                            context,
                          )?.noPendingLoginRequests ??
                          'No pending login requests',
                      subtitle:
                          AppLocalizations.of(
                            context,
                          )?.loginRequestsAppearHere ??
                          'Requests from your system users will appear here.',
                    ),
                  ],
                )
              : ListView.separated(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: UIUtils.cardsPadding(screenType),
                  itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
                  separatorBuilder: (_, _) =>
                      SizedBox(height: UIUtils.gapMD(screenType)),
                  itemBuilder: (context, index) {
                    if (index >= state.items.length) {
                      return const Center(child: CustomLoadingIndicator());
                    }
                    final request = state.items[index];
                    return _LoginApprovalCard(
                      request: request,
                      isProcessing: state.processingIds.contains(
                        request.userId,
                      ),
                      onApprove: () => _approve(context, request),
                      onDisapprove: () => _disapprove(context, request),
                    );
                  },
                ),
        );
      },
    );
  }

  Future<void> _approve(
    BuildContext context,
    LoginApprovalRequest request,
  ) async {
    final cubit = context.read<LoginApprovalsCubit>();
    if (_choosingIds.contains(request.userId) ||
        cubit.state.processingIds.contains(request.userId)) {
      return;
    }
    _choosingIds.add(request.userId);
    try {
      final approved = await ApproveLoginBottomSheet.show(
        context,
        name: request.name,
      );
      if (approved && context.mounted) await cubit.approve(request.userId);
    } finally {
      _choosingIds.remove(request.userId);
    }
  }

  Future<void> _disapprove(
    BuildContext context,
    LoginApprovalRequest request,
  ) async {
    final cubit = context.read<LoginApprovalsCubit>();
    if (_choosingIds.contains(request.userId) ||
        cubit.state.processingIds.contains(request.userId) ||
        !canManageSystemUserLogin(context)) {
      return;
    }
    _choosingIds.add(request.userId);
    try {
      final confirmed = await confirmRevokeSystemUserLogin(
        context,
        request.name,
      );
      if (confirmed && context.mounted && canManageSystemUserLogin(context)) {
        await cubit.disapprove(request.userId);
      }
    } finally {
      _choosingIds.remove(request.userId);
    }
  }
}

class _LoginApprovalCard extends StatelessWidget {
  final LoginApprovalRequest request;
  final bool isProcessing;
  final VoidCallback onApprove;
  final VoidCallback onDisapprove;

  const _LoginApprovalCard({
    required this.request,
    required this.isProcessing,
    required this.onApprove,
    required this.onDisapprove,
  });

  @override
  Widget build(BuildContext context) {
    final screenType = context.screenType;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = theme.colorScheme.onSurfaceVariant;

    Widget detail(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: muted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: UIUtils.body(screenType),
                color: muted,
              ),
            ),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.mainDarkContainerBgColor : Colors.white,
        borderRadius: BorderRadius.circular(UIUtils.radiusMD(screenType)),
        border: Border.all(color: AppColors.lightOutlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.name,
                  style: TextStyle(
                    fontSize: UIUtils.tileTitle(screenType),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              LoginApprovalBadge(request.status),
            ],
          ),
          if (request.email != null && request.email!.isNotEmpty)
            detail(Icons.email_outlined, request.email!),
          if (request.mobile != null && request.mobile!.isNotEmpty)
            detail(Icons.phone_outlined, request.mobile!),
          if (request.requestedAt != null)
            detail(
              Icons.schedule,
              AppLocalizations.of(context)?.loginRequestedAt(
                    DateFormat(
                      'dd MMM yyyy, hh:mm a',
                    ).format(request.requestedAt!.toLocal()),
                  ) ??
                  'Requested ${DateFormat('dd MMM yyyy, hh:mm a').format(request.requestedAt!.toLocal())}',
            ),
          const SizedBox(height: 12),
          if (!LoginApprovalsCubit.canManage)
            const SizedBox.shrink()
          else if (isProcessing)
            const SizedBox(
              height: 40,
              child: Center(
                child: CustomLoadingIndicator(size: 20, strokeWidth: 2),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDisapprove,
                    icon: const Icon(Icons.close, size: 18),
                    label: Text(
                      AppLocalizations.of(context)?.riderDisapprove ??
                          'Disapprove',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(
                      AppLocalizations.of(context)?.riderApprove ?? 'Approve',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
