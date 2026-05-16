// ignore_for_file: deprecated_member_use

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local_seller/bloc/screen_size/screen_size_bloc.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/router/app_routes.dart';
import 'package:hyper_local_seller/screen/home_page/bloc/notification/notification_list_bloc.dart';
import 'package:hyper_local_seller/screen/home_page/model/notification_list_model.dart';
import 'package:hyper_local_seller/utils/image_path.dart';
import 'package:hyper_local_seller/utils/time_utils.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/card_shimmers.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/config/app_permissions.dart';
import 'package:hyper_local_seller/utils/permission_checker.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';
import 'package:hyper_local_seller/widgets/ui/empty_state_widget.dart';

class NotificationListPage extends StatefulWidget {
  const NotificationListPage({super.key});

  @override
  State<NotificationListPage> createState() => _NotificationListPageState();
}

class _NotificationListPageState extends State<NotificationListPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (PermissionChecker.hasPermission(AppPermissions.notificationView)) {
      context.read<NotificationListBloc>().add(LoadNotificationsInitial());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<NotificationListBloc>().add(LoadMoreNotifications());
    }
  }

  void _onNotificationTap(NotificationItem notification) {
    // Mark as read if not already
    if (!notification.isRead) {
      if (!PermissionChecker.hasPermission(AppPermissions.notificationEdit)) {
        // Silent failure or snackbar? Usually, if they can't edit, they shouldn't trigger the mark read.
        // But clicking usually redirects too.
      } else {
        context.read<NotificationListBloc>().add(
          MarkNotificationRead(notification.id),
        );
      }
    }

    // Navigate based on type
    final type = notification.type.toLowerCase();
    final orderId = notification.metadata?.sellerOrderId;

    switch (type) {
      case 'order_update':
      case 'new_order':
        // case 'return_order':
        // case 'return_order_update':
        if (orderId != null && orderId > 0) {
          context.push('${AppRoutes.orderDetails}/$orderId');
        }
        break;
      case 'wallet_transaction':
        context.push(AppRoutes.wallet);
        break;
      case 'withdrawal_request':
      case 'withdrawal_process':
        context.push(AppRoutes.withdrawHistory);
        break;
      case 'settlement_process':
      case 'settlement_create':
        context.push(AppRoutes.earnings);
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return CustomScaffold(
      title: l10n?.notifications ?? "Notifications",
      showAppbar: true,
      appBarActions: [
        TextButton(
          onPressed: () {
            if (!PermissionChecker.hasPermission(
              AppPermissions.notificationEdit,
            )) {
              showCustomSnackbar(
                context: context,
                message:
                    l10n?.noPermissionMarkAllRead ??
                    "You don't have permission to mark all as read",
                isWarning: true,
              );
              return;
            }
            context.read<NotificationListBloc>().add(
              MarkAllNotificationsRead(),
            );
          },
          child: Text(
            l10n?.markAllRead ?? "Mark All Read",
            style: TextStyle(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
      body: BlocBuilder<ScreenSizeBloc, ScreenSizeState>(
        builder: (context, screenTypeState) {
          final screenType = screenTypeState.screenType;
          return BlocBuilder<NotificationListBloc, NotificationListState>(
            builder: (context, state) {
              if (!PermissionChecker.hasPermission(
                AppPermissions.notificationView,
              )) {
                return Center(
                  child: Text(
                    l10n?.noPermissionViewNotification ??
                        "You don't have permission to view notifications",
                  ),
                );
              }
              if ((state.isInitialLoading || state.isRefreshing) &&
                  state.items.isEmpty) {
                return ListView.separated(
                  padding: UIUtils.cardsPadding(screenType),
                  separatorBuilder: (context, index) =>
                      SizedBox(height: UIUtils.gapMD(screenType)),
                  itemCount: 8,
                  itemBuilder: (context, index) =>
                      CardShimmer(type: 'notification', screenType: screenType),
                );
              }

              if (state.error != null && state.items.isEmpty) {
                return EmptyStateWidget(
                  svgPath: ImagesPath.noOrderFoundSvg,
                  title:
                      l10n?.somethingWentWrong ??
                      'Seems like there is some issue',
                  subtitle: l10n?.tryAgainLater ?? 'Please try again later',
                  actionText: l10n?.tryAgain ?? 'Try Again',
                  onAction: () {
                    context.read<NotificationListBloc>().add(
                      RefreshNotifications(),
                    );
                  },
                );
              }

              if (state.items.isEmpty) {
                return EmptyStateWidget(
                  svgPath: ImagesPath.noOrderFoundSvg,
                  title: l10n?.noNotificationsYet ?? "No notifications yet",
                  subtitle:
                      l10n?.noNotificationsMessage ??
                      "You have not received any notifications yet.",
                  actionText: l10n?.refresh ?? "Refresh",
                  onAction: () {
                    context.read<NotificationListBloc>().add(
                      RefreshNotifications(),
                    );
                  },
                );
              }

              return RefreshIndicator(
                color: AppColors.primaryColor,
                onRefresh: () async {
                  context.read<NotificationListBloc>().add(
                    RefreshNotifications(),
                  );
                },
                child: ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: state.items.length + (state.isPaginating ? 1 : 0),
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    if (index >= state.items.length) {
                      return CardShimmer(
                        type: 'notification',
                        screenType: screenType,
                      );
                    }
                    final notification = state.items[index];
                    return Dismissible(
                      key: ValueKey(notification.id),
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          // Swipe right → mark as read
                          if (!notification.isRead) {
                            if (!PermissionChecker.hasPermission(
                              AppPermissions.notificationEdit,
                            )) {
                              showCustomSnackbar(
                                context: context,
                                message:
                                    l10n?.noPermissionMarkAsRead ??
                                    "You don't have permission to mark as read",
                                isWarning: true,
                              );
                            } else {
                              context.read<NotificationListBloc>().add(
                                MarkNotificationRead(notification.id),
                              );
                            }
                          }
                        } else if (direction == DismissDirection.endToStart) {
                          // Swipe left → mark as unread
                          if (notification.isRead) {
                            if (!PermissionChecker.hasPermission(
                              AppPermissions.notificationEdit,
                            )) {
                              showCustomSnackbar(
                                context: context,
                                message:
                                    l10n?.noPermissionMarkAsUnRead ??
                                    "You don't have permission to mark as unread",
                                isWarning: true,
                              );
                            } else {
                              context.read<NotificationListBloc>().add(
                                MarkNotificationUnread(notification.id),
                              );
                            }
                          }
                        }
                        return false; // Don't dismiss the card
                      },
                      background: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 20),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.mark_email_read_outlined,
                              color: Colors.green,
                            ),
                            SizedBox(width: 8),
                            Text(
                              l10n?.markRead ?? 'Mark Read',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      secondaryBackground: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              l10n?.markUnread ?? 'Mark Unread',
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.mark_email_unread_outlined,
                              color: Colors.orange,
                            ),
                          ],
                        ),
                      ),
                      child: _NotificationCard(
                        notification: notification,
                        onTap: () => _onNotificationTap(notification),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback onTap;

  const _NotificationCard({required this.notification, required this.onTap});

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'order_update':
      case 'new_order':
        return Icons.shopping_bag_outlined;
      case 'return_order':
      case 'return_order_update':
        return Icons.assignment_return_outlined;
      case 'wallet_transaction':
        return Icons.account_balance_wallet_outlined;
      case 'withdrawal_request':
      case 'withdrawal_process':
        return Icons.money_off_outlined;
      case 'settlement_process':
      case 'settlement_create':
        return Icons.receipt_long_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'order_update':
      case 'new_order':
        return Colors.blue;
      case 'return_order':
      case 'return_order_update':
        return Colors.orange;
      case 'wallet_transaction':
        return Colors.green;
      case 'withdrawal_request':
      case 'withdrawal_process':
        return Colors.purple;
      case 'settlement_process':
      case 'settlement_create':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeColor = _getColorForType(notification.type);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notification.isRead
              ? theme.colorScheme.surface
              : typeColor.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notification.isRead
                ? theme.colorScheme.outlineVariant.withValues(alpha: 0.3)
                : typeColor.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getIconForType(notification.type),
                color: typeColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: notification.isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        TimeUtils.formatTimeAgo(
                          notification.createdAt,
                          context,
                        ),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Unread dot
            if (!notification.isRead) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: typeColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
