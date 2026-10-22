import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioRecorder _audioRecorder = AudioRecorder();

  /// Play amen chime on successful recitation
  Future<void> playAmenChime() async {
    try {
      HapticFeedback.mediumImpact();
      // Falls back silently if sound asset is being streamed or mocked in tests
      await _audioPlayer.play(AssetSource('audio/amen_chime.wav'));
    } catch (_) {
      // Graceful fallback: trigger haptic only
      HapticFeedback.mediumImpact();
    }
  }

  /// Play sanctuary reminder / ambient chime
  Future<void> playSanctuaryChime() async {
    try {
      HapticFeedback.lightImpact();
      await _audioPlayer.play(AssetSource('audio/sanctuary_chime.wav'));
    } catch (_) {
      HapticFeedback.lightImpact();
    }
  }

  /// Fire heavy impact haptic on The Exchange collision
  void triggerExchangeHaptic() {
    HapticFeedback.heavyImpact();
  }

  AudioRecorder get recorder => _audioRecorder;
}
