import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/bloc/screen_size/screen_size_bloc.dart';
import 'package:hyper_local_seller/config/app_permissions.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/screen/more_page/view/roles_and_permissions/bloc/permissions_bloc/permissions_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/roles_and_permissions/model/permission_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/roles_and_permissions/repo/permissions_repo.dart';
import 'package:hyper_local_seller/service/demo_guard.dart';
import 'package:hyper_local_seller/utils/image_path.dart';
import 'package:hyper_local_seller/utils/permission_checker.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/card_shimmers.dart';
import 'package:hyper_local_seller/widgets/custom/custom_buttons.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';
import 'package:hyper_local_seller/widgets/ui/empty_state_widget.dart';

class PermissionPage extends StatelessWidget {
  final String role;
  final int roleId;

  const PermissionPage({super.key, required this.role, required this.roleId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocProvider(
      create: (context) =>
          PermissionsBloc(PermissionsRepo())..add(GetPermissions(role)),
      child: BlocConsumer<PermissionsBloc, PermissionsState>(
        listener: (context, state) {
          if (state is PermissionsSyncSuccess) {
            showCustomSnackbar(context: context, message: state.message);
            Navigator.pop(context);
          } else if (state is PermissionsError) {
            showCustomSnackbar(
              context: context,
              message: state.message,
              isError: true,
            );
          }
        },
        builder: (context, state) {
          return BlocBuilder<ScreenSizeBloc, ScreenSizeState>(
            builder: (context, screenSizeState) {
              final screenType = screenSizeState.screenType;

              return CustomScaffold(
                showAppbar: true,
                centerTitle: true,
                title: l10n?.permission ?? 'Permission',
                body: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: UIUtils.pagePadding(screenType),
                      child: Text(
                        "Permission for: $role",
                        style: TextStyle(
                          fontSize: UIUtils.body(screenType),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(child: _buildBody(state, screenType, l10n)),
                    if (state is PermissionsLoaded)
                      Padding(
                        padding: UIUtils.pagePadding(screenType),
                        child: PrimaryButton(
                          text: l10n?.addPermission ?? "Add Permissions",
                          onPressed: () {
                            if (!DemoGuard.shouldProceed(context)) {
                              return;
                            }

                            if (!PermissionChecker.hasPermission(
                              AppPermissions.rolePermissionEdit,
                            )) {
                              showCustomSnackbar(
                                context: context,
                                message:
                                    l10n?.noPermissionEditRolePermissions ??
                                    "You don't have permission to modify role permissions",
                                isWarning: true,
                              );
                              return;
                            }

                            // Proceed
                            context.read<PermissionsBloc>().add(
                              SyncPermissions(role),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBody(
    PermissionsState state,
    ScreenType screenType,
    AppLocalizations? l10n,
  ) {
    if (state is PermissionsLoading) {
      return ListView.separated(
        padding: UIUtils.cardsPadding(screenType),
        separatorBuilder: (context, index) =>
            SizedBox(height: UIUtils.gapMD(screenType)),
        itemCount: 5,
        itemBuilder: (context, index) =>
            CardShimmer(type: 'permission', screenType: screenType),
      );
    }

    if (state is PermissionsLoaded) {
      final grouped = state.data.groupedPermissions;
      if (grouped == null) {
        return EmptyStateWidget(
          svgPath: ImagesPath.noProductFoundSvg,
          title: l10n?.noAttributeValuesFound ?? 'No attribute value found',
          subtitle:
              l10n?.noAttributeValuesAddedYet ??
              'You have not added any attribute value yet',
          actionText: l10n?.refresh ?? 'Refresh',
          onAction: () {},
        );
      }

      final groups = [
        grouped.dashboard,
        grouped.wallet,
        grouped.withdrawal,
        grouped.earning,
        grouped.order,
        grouped.returns,
        grouped.category,
        grouped.brand,
        grouped.attribute,
        grouped.product,
        grouped.productFaq,
        grouped.taxRate,
        grouped.store,
        grouped.notification,
        grouped.role,
        grouped.permission,
        grouped.systemUser,
        grouped.subscription,
      ].whereType<PermissionGroup>().toList();

      return ListView.separated(
        padding: UIUtils.cardsPadding(screenType),
        itemCount: groups.length,
        separatorBuilder: (context, index) =>
            SizedBox(height: UIUtils.gapMD(screenType)),
        itemBuilder: (context, index) {
          return _PermissionGroupCard(
            group: groups[index],
            assigned: state.currentAssigned,
            screenType: screenType,
          );
        },
      );
    }

    return const SizedBox.shrink();
  }
}

class _PermissionGroupCard extends StatelessWidget {
  final PermissionGroup group;
  final List<String> assigned;
  final ScreenType screenType;

  const _PermissionGroupCard({
    required this.group,
    required this.assigned,
    required this.screenType,
  });

  @override
  Widget build(BuildContext context) {
    final isAllSelected = group.permissions.every((p) => assigned.contains(p));

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(UIUtils.radiusLG(screenType)),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: UIUtils.cardPadding(screenType),
            child: Text(
              group.name,
              style: TextStyle(
                fontSize: UIUtils.body(screenType),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          ...group.permissions.map((permission) {
            final isSelected = assigned.contains(permission);
            return CheckboxListTile(
              title: Text(
                _formatPermissionName(permission),
                style: TextStyle(fontSize: UIUtils.tileSubtitle(screenType)),
              ),
              value: isSelected,
              onChanged: (val) {
                context.read<PermissionsBloc>().add(
                  TogglePermission(permission),
                );
              },
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              activeColor: AppColors.primaryColor,
            );
          }),
          CheckboxListTile(
            title: Text(
              "Select All",
              style: TextStyle(
                fontSize: UIUtils.tileSubtitle(screenType),
                fontWeight: FontWeight.bold,
              ),
            ),
            value: isAllSelected,
            onChanged: (val) {
              context.read<PermissionsBloc>().add(
                ToggleMultiplePermissions(group.permissions, val == true),
              );
            },
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            activeColor: AppColors.primaryColor,
          ),
        ],
      ),
    );
  }

  String _formatPermissionName(String permission) {
    // permission is like 'dashboard.view', we want 'View' or something similar
    // For now, just capitalize the last part
    final parts = permission.split('.');
    if (parts.length > 1) {
      final name = parts.last;
      return name[0].toUpperCase() + name.substring(1);
    }
    return permission;
  }
}
