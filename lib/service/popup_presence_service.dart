import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hyper_local_seller/config/api_routes.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/screen/order_page/popup_users/repo/popup_users_repo.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';
import 'package:hyper_local_seller/utils/permission_checker.dart';

/// Why this device is or isn't reporting popup presence.
enum PopupPresenceStatus {
  /// Logged out, or the role has no `order.popup`.
  off,

  /// The user turned order alerts off.
  disabledByUser,

  /// Waiting for location permission or the first GPS fix.
  locating,

  /// Location is being reported; nearby orders can be offered.
  active,

  /// Device location services are switched off.
  serviceDisabled,

  /// Location permission was denied (can be asked again).
  permissionDenied,

  /// Location permission was denied permanently; only app settings can fix it.
  permissionDeniedForever,

  /// The last presence update didn't reach the server.
  offline,
}

/// Reports the device's GPS position to `POST /seller/orders/popup-presence`
/// so the backend can offer this user incoming orders from stores within
/// 200 m. The server ignores presence older than two minutes, so while
/// active we send on start, on every meaningful move and on a heartbeat.
///
/// The main seller owner is only a fallback recipient and their location is
/// never checked, so the owner is never asked for location: presence is just
/// `{active: true}` on a heartbeat. If the owner already granted location,
/// the location stream still runs because it keeps reporting alive in the
/// background; the server ignores the owner's coordinates.
///
/// Keeps running in the background where the platform allows: an Android
/// foreground-service notification, iOS background location updates.
class PopupPresenceService {
  static final PopupPresenceService _instance = PopupPresenceService._();
  factory PopupPresenceService() => _instance;
  PopupPresenceService._();

  /// Comfortably inside the server's two-minute freshness window.
  static const heartbeatInterval = Duration(seconds: 45);

  /// Movement smaller than this doesn't trigger an extra update.
  static const minMoveMeters = 25;

  /// Stream events closer together than this are folded into the next one.
  static const _minSendGap = Duration(seconds: 10);

  /// Same as the server's freshness window.
  static const _maxCachedFixAge = Duration(minutes: 2);

  final ApiBaseHelper _helper = ApiBaseHelper();
  final ValueNotifier<PopupPresenceStatus> status = ValueNotifier(
    PopupPresenceStatus.off,
  );

  StreamSubscription<Position>? _positions;
  Timer? _heartbeat;
  Position? _last;
  DateTime? _lastSentAt;
  Future<void>? _starting;

  /// Automatic syncs ask for location permission once per app run; asking
  /// again needs the user's own action ([setEnabled], [enableLocation]).
  bool _askedPermission = false;

  /// Bumped on every stop, so callbacks from an older run do nothing.
  int _generation = 0;

  /// Reporting as the main seller owner: no location needed.
  bool _ownerMode = false;
  bool get isOwnerMode => _ownerMode;

  /// Whether the signed-in user is the main seller owner, and for which
  /// user id that was learned.
  bool? _isOwner;
  Object? _ownerFor;

  /// Answers "is this user the owner?": true, false, or null when unknown
  /// (offline). Replaced in tests.
  @visibleForTesting
  Future<bool?> Function() ownerProbe = _probeOwner;

  /// Sends a presence body. Replaced in tests.
  @visibleForTesting
  late Future<dynamic> Function(Map<String, dynamic> body) postPresence =
      (body) => _helper.post(ApiRoutes.popupPresenceApi, body);

  bool get isRunning => _heartbeat != null;

  static bool get _isLoggedIn =>
      HiveStorage.userToken?.trim().isNotEmpty ?? false;

  static bool get _isPermitted =>
      _isLoggedIn && PermissionChecker.canShowOrderPopup;

  /// Starts or stops reporting to match login, role and the user's toggle.
  /// Safe to call often (app start, resume, permission changes).
  /// [requestPermission] asks for location access when it isn't granted.
  Future<void> sync({bool requestPermission = false}) =>
      _sync(requestPermission && !_askedPermission);

  /// Never throws: a platform error leaves presence off rather than
  /// surfacing in whatever widget or lifecycle hook asked for the sync.
  Future<void> _sync(bool requestPermission) async {
    try {
      await _syncUnguarded(requestPermission);
    } catch (e) {
      debugPrint('[PopupPresence] sync failed: $e');
      _generation++;
      await _cancelTracking();
      status.value = PopupPresenceStatus.off;
    }
  }

  Future<void> _syncUnguarded(bool requestPermission) async {
    if (!_isPermitted) {
      // Logged out or no `order.popup`: nothing to tell the server.
      if (!_isLoggedIn) _isOwner = null;
      await stop(notifyServer: false);
      return;
    }
    if (!HiveStorage.orderAlertsEnabled) {
      if (isRunning) await stop();
      status.value = PopupPresenceStatus.disabledByUser;
      return;
    }
    if (isRunning) {
      // Permission may have been revoked while the app was in background.
      if (_positions == null) return;
      final permission = await Geolocator.checkPermission();
      if (_granted(permission)) return;
      if (_ownerMode) {
        _dropLocation(); // The owner stays available without location.
      } else {
        await _lostLocation(_statusFor(permission));
      }
      return;
    }
    await (_starting ??= _start(requestPermission).whenComplete(() {
      _starting = null;
    }));
  }

  /// The user's "order alerts" switch.
  Future<void> setEnabled(bool enabled) async {
    await HiveStorage.setOrderAlertsEnabled(enabled);
    if (enabled) {
      await _sync(true);
    } else {
      await stop();
      if (_isPermitted) status.value = PopupPresenceStatus.disabledByUser;
    }
  }

  /// The user asked to fix location access: opens system settings when the
  /// app can't ask any more, otherwise asks again.
  Future<void> enableLocation() async {
    try {
      switch (status.value) {
        case PopupPresenceStatus.serviceDisabled:
          await Geolocator.openLocationSettings();
        case PopupPresenceStatus.permissionDeniedForever:
          await Geolocator.openAppSettings();
        default:
          await _sync(true);
      }
    } catch (e) {
      debugPrint('[PopupPresence] could not open location settings: $e');
    }
  }

  /// Stops reporting. With [notifyServer] the backend is told right away
  /// (`active: false`) instead of waiting for the presence to go stale. Must
  /// run before logout, while the access token is still valid.
  Future<void> stop({bool notifyServer = true}) async {
    _generation++;
    _ownerMode = false;
    await _cancelTracking();
    status.value = HiveStorage.orderAlertsEnabled || !_isPermitted
        ? PopupPresenceStatus.off
        : PopupPresenceStatus.disabledByUser;
    if (notifyServer && _isPermitted) await _sendInactive();
  }

  Future<void> _start(bool requestPermission) async {
    final generation = _generation;
    status.value = PopupPresenceStatus.locating;

    final owner = await _resolveOwner();
    if (generation != _generation) return;
    if (owner) return _startOwner(generation);

    if (!await Geolocator.isLocationServiceEnabled()) {
      status.value = PopupPresenceStatus.serviceDisabled;
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied && requestPermission) {
      _askedPermission = true;
      permission = await Geolocator.requestPermission();
    }
    if (generation != _generation) return;
    if (!_granted(permission)) {
      status.value = _statusFor(permission);
      return;
    }

    _startHeartbeat(generation);
    await _startTracking(generation);
  }

  /// Owner presence: `{active: true}` now and on every heartbeat. Location
  /// is used only if already granted, never asked for.
  Future<void> _startOwner(int generation) async {
    _ownerMode = true;
    _startHeartbeat(generation);
    unawaited(_send(null, generation));
    if (await _locationAlreadyAvailable() && generation == _generation) {
      await _startTracking(generation);
    }
  }

  void _startHeartbeat(int generation) {
    _heartbeat = Timer.periodic(heartbeatInterval, (_) {
      if (generation != _generation) return;
      final last = _last;
      if (last != null || _ownerMode) _send(last, generation);
    });
  }

  /// Location permission is granted and location is on, without asking.
  static Future<bool> _locationAlreadyAvailable() async {
    try {
      return _granted(await Geolocator.checkPermission()) &&
          await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      debugPrint('[PopupPresence] location check failed: $e');
      return false;
    }
  }

  Future<void> _startTracking(int generation) async {
    _positions = Geolocator.getPositionStream(
      locationSettings: _locationSettings(),
    ).listen(
      (position) => _onPosition(position, generation),
      onError: (Object error) {
        debugPrint('[PopupPresence] location stream error: $error');
        if (generation != _generation) return;
        if (_ownerMode) {
          _dropLocation();
          return;
        }
        _lostLocation(
          error is LocationServiceDisabledException
              ? PopupPresenceStatus.serviceDisabled
              : PopupPresenceStatus.permissionDenied,
        );
      },
    );
    // Report straight away rather than waiting for the first stream fix,
    // but only from a recent fix: an old one may be somewhere else.
    try {
      final known = await Geolocator.getLastKnownPosition();
      if (known != null &&
          DateTime.now().difference(known.timestamp) < _maxCachedFixAge &&
          generation == _generation &&
          _last == null) {
        _onPosition(known, generation);
      }
    } catch (e) {
      debugPrint('[PopupPresence] no last known position: $e');
    }
  }

  void _onPosition(Position position, int generation) {
    if (generation != _generation) return;
    final previous = _last;
    _last = position;
    final sentRecently =
        _lastSentAt != null &&
        DateTime.now().difference(_lastSentAt!) < _minSendGap;
    final moved =
        previous == null ||
        Geolocator.distanceBetween(
              previous.latitude,
              previous.longitude,
              position.latitude,
              position.longitude,
            ) >=
            minMoveMeters;
    if (_lastSentAt == null || (moved && !sentRecently)) {
      _send(position, generation);
    }
  }

  /// [position] is null only for the owner, who needs no coordinates.
  Future<void> _send(Position? position, int generation) async {
    _lastSentAt = DateTime.now();
    try {
      await postPresence({
        'active': true,
        if (position != null) ...{
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
      });
      if (generation == _generation) {
        status.value = PopupPresenceStatus.active;
      }
    } catch (e) {
      debugPrint('[PopupPresence] update failed: $e');
      if (generation != _generation) return;
      if (e is ApiException && e.statusCode == 403) {
        // The role lost `order.popup`; the server won't take presence.
        await stop(notifyServer: false);
      } else {
        status.value = PopupPresenceStatus.offline;
      }
    }
  }

  Future<void> _sendInactive() async {
    try {
      await postPresence({'active': false});
    } catch (e) {
      debugPrint('[PopupPresence] deactivate failed: $e');
    }
  }

  /// Location stopped being available: tell the server so no new orders are
  /// assigned to a user we can no longer place.
  Future<void> _lostLocation(PopupPresenceStatus reason) async {
    _generation++;
    await _cancelTracking();
    status.value = reason;
    if (_isPermitted) await _sendInactive();
  }

  /// The owner lost location: keep reporting presence without coordinates.
  void _dropLocation() {
    final positions = _positions;
    _positions = null;
    _last = null;
    positions?.cancel();
  }

  /// The owner needs no location, so finding out comes first. A role named
  /// `seller` settles it; otherwise the owner-only availability endpoint
  /// does (200 owner, 403 not), once per signed-in user.
  Future<bool> _resolveOwner() async {
    if (PermissionChecker.isDefaultSeller) return true;
    final user = HiveStorage.userData?['id'];
    if (_isOwner != null && _ownerFor == user) return _isOwner!;
    final result = await ownerProbe();
    if (result != null) {
      _isOwner = result;
      _ownerFor = user;
    }
    return result ?? false;
  }

  static Future<bool?> _probeOwner() async {
    try {
      await PopupUsersRepo().getAvailability();
      return true;
    } on ApiException catch (e) {
      return e.statusCode == 403 ? false : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _cancelTracking() async {
    _heartbeat?.cancel();
    _heartbeat = null;
    final positions = _positions;
    _positions = null;
    _last = null;
    _lastSentAt = null;
    await positions?.cancel();
  }

  static bool _granted(LocationPermission permission) =>
      permission == LocationPermission.always ||
      permission == LocationPermission.whileInUse;

  static PopupPresenceStatus _statusFor(LocationPermission permission) =>
      permission == LocationPermission.deniedForever
      ? PopupPresenceStatus.permissionDeniedForever
      : PopupPresenceStatus.permissionDenied;

  static LocationSettings _locationSettings() {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: minMoveMeters,
        intervalDuration: const Duration(seconds: 30),
        // A foreground service keeps updates coming while backgrounded.
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Order alerts are on',
          notificationText:
              'Sharing your location so nearby orders can reach you.',
          notificationChannelName: 'Order alerts location',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    }
    if (Platform.isIOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        // iOS suspends a backgrounded app once updates stop arriving, which
        // would also stop the heartbeat. Sends are throttled in [_onPosition].
        distanceFilter: 0,
        activityType: ActivityType.other,
        pauseLocationUpdatesAutomatically: false,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: minMoveMeters,
    );
  }
}
