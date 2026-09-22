import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hyper_local_seller/utils/image_path.dart';

/// Loops the order ringtone (plus vibration) while there are unaccepted
/// orders on screen.
class OrderRingtoneService {
  static final OrderRingtoneService _instance =
      OrderRingtoneService._internal();
  factory OrderRingtoneService() => _instance;
  OrderRingtoneService._internal();

  final AudioPlayer _player = AudioPlayer(playerId: 'incoming_order_ringtone');
  Timer? _vibrationTimer;
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

    try {
      await _player.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.notificationRingtone,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
            stayAwake: true,
          ),
          // Playback category so it still rings with the iOS silent switch on.
          iOS: AudioContextIOS(category: AVAudioSessionCategory.playback),
        ),
      );
      await _player.setReleaseMode(ReleaseMode.loop);
      // stop() may have been called while the context was being set.
      if (!_isRinging) return;
      await _player.play(AssetSource(AudioPath.inAppNotificationSound));
    } catch (e) {
      debugPrint('[OrderRingtone] failed to start: $e');
    }
  }

  Future<void> stop() async {
    if (!_isRinging) return;
    _isRinging = false;
    _vibrationTimer?.cancel();
    _vibrationTimer = null;
    try {
      await _player.stop();
    } catch (e) {
      debugPrint('[OrderRingtone] failed to stop: $e');
    }
  }
}
