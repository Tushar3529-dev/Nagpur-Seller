import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hyper_local_seller/bloc/store_switcher/store_switcher_cubit.dart';
import 'package:hyper_local_seller/config/global_keys.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/router/app_routes.dart';
import 'package:hyper_local_seller/screen/home_page/bloc/home_page/home_page_bloc.dart';
import 'package:hyper_local_seller/screen/home_page/bloc/notification/notification_list_bloc.dart';
import 'package:hyper_local_seller/screen/order_page/bloc/orders/orders_bloc.dart';
import 'package:hyper_local_seller/widgets/ui/order_notification_handler.dart';
import 'package:path_provider/path_provider.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  Map<String, dynamic>? _pendingPayload;

  bool get hasPendingNotification => _pendingPayload != null;

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // Request permission first
    await notificationPermission();

    // Init local notifications
    await _initLocalNotification();

    // Init Firebase listeners
    _firebaseInit();

    // Setup token refresh listener
    _onTokenRefresh();

    // Generate and store tokens
    await updateTokens();
  }

  Future<void> _initLocalNotification() async {
    const androidInitializationSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosInitializationSettings = DarwinInitializationSettings();

    const initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null) {
          try {
            final payloadStr = response.payload!;
            if (payloadStr.startsWith('{')) {
              final payloadMap =
                  json.decode(payloadStr) as Map<String, dynamic>;
              _handleNotificationTap(payloadMap, fromForeground: false);
            } else {
              debugPrint('Notification payload: $payloadStr');
              _handleNotificationTap({}, fromForeground: false);
            }
          } catch (e) {
            debugPrint('Error parsing notification payload: $e');
            _handleNotificationTap({}, fromForeground: false);
          }
        }
      },
    );
  }

  void _handleNotificationTap(
    Map<String, dynamic> payload, {
    BuildContext? context,
    bool fromForeground = false,
    bool fromTerminated = false,
  }) {
    final navContext = context ?? GlobalKeys.navigatorKey.currentContext;
    if (navContext == null) {
      debugPrint("Error: No valid context found for notification navigation");
      return;
    }

    final type = payload['type']?.toString().toLowerCase();
    final orderId = payload['seller_order_id']?.toString();

    // Determine notification category
    final isOrderNotification = type == 'order' ||
        type == 'orders' ||
        type == 'order_update' ||
        type == 'new_order' ||
        type == 'return_order' ||
        type == 'return_order_update' ||
        (orderId != null && orderId.isNotEmpty && type == null);

    final isWalletNotification = type == 'wallet_transaction';
    final isWithdrawalNotification =
        type == 'withdrawal_request' || type == 'withdrawal_process';
    final isSettlementNotification =
        type == 'settlement_process' || type == 'settlement_create';

    if (isOrderNotification) {
      if (fromForeground) {
        if (type == 'order_update' ||
            type == 'return_order_update' ||
            (orderId != null && orderId.isNotEmpty && type == null)) {
          debugPrint("Foreground: Navigation to order details for update");
          navContext.push('${AppRoutes.orderDetails}/$orderId');
        } else {
          debugPrint("Foreground: Showing bottom sheet on current page");
          OrderNotificationHandler.showOrderAcceptanceBottomSheet(
            navContext,
            payload,
          );
        }
      } else if (fromTerminated) {
        if (orderId != null && orderId.isNotEmpty) {
          debugPrint("Terminated: Building navigation stack to order details");
          Future.delayed(const Duration(milliseconds: 500), () {
            if (navContext.mounted) {
              navContext.go(AppRoutes.home);
              Future.delayed(const Duration(milliseconds: 300), () {
                if (navContext.mounted) {
                  navContext.go(AppRoutes.orders);
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (navContext.mounted) {
                      navContext.push('${AppRoutes.orderDetails}/$orderId');
                    }
                  });
                }
              });
            }
          });
        } else {
          debugPrint("No order ID, navigating to Orders page");
          navContext.go(AppRoutes.orders);
        }
      } else {
        if (orderId != null && orderId.isNotEmpty) {
          debugPrint("Background: Pushing to Order Details page");
          navContext.push('${AppRoutes.orderDetails}/$orderId');
        } else {
          debugPrint("No order ID, pushing to Orders page");
          navContext.go(AppRoutes.orders);
        }
      }
    } else if (isWalletNotification) {
      debugPrint("Navigating to Wallet page");
      if (fromTerminated) {
        navContext.go(AppRoutes.home);
        Future.delayed(const Duration(milliseconds: 500), () {
          if (navContext.mounted) navContext.push(AppRoutes.wallet);
        });
      } else {
        navContext.push(AppRoutes.wallet);
      }
    } else if (isWithdrawalNotification) {
      debugPrint("Navigating to Withdraw History page");
      if (fromTerminated) {
        navContext.go(AppRoutes.home);
        Future.delayed(const Duration(milliseconds: 500), () {
          if (navContext.mounted) navContext.push(AppRoutes.withdrawHistory);
        });
      } else {
        navContext.push(AppRoutes.withdrawHistory);
      }
    } else if (isSettlementNotification) {
      debugPrint("Navigating to Earnings page");
      if (fromTerminated) {
        navContext.go(AppRoutes.home);
        Future.delayed(const Duration(milliseconds: 500), () {
          if (navContext.mounted) navContext.push(AppRoutes.earnings);
        });
      } else {
        navContext.push(AppRoutes.earnings);
      }
    } else {
      debugPrint("Payload not proper or unknown type, navigating home");
      if (fromTerminated) {
        navContext.go(AppRoutes.home);
      } else {
        navContext.go(AppRoutes.home);
      }
    }
  }

  void _firebaseInit() {
    FirebaseMessaging.onMessage.listen((message) async {
      debugPrint('Foreground message received: ${message.messageId}');
      debugPrint('Title: ${message.notification?.title}');
      debugPrint('Body: ${message.notification?.body}');
      debugPrint('Data: ${message.data}');

      final payload = {
        "title": message.data['title'] ?? message.notification?.title ?? '',
        "body": message.data['body'] ?? message.notification?.body ?? '',
        "slug": message.data['slug'] ?? '',
        "type": message.data['type'] ?? '',
        "order_id": message.data['order_id'] ?? '',
        "order_slug": message.data['order_slug'] ?? '',
        "seller_order_id": message.data['seller_order_id'] ?? '',
        "status": message.data['status'] ?? '',
        "notification_id": message.data['notification_id'] ?? '',
        "image": message.data['image'] ?? '',
      };

      // Always refresh notification unread count when any notification arrives
      _refreshBlocsFromContext();

      // Check if this is a new order notification
      final type = payload['type']?.toString().toLowerCase();
      final isOrderNotification = _isOrderRelatedType(type, payload['seller_order_id']);

      if (isOrderNotification) {
        // Show the bottom sheet immediately for foreground order notifications
        final context = GlobalKeys.navigatorKey.currentContext;
        if (context != null) {
          _handleNotificationTap(payload, fromForeground: true);
        }
        return; // Don't show the system notification
      }

      // For other notifications, show as usual
      if (Platform.isIOS && message.notification != null) {
        return;
      }

      final jsonPayload = jsonEncode(payload);

      if (Platform.isAndroid) {
        await showNotification(message, jsonPayload);
      } else if (Platform.isIOS) {
        if (message.notification == null && message.data.isNotEmpty) {
          await showNotification(message, jsonPayload);
        }
      }
    });

    // Handle background/terminated state click
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('Message clicked (background): ${message.messageId}');
      final payload = {
        "title": message.data['title'] ?? message.notification?.title ?? '',
        "body": message.data['body'] ?? message.notification?.body ?? '',
        "slug": message.data['slug'] ?? '',
        "type": message.data['type'] ?? '',
        "order_id": message.data['order_id'] ?? '',
        "order_slug": message.data['order_slug'] ?? '',
        "status": message.data['status'] ?? '',
        "image": message.data['image'] ?? '',
        "seller_order_id": message.data['seller_order_id'] ?? '',
        "notification_id": message.data['notification_id'] ?? '',
      };
      _handleNotificationTap(payload, fromForeground: false);

      // Refresh orders + notification count after background tap navigation
      final type = message.data['type']?.toString().toLowerCase();
      final orderId = message.data['seller_order_id']?.toString();
      if (_isOrderRelatedType(type, orderId)) {
        // Small delay so navigation completes first
        Future.delayed(const Duration(milliseconds: 600), () {
          _refreshBlocsFromContext();
        });
      } else {
        // Always refresh notification count
        Future.delayed(const Duration(milliseconds: 600), () {
          _refreshNotificationCountFromContext();
        });
      }
    });

    // Handle terminated state directly
    _firebaseMessaging.getInitialMessage().then((message) {
      if (message != null) {
        debugPrint(
          'App opened from terminated state by notification: ${message.messageId}',
        );
        final payload = {
          "title": message.data['title'] ?? message.notification?.title ?? '',
          "body": message.data['body'] ?? message.notification?.body ?? '',
          "slug": message.data['slug'] ?? '',
          "type": message.data['type'] ?? '',
          "order_id": message.data['order_id'] ?? '',
          "order_slug": message.data['order_slug'] ?? '',
          "status": message.data['status'] ?? '',
          "seller_order_id": message.data['seller_order_id'] ?? '',
          "image": message.data['image'] ?? '',
          "notification_id": message.data['notification_id'] ?? '',
        };
        _pendingPayload = payload;
        debugPrint(
          'Payload stored for terminated state. Will be handled after splash.',
        );
      }
    });
  }

  void handlePendingNotification(BuildContext context) {
    if (_pendingPayload != null) {
      debugPrint("Handling pending notification from terminated state");
      final payload = _pendingPayload!;
      _pendingPayload = null;

      _handleNotificationTap(
        payload,
        context: context,
        fromForeground: false,
        fromTerminated: true,
      );

      // Refresh orders + notification count after terminated-state tap
      final type = payload['type']?.toString().toLowerCase();
      final orderId = payload['seller_order_id']?.toString();
      Future.delayed(const Duration(milliseconds: 800), () {
        if (context.mounted) {
          if (_isOrderRelatedType(type, orderId)) {
            context.read<OrdersBloc>().add(RefreshOrders());
          }
          context.read<NotificationListBloc>().add(FetchUnreadCount());
          debugPrint('[Terminated] Blocs refreshed after handling pending notification');
        }
      });
    }
  }

  static bool _isOrderRelatedType(String? type, String? orderId) {
    return type == 'order' ||
        type == 'orders' ||
        type == 'order_update' ||
        type == 'new_order' ||
        type == 'return_order' ||
        type == 'return_order_update' ||
        (orderId != null && orderId.isNotEmpty && type == null);
  }

  /// Dispatches [RefreshOrders] + [FetchUnreadCount] using the global navigator
  /// context.  Safe to call from any foreground listener.
  void _refreshBlocsFromContext() {
    final context = GlobalKeys.navigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    try {
      context.read<OrdersBloc>().add(RefreshOrders());
      context.read<NotificationListBloc>().add(FetchUnreadCount());

      // Refresh HomePage Data when any notification (like new order) is received
      final switcherState = context.read<StoreSwitcherCubit>().state;
      if (switcherState.selectedStore != null) {
        context.read<HomePageBloc>().add(
          FetchHomePageData(storeId: switcherState.selectedStore!.id),
        );
      }

      debugPrint(
        '[Notification] Orders + NotificationCount + HomePage refreshed (foreground)',
      );
    } catch (e) {
      debugPrint('[Notification] Error refreshing blocs: $e');
    }
  }

  /// Dispatches only [FetchUnreadCount] for non-order notifications.
  void _refreshNotificationCountFromContext() {
    final context = GlobalKeys.navigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    try {
      context.read<NotificationListBloc>().add(FetchUnreadCount());
      debugPrint('[Notification] NotificationCount refreshed');
    } catch (e) {
      debugPrint('[Notification] Error refreshing notification count: $e');
    }
  }

  Future<void> showNotification(
    RemoteMessage message,
    String jsonPayload,
  ) async {
    try {
      const String channelId = 'high_importance_channel';
      const String channelName = 'Order Notifications';

      final AndroidNotificationChannel channel = AndroidNotificationChannel(
        channelId,
        channelName,
        description: 'Notifications for new orders and updates.',
        importance: Importance.max,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('notification_sound'),
        showBadge: true,
        enableVibration: true,
      );

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);

      String? imageUrl = message.data['image'];
      String? publisherName =
          message.data['channel_name'] ?? 'Hyper Local Seller';

      AndroidNotificationDetails androidDetails;
      DarwinNotificationDetails iosDetails;

      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          final bigPicturePath = await _downloadAndSaveImage(
            imageUrl,
            'notification_img.jpg',
          );

          if (bigPicturePath.isNotEmpty) {
            final BigPictureStyleInformation bigPictureStyleInformation =
                BigPictureStyleInformation(
                  FilePathAndroidBitmap(bigPicturePath),
                  contentTitle: publisherName,
                  summaryText:
                      message.data['body'] ?? message.notification?.body,
                  htmlFormatContent: true,
                  htmlFormatContentTitle: true,
                );

            androidDetails = AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              importance: Importance.high,
              priority: Priority.high,
              styleInformation: bigPictureStyleInformation,
              sound: const RawResourceAndroidNotificationSound('notification_sound'),
            );

            iosDetails = DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
              sound: 'notification_sound.wav', // Common to use wav for iOS but mp3 also works
              interruptionLevel: InterruptionLevel.active,
              attachments: [DarwinNotificationAttachment(bigPicturePath)],
            );
          } else {
            androidDetails = _createTextNotification(
              channel,
              publisherName,
              message.data['body'] ?? message.notification?.body,
            );
            iosDetails = const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
              sound: 'notification_sound.wav',
            );
          }
        } catch (e) {
          debugPrint('Error downloading image: $e');
          androidDetails = _createTextNotification(
            channel,
            publisherName,
            message.data['body'] ?? message.notification?.body,
          );
          iosDetails = const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'notification_sound.wav',
          );
        }
      } else {
        androidDetails = _createTextNotification(
          channel,
          publisherName,
          message.data['body'] ?? message.notification?.body,
        );
        iosDetails = const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'notification_sound.wav',
        );
      }

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        message.hashCode,
        message.data['title'] ?? message.notification?.title,
        message.data['body'] ?? message.notification?.body,
        details,
        payload: jsonPayload,
      );
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  AndroidNotificationDetails _createTextNotification(
    AndroidNotificationChannel channel,
    String? publisherName,
    String? body,
  ) {
    return AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: Importance.high,
      priority: Priority.high,
      sound: const RawResourceAndroidNotificationSound('notification_sound'),
      styleInformation: BigTextStyleInformation(
        body ?? '',
        contentTitle: publisherName,
        summaryText: body,
      ),
    );
  }

  Future<String> _downloadAndSaveImage(String url, String fileName) async {
    try {
      if (url.isEmpty || !url.startsWith('http')) return '';

      final Directory directory = Platform.isIOS
          ? await getTemporaryDirectory()
          : await getApplicationDocumentsDirectory();

      final String filePath = '${directory.path}/$fileName';

      final File oldFile = File(filePath);
      if (await oldFile.exists()) {
        await oldFile.delete();
      }

      final Dio dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 10);
      dio.options.receiveTimeout = const Duration(seconds: 15);

      await dio.download(url, filePath);

      final File file = File(filePath);
      if (await file.exists() && await file.length() > 0) {
        return filePath;
      }
      return '';
    } catch (e) {
      debugPrint('Error downloading image $fileName: $e');
      return '';
    }
  }

  Future<void> notificationPermission() async {
    const String notificationBoxName = 'notificationBox';
    const String hasAskedForPermissionKey =
        'has_asked_for_notification_permission';

    final box = await Hive.openBox(notificationBoxName);
    final bool hasAskedBefore = box.get(
      hasAskedForPermissionKey,
      defaultValue: false,
    );

    if (hasAskedBefore) return;

    await box.put(hasAskedForPermissionKey, true);

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    if (Platform.isIOS) {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );
    }

    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: true,
    );
  }

  Future<void> updateTokens() async {
    try {
      // APNs Token for iOS
      if (Platform.isIOS) {
        String? apnsToken = await _firebaseMessaging.getAPNSToken();
        int retryCount = 0;
        const maxRetries = 10;

        while (apnsToken == null && retryCount < maxRetries) {
          debugPrint('Waiting for APNs token... attempt ${retryCount + 1}');
          await Future.delayed(const Duration(seconds: 2));
          apnsToken = await _firebaseMessaging.getAPNSToken();
          retryCount++;
        }

        if (apnsToken != null) {
          await HiveStorage.setApnsToken(apnsToken);
        } else {
          debugPrint('APNs token failed after retries');
        }
      }

      // FCM Token
      String? fcmToken = await _firebaseMessaging.getToken();
      if (fcmToken != null) {
        await HiveStorage.setFcmToken(fcmToken);
      }
    } catch (e) {
      debugPrint("Error updating tokens: $e");
    }
  }

  void _onTokenRefresh() {
    _firebaseMessaging.onTokenRefresh.listen((token) async {
      debugPrint('Token Refreshed: $token');
      await HiveStorage.setFcmToken(token);
    });
  }
}
