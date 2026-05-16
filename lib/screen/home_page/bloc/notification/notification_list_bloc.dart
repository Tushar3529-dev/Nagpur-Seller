import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/bloc/pagination/paginated_state.dart';
import 'package:hyper_local_seller/screen/home_page/model/notification_list_model.dart';
import 'package:hyper_local_seller/screen/home_page/repo/notification_list_repo.dart';

part 'notification_list_event.dart';
part 'notification_list_state.dart';

class NotificationListBloc
    extends Bloc<NotificationListEvent, NotificationListState> {
  final NotificationListRepo _repo;

  NotificationListBloc(this._repo) : super(const NotificationListState()) {
    on<LoadNotificationsInitial>(_onLoadInitial);
    on<LoadMoreNotifications>(_onLoadMore);
    on<RefreshNotifications>(_onRefresh);
    on<MarkNotificationRead>(_onMarkRead);
    on<MarkNotificationUnread>(_onMarkUnread);
    on<MarkAllNotificationsRead>(_onMarkAllRead);
    on<FetchUnreadCount>(_onFetchUnreadCount);
    on<ClearNotifications>((event, emit) => emit(const NotificationListState()));
  }

  Future<void> _onLoadInitial(
    LoadNotificationsInitial event,
    Emitter<NotificationListState> emit,
  ) async {
    emit(
      state.copyWith(
        isInitialLoading: true,
        items: [],
        currentPage: 1,
        hasMore: true,
        error: null,
      ),
    );

    try {
      final response = await _repo.getAllNotifications(page: 1);
      final result = NotificationListResponse.fromJson(response);

      if (result.success == true && result.data != null) {
        final notifications = result.data!.notifications ?? [];
        emit(
          state.copyWith(
            isInitialLoading: false,
            items: notifications,
            currentPage: 1,
            hasMore: (result.data!.currentPage ?? 1) <
                (result.data!.lastPage ?? 1),
            total: result.data!.total,
          ),
        );
      } else {
        emit(
          state.copyWith(
            isInitialLoading: false,
            error: result.message ?? 'Failed to load notifications',
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(isInitialLoading: false, error: e.toString()));
    }

    // Also fetch unread count
    add(FetchUnreadCount());
  }

  Future<void> _onLoadMore(
    LoadMoreNotifications event,
    Emitter<NotificationListState> emit,
  ) async {
    if (state.isPaginating || !state.hasMore) return;

    emit(state.copyWith(isPaginating: true));

    try {
      final nextPage = state.currentPage + 1;
      final response = await _repo.getAllNotifications(page: nextPage);
      final result = NotificationListResponse.fromJson(response);

      if (result.success == true && result.data != null) {
        final notifications = result.data!.notifications ?? [];
        emit(
          state.copyWith(
            isPaginating: false,
            items: [...state.items, ...notifications],
            currentPage: nextPage,
            hasMore: (result.data!.currentPage ?? 1) <
                (result.data!.lastPage ?? 1),
            total: result.data!.total,
          ),
        );
      } else {
        emit(
          state.copyWith(
            isPaginating: false,
            error: result.message ?? 'Failed to load more notifications',
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(isPaginating: false, error: e.toString()));
    }
  }

  Future<void> _onRefresh(
    RefreshNotifications event,
    Emitter<NotificationListState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true, error: null));

    try {
      final response = await _repo.getAllNotifications(page: 1);
      final result = NotificationListResponse.fromJson(response);

      if (result.success == true && result.data != null) {
        final notifications = result.data!.notifications ?? [];
        emit(
          state.copyWith(
            isRefreshing: false,
            items: notifications,
            currentPage: 1,
            hasMore: (result.data!.currentPage ?? 1) <
                (result.data!.lastPage ?? 1),
            total: result.data!.total,
          ),
        );
      } else {
        emit(
          state.copyWith(
            isRefreshing: false,
            error: result.message ?? 'Failed to refresh notifications',
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(isRefreshing: false, error: e.toString()));
    }

    // Also refresh unread count
    add(FetchUnreadCount());
  }

  Future<void> _onMarkRead(
    MarkNotificationRead event,
    Emitter<NotificationListState> emit,
  ) async {
    try {
      await _repo.markAsRead(event.notificationId);

      // Update local state
      final updatedItems = state.items.map((item) {
        if (item.id == event.notificationId) {
          return NotificationItem(
            id: item.id,
            userId: item.userId,
            storeId: item.storeId,
            orderId: item.orderId,
            type: item.type,
            sentTo: item.sentTo,
            title: item.title,
            message: item.message,
            isRead: true,
            metadata: item.metadata,
            createdAt: item.createdAt,
            updatedAt: item.updatedAt,
          );
        }
        return item;
      }).toList();

      final newUnread = (state.unreadCount > 0) ? state.unreadCount - 1 : 0;
      emit(state.copyWith(items: updatedItems, unreadCount: newUnread));
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> _onMarkAllRead(
    MarkAllNotificationsRead event,
    Emitter<NotificationListState> emit,
  ) async {
    try {
      await _repo.markAllRead();

      // Update all local items to read
      final updatedItems = state.items.map((item) {
        return NotificationItem(
          id: item.id,
          userId: item.userId,
          storeId: item.storeId,
          orderId: item.orderId,
          type: item.type,
          sentTo: item.sentTo,
          title: item.title,
          message: item.message,
          isRead: true,
          metadata: item.metadata,
          createdAt: item.createdAt,
          updatedAt: item.updatedAt,
        );
      }).toList();

      emit(state.copyWith(items: updatedItems, unreadCount: 0));
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  Future<void> _onMarkUnread(
    MarkNotificationUnread event,
    Emitter<NotificationListState> emit,
  ) async {
    try {
      await _repo.markAsUnRead(event.notificationId);

      final updatedItems = state.items.map((item) {
        if (item.id == event.notificationId) {
          return NotificationItem(
            id: item.id,
            userId: item.userId,
            storeId: item.storeId,
            orderId: item.orderId,
            type: item.type,
            sentTo: item.sentTo,
            title: item.title,
            message: item.message,
            isRead: false,
            metadata: item.metadata,
            createdAt: item.createdAt,
            updatedAt: item.updatedAt,
          );
        }
        return item;
      }).toList();

      emit(state.copyWith(
        items: updatedItems,
        unreadCount: state.unreadCount + 1,
      ));
    } catch (e) {
      debugPrint('Error marking notification as unread: $e');
    }
  }

  Future<void> _onFetchUnreadCount(
    FetchUnreadCount event,
    Emitter<NotificationListState> emit,
  ) async {
    try {
      final response = await _repo.getUnreadCount();
      final data = response['data'] as Map<String, dynamic>?;
      final count = data?['unread_count'] ?? 0;
      emit(state.copyWith(unreadCount: count is int ? count : 0));
    } catch (e) {
      debugPrint('Error fetching unread count: $e');
    }
  }
}
