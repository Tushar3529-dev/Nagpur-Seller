import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/global_keys.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/screen/order_page/incoming_orders/model/pending_order_model.dart';
import 'package:hyper_local_seller/screen/order_page/incoming_orders/cubit/incoming_orders_cubit.dart';
import 'package:hyper_local_seller/service/order_alert_bridge.dart';
import 'package:hyper_local_seller/service/order_ringtone_service.dart';
import 'package:hyper_local_seller/service/popup_presence_service.dart';
import 'package:hyper_local_seller/utils/permission_checker.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';

/// Drives the incoming-order popup from outside the router:
/// - rings while there are orders waiting to be accepted (not while the
///   seller is only scanning an accepted one). On Android the ringing is
///   native ([OrderAlertBridge]): pushes start it even with the app closed,
///   and it goes on after the app is swiped away. Only accepting the order,
///   or its reassignment to another seller, stops it
/// - swallows the Android back button while orders are pending
/// - re-checks the pending list on resume and on a timer (backup for missed pushes)
/// - keeps popup presence (location reporting) in step with login, role and
///   location permission, so the backend can offer this user nearby orders
///
/// Must sit ABOVE `MaterialApp.router` so its back-button observer is
/// registered before the router's and gets the first say.
class IncomingOrdersController extends StatefulWidget {
  final Widget child;

  const IncomingOrdersController({super.key, required this.child});

  @override
  State<IncomingOrdersController> createState() =>
      _IncomingOrdersControllerState();
}

class _IncomingOrdersControllerState extends State<IncomingOrdersController>
    with WidgetsBindingObserver {
  static const _pollInterval = Duration(seconds: 5);
  Timer? _pollTimer;

  // Kept from initState: dispose() can't look providers up.
  late final IncomingOrdersCubit _cubit = context.read<IncomingOrdersCubit>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    HiveStorage.userDataRevision.addListener(_syncPresence);
    _cubit.fetchRevision.addListener(_onFetched);
    _startPolling();
    _syncPresence();
    // The listener below only reacts to changes, so cover orders that were
    // already queued before this widget mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncRinging(_cubit.state);
    });
  }

  void _syncRinging(IncomingOrdersState state) {
    if (OrderAlertBridge.isSupported) {
      _syncNativeAlerts();
      return;
    }
    if (state.hasUnaccepted) {
      OrderRingtoneService().start();
    } else {
      OrderRingtoneService().stop();
    }
  }

  /// Unaccepted orders ring natively; accepted and minimized ones stop (a
  /// minimized order rings again when reopened, if still unaccepted). With
  /// [afterFetch], the queue mirrors the server, so ringing orders missing
  /// from it were reassigned to another seller and stop too. Nothing else
  /// stops the ringing.
  void _syncNativeAlerts({bool afterFetch = false}) {
    if (!OrderAlertBridge.isSupported || !mounted) return;
    final state = _cubit.state;
    OrderAlertBridge.sync(
      [
        for (final order in state.visibleOrders)
          if (!state.isAccepted(order)) _alertFor(order),
      ],
      acceptedIds: {...state.acceptedOrderIds, ...state.minimizedOrderIds},
      serverIds: afterFetch
          ? [for (final order in state.orders) order.sellerOrderId]
          : null,
    );
  }

  void _onFetched() => _syncNativeAlerts(afterFetch: true);

  static OrderAlertEntry _alertFor(PendingOrder order) => OrderAlertEntry(
    orderId: order.sellerOrderId.toString(),
    title: order.isWholesale
        ? 'New wholesale order #${order.orderNumber}'
        : 'New order #${order.orderNumber}',
    body: [
      '${order.itemCount} ${order.itemCount == 1 ? 'item' : 'items'}',
      if (order.total.isNotEmpty) '₹${order.total}',
      'Open the app to accept it.',
    ].join(' · '),
  );

  /// Login, logout and permission updates all change the stored user data.
  void _syncPresence() {
    PopupPresenceService().sync(requestPermission: true);
    final token = HiveStorage.userToken;
    OrderAlertBridge.setLoggedIn(
      token != null &&
          token.trim().isNotEmpty &&
          PermissionChecker.canShowOrderPopup,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    HiveStorage.userDataRevision.removeListener(_syncPresence);
    if (!_cubit.isClosed) _cubit.fetchRevision.removeListener(_onFetched);
    _pollTimer?.cancel();
    // The native alert is left alone: it must outlive the app.
    OrderRingtoneService().stop();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _cubit.fetch());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _cubit.fetch();
        // Location may have been switched off or revoked while away. No
        // prompt here: a dialog on every resume would be intrusive.
        PopupPresenceService().sync();
        if (_cubit.state.hasUnaccepted && !OrderAlertBridge.isSupported) {
          // A call or another app may have taken audio focus meanwhile.
          OrderRingtoneService().stop().then(
            (_) => OrderRingtoneService().start(),
          );
        }
        _startPolling();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _pollTimer?.cancel();
        break;
      default:
        break;
    }
  }

  @override
  Future<bool> didPopRoute() async {
    // true = handled, so neither the router nor Android closes anything.
    // Bag inventory, opened from the popup, keeps its normal back button.
    final state = _cubit.state;
    return state.hasVisible && !state.isManagingBags;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<IncomingOrdersCubit, IncomingOrdersState>(
          listenWhen: (prev, curr) =>
              prev.hasUnaccepted != curr.hasUnaccepted ||
              prev.orders != curr.orders ||
              prev.acceptedOrderIds != curr.acceptedOrderIds ||
              prev.minimizedOrderIds != curr.minimizedOrderIds,
          listener: (context, state) => _syncRinging(state),
        ),
        BlocListener<IncomingOrdersCubit, IncomingOrdersState>(
          listenWhen: (prev, curr) =>
              prev.noticeId != curr.noticeId && curr.notice != null,
          listener: (context, state) {
            // This widget sits above the app's navigator and messenger.
            final appContext = GlobalKeys.navigatorKey.currentContext;
            if (appContext == null || !appContext.mounted) return;
            showCustomSnackbar(
              context: appContext,
              message: state.notice!,
              isWarning: true,
            );
          },
        ),
      ],
      child: widget.child,
    );
  }
}
