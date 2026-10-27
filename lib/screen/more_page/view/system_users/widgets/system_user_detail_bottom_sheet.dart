import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/bloc/system_user_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/login_approvals/login_approvals_cubit.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/model/system_users_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/repo/system_users_repo.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/widgets/approve_login_bottom_sheet.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/widgets/system_user_status_badges.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/card_shimmers.dart';
import 'package:hyper_local_seller/widgets/custom/custom_loading_indicator.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';
import 'package:intl/intl.dart';

Future<bool> confirmRevokeSystemUserLogin(
  BuildContext context,
  String name,
) async {
  final l10n = AppLocalizations.of(context);
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n?.revokeAccessTitle ?? 'Revoke access?'),
          content: Text(
            l10n?.revokeAccessBody(name) ??
                "$name won't be able to sign in and any active session on their device will end.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n?.cancel ?? 'Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(l10n?.revoke ?? 'Revoke'),
            ),
          ],
        ),
      ) ??
      false;
}

class SystemUserDetailBottomSheet extends StatefulWidget {
  final int id;
  final SystemUserBloc bloc;
  final SystemUsersRepo? repo;
  const SystemUserDetailBottomSheet({
    super.key,
    required this.id,
    required this.bloc,
    this.repo,
  });

  static Future<void> show(BuildContext context, int id) async {
    if (!LoginApprovalsCubit.canView) {
      showCustomSnackbar(
        context: context,
        message:
            AppLocalizations.of(context)?.noPermissionViewSystemUsers ??
            "You don't have permission to view system users",
        isWarning: true,
      );
      return;
    }
    final bloc = context.read<SystemUserBloc>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SystemUserDetailBottomSheet(id: id, bloc: bloc),
    );
  }

  @override
  State<SystemUserDetailBottomSheet> createState() =>
      _SystemUserDetailBottomSheetState();
}

class _SystemUserDetailBottomSheetState
    extends State<SystemUserDetailBottomSheet> {
  SystemUser? _user;
  bool _loading = true;
  bool _choosing = false;
  bool _acting = false;
  String? _error;
  int _loadVersion = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _refreshList() => widget.bloc.add(
    FetchSystemUsersEvent(
      isRefresh: true,
      silent: true,
      search: widget.bloc.state.search,
    ),
  );

  Future<void> _load() async {
    final version = ++_loadVersion;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await (widget.repo ?? SystemUsersRepo()).getSystemUserDetail(
        widget.id,
      );
      if (mounted && version == _loadVersion) {
        setState(() {
          _user = user;
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted || version != _loadVersion) return;
      final message = systemUserErrorMessage(
        context,
        e is ApiException ? e.message : 'Something went wrong',
      );
      if (e is ApiException && e.statusCode == 404) {
        showCustomSnackbar(context: context, message: message, isError: true);
        _refreshList();
        Navigator.pop(context);
      } else {
        setState(() {
          _error = message;
          _loading = false;
        });
      }
    }
  }

  bool get _busy =>
      _choosing ||
      _acting ||
      widget.bloc.state.processingIds.contains(widget.id);

  Future<void> _approve() async {
    if (_busy) return;
    setState(() => _choosing = true);
    final approved = await ApproveLoginBottomSheet.show(
      context,
      name: _user?.name ?? '',
    );
    if (!mounted) return;
    setState(() => _choosing = false);
    if (!approved || widget.bloc.state.processingIds.contains(widget.id)) {
      return;
    }
    setState(() => _acting = true);
    widget.bloc.add(ApproveSystemUserLoginEvent(id: widget.id));
  }

  Future<void> _revoke() async {
    if (_busy || !canManageSystemUserLogin(context)) return;
    setState(() => _choosing = true);
    final confirmed = await confirmRevokeSystemUserLogin(
      context,
      _user?.name ?? '',
    );
    if (!mounted) return;
    setState(() => _choosing = false);
    if (!confirmed ||
        !canManageSystemUserLogin(context) ||
        widget.bloc.state.processingIds.contains(widget.id)) {
      return;
    }
    setState(() => _acting = true);
    widget.bloc.add(DisapproveSystemUserLoginEvent(id: widget.id));
  }

  @override
  Widget build(BuildContext context) {
    final screenType = context.screenType;
    return BlocConsumer<SystemUserBloc, SystemUserState>(
      bloc: widget.bloc,
      listener: (context, state) {
        final result = state.approvalResult;
        if (_acting && result?.userId == widget.id) {
          ++_loadVersion;
          setState(() {
            _acting = false;
            _user = _user?.copyWithApproval(
              loginApprovalStatus: result!.loginApprovalStatus,
              loginApprovedUntil: result.loginApprovedUntil,
              clearApprovedUntil: result.loginApprovedUntil == null,
              systemUserStatus: result.systemUserStatus,
            );
          });
          context.read<LoginApprovalsCubit>().fetch();
          showCustomSnackbar(
            context: context,
            message: loginApprovalMessage(context, result!),
          );
          widget.bloc.add(ClearSystemUserMessages());
        } else if (_acting && state.approvalErrorId == widget.id) {
          setState(() => _acting = false);
          showCustomSnackbar(
            context: context,
            message: systemUserErrorMessage(
              context,
              state.errorMessage ?? 'Something went wrong',
            ),
            isError: true,
          );
          widget.bloc.add(ClearSystemUserMessages());
          if (state.approvalErrorStatus == 404) Navigator.pop(context);
        }
      },
      builder: (context, state) => SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.9,
          ),
          padding: EdgeInsets.all(UIUtils.gapMD(screenType)),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            child: _loading
                ? CardShimmer(type: 'system_user', screenType: screenType)
                : _error != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      TextButton(
                        onPressed: _load,
                        child: Text(
                          AppLocalizations.of(context)?.tryAgain ?? 'Try Again',
                        ),
                      ),
                    ],
                  )
                : _content(context),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final user = _user!;
    final l10n = AppLocalizations.of(context);
    final screenType = context.screenType;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    String date(DateTime? value) => value == null
        ? '—'
        : DateFormat('dd MMM, hh:mm a').format(value.toLocal());
    Widget info(String label, Widget value) => Padding(
      padding: EdgeInsets.symmetric(vertical: UIUtils.gapSM(screenType)),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: muted)),
          ),
          const SizedBox(width: 12),
          Flexible(child: value),
        ],
      ),
    );
    Widget initials() => CircleAvatar(
      backgroundColor: AppColors.primaryColor.withValues(alpha: 0.12),
      child: Text(
        (user.name ?? '')
            .trim()
            .split(RegExp(r'\s+'))
            .where((s) => s.isNotEmpty)
            .take(2)
            .map((s) => s.characters.first.toUpperCase())
            .join(),
      ),
    );
    final image = user.profileImage;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (image != null && image.isNotEmpty)
              ClipOval(
                child: Image.network(
                  image,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => initials(),
                ),
              )
            else
              initials(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name ?? '',
                    style: TextStyle(
                      fontSize: UIUtils.tileTitle(screenType),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(user.email ?? '', style: TextStyle(color: muted)),
                ],
              ),
            ),
            SystemUserActivityBadge(user.systemUserStatus),
          ],
        ),
        SizedBox(height: UIUtils.gapMD(screenType)),
        info(
          l10n?.activityLabel ?? 'Activity',
          Text(
            user.isActive
                ? l10n?.activeLoggedIn ?? 'Active (logged in)'
                : l10n?.inactive ?? 'Inactive',
          ),
        ),
        info(
          l10n?.loginApprovalLabel ?? 'Login approval',
          user.loginApprovalStatus == 'not_requested'
              ? Text(l10n?.approvalNotRequested ?? 'Not requested')
              : LoginApprovalBadge(user.loginApprovalStatus),
        ),
        info(
          l10n?.accessUntilLabel ?? 'Access until',
          Text(date(user.loginApprovedUntil)),
        ),
        info(
          l10n?.lastRequestedLabel ?? 'Last requested',
          Text(date(user.loginApprovalRequestedAt)),
        ),
        info(l10n?.mobileNumber ?? 'Mobile', Text(user.mobile)),
        SizedBox(height: UIUtils.gapMD(screenType)),
        if (LoginApprovalsCubit.canManage)
          if (_acting || widget.bloc.state.processingIds.contains(widget.id))
            const Center(child: CustomLoadingIndicator(size: 22))
          else
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (user.isApprovalPending)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    onPressed: _choosing ? null : _revoke,
                    child: Text(l10n?.riderDisapprove ?? 'Disapprove'),
                  ),
                if (user.isApproved)
                  OutlinedButton(
                    onPressed: _choosing ? null : _approve,
                    child: Text(l10n?.extendAccess ?? 'Extend access'),
                  )
                else
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                    ),
                    onPressed: _choosing ? null : _approve,
                    child: Text(l10n?.riderApprove ?? 'Approve'),
                  ),
                if (user.isApproved)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    onPressed: _choosing ? null : _revoke,
                    child: Text(l10n?.revokeAccess ?? 'Revoke access'),
                  ),
              ],
            ),
        SizedBox(height: UIUtils.gapSM(screenType)),
        Text(
          l10n?.approvalFooterNote ??
              'Approval allows sign-in. Status turns Active only after they log in.',
          style: TextStyle(color: muted, fontSize: UIUtils.caption(screenType)),
        ),
      ],
    );
  }
}
