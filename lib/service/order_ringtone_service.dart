import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

/// Rings like an incoming call (the phone's ringtone, plus vibration) while
/// there are unaccepted orders on screen.
class OrderRingtoneService {
  static final OrderRingtoneService _instance =
      OrderRingtoneService._internal();
  factory OrderRingtoneService() => _instance;
  OrderRingtoneService._internal();

  final FlutterRingtonePlayer _player = FlutterRingtonePlayer();
  Timer? _vibrationTimer;
  Timer? _iosRepeatTimer;
  bool _isRinging = false;

  bool get isRinging => _isRinging;

  Future<void> start() async {
    if (_isRinging) return;
    _isRinging = true;

    _vibrationTimer?.cancel();
    HapticFeedback.vibrate();
    _vibrationTimer = Timer.periodic(
      const Duration(milliseconds: 1500),
      (_) => HapticFeedback.vibrate(),
    );

    // iOS only plays a one-shot system sound and can't loop it, so it is
    // replayed on a timer. Android loops the real ringtone itself.
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      _iosRepeatTimer?.cancel();
      _iosRepeatTimer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => _ring(),
      );
    }
    await _ring();
  }

  Future<void> _ring() async {
    if (!_isRinging) return;
    try {
      // asAlarm: alarm stream on Android, so it still rings when the phone
      // is on silent or vibrate (the ring stream is muted then).
      await _player.playRingtone(looping: true, asAlarm: true);
    } catch (e) {
      debugPrint('[OrderRingtone] failed to start: $e');
    }
  }

  Future<void> stop() async {
    if (!_isRinging) return;
    _isRinging = false;
    _vibrationTimer?.cancel();
    _vibrationTimer = null;
    _iosRepeatTimer?.cancel();
    _iosRepeatTimer = null;
    try {
      await _player.stop();
    } catch (e) {
      debugPrint('[OrderRingtone] failed to stop: $e');
    }
  }
}
