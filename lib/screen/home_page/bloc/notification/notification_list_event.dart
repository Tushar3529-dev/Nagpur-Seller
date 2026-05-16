part of 'notification_list_bloc.dart';

@immutable
sealed class NotificationListEvent {}

class LoadNotificationsInitial extends NotificationListEvent {}

class LoadMoreNotifications extends NotificationListEvent {}

class RefreshNotifications extends NotificationListEvent {}

class MarkNotificationRead extends NotificationListEvent {
  final String notificationId;
  MarkNotificationRead(this.notificationId);
}

class MarkAllNotificationsRead extends NotificationListEvent {}

class MarkNotificationUnread extends NotificationListEvent {
  final String notificationId;
  MarkNotificationUnread(this.notificationId);
}

class FetchUnreadCount extends NotificationListEvent {}

class ClearNotifications extends NotificationListEvent {}

