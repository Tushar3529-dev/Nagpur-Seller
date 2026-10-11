import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/login_approvals/login_approvals_cubit.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/model/login_approval_model.dart';
import 'package:hyper_local_seller/service/demo_guard.dart';
import 'package:hyper_local_seller/utils/image_path.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/card_shimmers.dart';
import 'package:hyper_local_seller/widgets/custom/custom_loading_indicator.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';
import 'package:hyper_local_seller/widgets/ui/empty_state_widget.dart';

/// Pending login requests from system users, with approve / disapprove.
class LoginApprovalsPage extends StatefulWidget {
  const LoginApprovalsPage({super.key});

  @override
  State<LoginApprovalsPage> createState() => _LoginApprovalsPageState();
}

class _LoginApprovalsPageState extends State<LoginApprovalsPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      final position = _scrollController.position;
      if (position.pixels >= position.maxScrollExtent * 0.9) {
        context.read<LoginApprovalsCubit>().loadMore();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LoginApprovalsCubit>().fetch();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      showAppbar: true,
      title: 'Login Approvals',
      centerTitle: true,
      body: LoginApprovalsCubit.canView
          ? _buildBody(context)
          : const EmptyStateWidget(
              svgPath: ImagesPath.noSearchFoundSvg,
              title: "You don't have permission to view login approvals",
            ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final screenType = context.screenType;

    return BlocConsumer<LoginApprovalsCubit, LoginApprovalsState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage ||
          previous.actionMessage != current.actionMessage,
      listener: (context, state) {
        // Load failures are shown by the empty state instead.
        if (state.errorMessage != null &&
            state.status != LoginApprovalsStatus.failure) {
          showCustomSnackbar(
            context: context,
            message: state.errorMessage!,
            isError: true,
          );
          context.read<LoginApprovalsCubit>().clearMessages();
        } else if (state.actionMessage != null) {
          showCustomSnackbar(context: context, message: state.actionMessage!);
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
            title: state.errorMessage ?? 'Seems like there is some issue',
            subtitle: 'Please try again later',
            actionText: 'Try Again',
            onAction: cubit.fetch,
          );
        }

        return RefreshIndicator(
          color: AppColors.primaryColor,
          onRefresh: cubit.fetch,
          child: state.items.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 60),
                    EmptyStateWidget(
                      svgPath: ImagesPath.noSearchFoundSvg,
                      title: 'No pending login requests',
                      subtitle:
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

  bool _canManage(BuildContext context) {
    if (!LoginApprovalsCubit.canManage) {
      showCustomSnackbar(
        context: context,
        message: "You don't have permission to manage system users",
        isWarning: true,
      );
      return false;
    }
    return DemoGuard.shouldProceed(context);
  }

  void _approve(BuildContext context, LoginApprovalRequest request) {
    if (!_canManage(context)) return;
    context.read<LoginApprovalsCubit>().approve(request.userId);
  }

  Future<void> _disapprove(
    BuildContext context,
    LoginApprovalRequest request,
  ) async {
    if (!_canManage(context)) return;
    final cubit = context.read<LoginApprovalsCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Disapprove login?'),
        content: Text(
          '${request.name} will not be able to sign in and any active '
          'session on their device will be ended.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Disapprove'),
          ),
        ],
      ),
    );
    if (confirmed == true) cubit.disapprove(request.userId);
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Pending',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          if (request.email != null && request.email!.isNotEmpty)
            detail(Icons.email_outlined, request.email!),
          if (request.mobile != null && request.mobile!.isNotEmpty)
            detail(Icons.phone_outlined, request.mobile!),
          if (request.requestedAt != null)
            detail(
              Icons.schedule,
              'Requested ${DateFormat('dd MMM yyyy, hh:mm a').format(request.requestedAt!)}',
            ),
          const SizedBox(height: 12),
          if (isProcessing)
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
                    label: const Text('Disapprove'),
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
                    label: const Text('Approve'),
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
