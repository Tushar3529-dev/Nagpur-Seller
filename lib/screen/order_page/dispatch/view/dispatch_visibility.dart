import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/config/app_permissions.dart';
import 'package:hyper_local_seller/utils/permission_checker.dart';

// Router visibility also covers Orders in the retained indexed navigation shell.
mixin DispatchVisibility<T extends StatefulWidget>
    on State<T>, WidgetsBindingObserver {
  GoRouter? _dispatchRouter;
  bool _foreground = true;
  bool? _wasVisible;
  Set<String> get dispatchVisiblePaths;
  void dispatchVisibilityChanged(bool visible);

  @override
  void initState() {
    super.initState();
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    HiveStorage.userDataRevision.addListener(_permissionsChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = GoRouter.of(context);
    if (_dispatchRouter != router) {
      _dispatchRouter?.routerDelegate.removeListener(_scheduleVisibility);
      _dispatchRouter = router;
      router.routerDelegate.addListener(_scheduleVisibility);
    }
    _scheduleVisibility();
  }

  void _permissionsChanged() {
    if (!mounted) return;
    syncDispatchVisibility();
    setState(() {});
  }

  void _scheduleVisibility() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      syncDispatchVisibility();
    });
  }

  void syncDispatchVisibility() {
    final path = _dispatchRouter?.routerDelegate.state.uri.path;
    final visible =
        _foreground &&
        dispatchVisiblePaths.contains(path) &&
        PermissionChecker.hasPermission(AppPermissions.orderView);
    if (_wasVisible == visible) return;
    _wasVisible = visible;
    dispatchVisibilityChanged(visible);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    syncDispatchVisibility();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    HiveStorage.userDataRevision.removeListener(_permissionsChanged);
    _dispatchRouter?.routerDelegate.removeListener(_scheduleVisibility);
    dispatchVisibilityChanged(false);
    super.dispose();
  }
}
