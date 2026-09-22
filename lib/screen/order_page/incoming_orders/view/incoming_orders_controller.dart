import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/screen/order_page/incoming_orders/cubit/incoming_orders_cubit.dart';
import 'package:hyper_local_seller/service/notification_service.dart';
import 'package:hyper_local_seller/service/order_ringtone_service.dart';

/// Drives the incoming-order popup from outside the router:
/// - rings while there are pending orders and stops when the stack is empty
/// - swallows the Android back button while orders are pending
/// - re-checks the pending list on resume and on a timer (backup for missed pushes)
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
  static const _pollInterval = Duration(seconds: 20);
  Timer? _pollTimer;

  IncomingOrdersCubit get _cubit => context.read<IncomingOrdersCubit>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
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
        if (_cubit.state.hasPending) {
          // A call or another app may have taken audio focus meanwhile.
          OrderRingtoneService().stop().then(
            (_) => OrderRingtoneService().start(),
          );
          NotificationService().cancelIncomingOrderAlert();
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
    return _cubit.state.hasPending;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<IncomingOrdersCubit, IncomingOrdersState>(
      listenWhen: (prev, curr) => prev.hasPending != curr.hasPending,
      listener: (context, state) {
        if (state.hasPending) {
          OrderRingtoneService().start();
          // The in-app ring takes over from the system alert.
          NotificationService().cancelIncomingOrderAlert();
        } else {
          OrderRingtoneService().stop();
        }
      },
      child: widget.child,
    );
  }
}
