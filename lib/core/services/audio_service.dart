import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Chimes, ambient sanctuary loops and haptics.
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _sfx = AudioPlayer(playerId: 'sfx');
  final AudioPlayer _ambient = AudioPlayer(playerId: 'ambient');
  String? _ambientAsset;

  /// Maps a Scripture Drop ambient preset to its bundled loop.
  static String ambientAssetFor(String preset) => switch (preset) {
        'sanctuary_dune' => 'audio/ambient_sanctuary_dune.wav',
        _ => 'audio/ambient_sanctuary_dawn.wav',
      };

  Future<void> _playSfx(String asset) async {
    try {
      await _sfx.stop();
      await _sfx.play(AssetSource(asset), volume: 0.9);
    } catch (_) {
      // Audio is non-critical; haptics still fire.
    }
  }

  /// Played when a recitation passes the 80% threshold.
  Future<void> playAmenChime() async {
    HapticFeedback.mediumImpact();
    await _playSfx('audio/amen_chime.wav');
  }

  Future<void> playSanctuaryChime() async {
    HapticFeedback.lightImpact();
    await _playSfx('audio/sanctuary_chime.wav');
  }

  bool get isAmbientPlaying => _ambient.state == PlayerState.playing;

  Future<void> startAmbient(String preset) async {
    try {
      final asset = ambientAssetFor(preset);
      if (_ambientAsset != asset) {
        await _ambient.setReleaseMode(ReleaseMode.loop);
        await _ambient.setSource(AssetSource(asset));
        _ambientAsset = asset;
      }
      await _ambient.setVolume(0.7);
      await _ambient.resume();
    } catch (_) {}
  }

  Future<void> pauseAmbient() async {
    try {
      await _ambient.pause();
    } catch (_) {}
  }

  Future<void> stopAmbient() async {
    try {
      await _ambient.stop();
    } catch (_) {}
  }

  /// Heavy impact when the Word meets the burden in The Exchange.
  void triggerExchangeHaptic() => HapticFeedback.heavyImpact();

  void selectionTick() => HapticFeedback.selectionClick();
}
