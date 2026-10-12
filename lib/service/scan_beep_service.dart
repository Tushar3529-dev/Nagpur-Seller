import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:hyper_local_seller/utils/image_path.dart';

/// Plays the store-scanner beep whenever the camera reads a code, right or
/// wrong.
class ScanBeepService {
  static final ScanBeepService _instance = ScanBeepService._internal();
  factory ScanBeepService() => _instance;
  ScanBeepService._internal();

  /// The camera reports the same code on every frame while it is in view.
  /// It beeps again only once the code has been out of view this long.
  static const _repeatGap = Duration(milliseconds: 1200);

  AudioPlayer? _player;
  Future<void>? _setup;
  String? _lastCode;
  DateTime? _lastSeenAt;

  Future<void> _ensureReady() {
    return _setup ??= () async {
      final player = AudioPlayer(playerId: 'scanner_beep');
      _player = player;
      await player.setAudioContext(
        AudioContext(
          // Media stream, like a video's sound: the system/sonification
          // stream is muted or very low on many phones. No audio focus, so
          // music and the order ringtone keep playing.
          android: const AudioContextAndroid(
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.none,
          ),
          // Playback so the beep is heard with the silent switch on too;
          // mixWithOthers keeps other audio playing.
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {AVAudioSessionOptions.mixWithOthers},
          ),
        ),
      );
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setSource(AssetSource(AudioPath.scannerBeep));
    }();
  }

  /// Loads the beep ahead of time so the first scan plays without delay.
  Future<void> preload() async {
    try {
      await _ensureReady();
    } catch (e) {
      debugPrint('[ScanBeep] failed to load: $e');
      await _reset();
    }
  }

  /// Beeps for [code] read by the camera, unless it is the same code still
  /// in view from the last frames.
  void onCodeRead(String code) {
    final now = DateTime.now();
    final stillInView =
        code == _lastCode &&
        _lastSeenAt != null &&
        now.difference(_lastSeenAt!) < _repeatGap;
    _lastCode = code;
    _lastSeenAt = now;
    if (!stillInView) play();
  }

  Future<void> play() async {
    try {
      await _ensureReady();
      final player = _player!;
      // Restart from the top if the previous beep is still playing.
      await player.stop();
      await player.resume();
    } catch (e) {
      debugPrint('[ScanBeep] failed to play: $e');
      await _reset();
    }
  }

  /// Drops a player that failed so the next beep builds a fresh one.
  Future<void> _reset() async {
    final player = _player;
    _player = null;
    _setup = null;
    try {
      await player?.dispose();
    } catch (_) {}
  }
}
