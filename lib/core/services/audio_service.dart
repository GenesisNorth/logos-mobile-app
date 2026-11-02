import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Multi-track ambient sanctuary stems, liturgical chimes, and tactile haptics.
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _sfx = AudioPlayer(playerId: 'sfx');

  // Multi-track contemplative stem players
  final AudioPlayer _dronePlayer = AudioPlayer(playerId: 'stem_drone');
  final AudioPlayer _rainPlayer = AudioPlayer(playerId: 'stem_rain');
  final AudioPlayer _resonancePlayer = AudioPlayer(playerId: 'stem_resonance');

  // Track stem volumes (0.0 to 1.0)
  double _droneVolume = 0.70;
  double _rainVolume = 0.35;
  double _resonanceVolume = 0.45;
  double _masterVolume = 0.85;
  bool _isMuted = false;
  bool _isPlaying = false;
  String _activePreset = 'sanctuary_dawn';

  double get droneVolume => _droneVolume;
  double get rainVolume => _rainVolume;
  double get resonanceVolume => _resonanceVolume;
  double get masterVolume => _masterVolume;
  bool get isMuted => _isMuted;
  bool get isAmbientPlaying => _isPlaying;
  String get activePreset => _activePreset;

  /// Maps a Scripture Drop ambient preset to its bundled loop.
  static String ambientAssetFor(String preset) => switch (preset) {
        'sanctuary_dune' => 'audio/ambient_sanctuary_dune.wav',
        'cloister_rain' => 'audio/ambient_gentle_rain.wav',
        'gregorian_cathedral' => 'audio/ambient_gregorian_resonance.wav',
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
    await sacredCelebrationHaptic();
    await _playSfx('audio/amen_chime.wav');
  }

  Future<void> playSanctuaryChime() async {
    await liturgicalHourChime();
    await _playSfx('audio/sanctuary_chime.wav');
  }

  /// Starts or resumes multi-track ambient soundscapes.
  Future<void> startAmbient([String? preset]) async {
    if (preset != null && preset != _activePreset) {
      applyPreset(preset);
    }

    try {
      _isPlaying = true;
      await Future.wait([
        _configureStem(_dronePlayer, 'audio/ambient_sanctuary_dawn.wav', _effectiveDroneVolume),
        _configureStem(_rainPlayer, 'audio/ambient_gentle_rain.wav', _effectiveRainVolume),
        _configureStem(_resonancePlayer, 'audio/ambient_gregorian_resonance.wav', _effectiveResonanceVolume),
      ]);

      await Future.wait([
        _dronePlayer.resume(),
        _rainPlayer.resume(),
        _resonancePlayer.resume(),
      ]).timeout(const Duration(milliseconds: 100), onTimeout: () => []);
    } catch (_) {}
  }

  Future<void> _configureStem(AudioPlayer player, String asset, double volume) async {
    try {
      await Future.wait([
        player.setReleaseMode(ReleaseMode.loop),
        player.setSource(AssetSource(asset)),
        player.setVolume(volume),
      ]).timeout(const Duration(milliseconds: 100), onTimeout: () => []);
    } catch (_) {}
  }

  double get _effectiveDroneVolume => _isMuted ? 0.0 : (_droneVolume * _masterVolume).clamp(0.0, 1.0);
  double get _effectiveRainVolume => _isMuted ? 0.0 : (_rainVolume * _masterVolume).clamp(0.0, 1.0);
  double get _effectiveResonanceVolume => _isMuted ? 0.0 : (_resonanceVolume * _masterVolume).clamp(0.0, 1.0);

  Future<void> _syncVolumes() async {
    try {
      await Future.wait([
        _dronePlayer.setVolume(_effectiveDroneVolume),
        _rainPlayer.setVolume(_effectiveRainVolume),
        _resonancePlayer.setVolume(_effectiveResonanceVolume),
      ]).timeout(const Duration(milliseconds: 200), onTimeout: () => []);
    } catch (_) {}
  }

  Future<void> setDroneVolume(double vol) async {
    _droneVolume = vol.clamp(0.0, 1.0);
    await _syncVolumes();
  }

  Future<void> setRainVolume(double vol) async {
    _rainVolume = vol.clamp(0.0, 1.0);
    await _syncVolumes();
  }

  Future<void> setResonanceVolume(double vol) async {
    _resonanceVolume = vol.clamp(0.0, 1.0);
    await _syncVolumes();
  }

  Future<void> setAmbientVolume(double volume) async {
    _masterVolume = volume.clamp(0.0, 1.0);
    await _syncVolumes();
  }

  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    await _syncVolumes();
  }

  void applyPreset(String preset) {
    _activePreset = preset;
    switch (preset) {
      case 'cloister_rain':
        _droneVolume = 0.30;
        _rainVolume = 0.85;
        _resonanceVolume = 0.25;
        break;
      case 'gregorian_cathedral':
      case 'sanctuary_dune':
        _droneVolume = 0.45;
        _rainVolume = 0.15;
        _resonanceVolume = 0.85;
        break;
      case 'sanctuary_dawn':
      default:
        _droneVolume = 0.70;
        _rainVolume = 0.35;
        _resonanceVolume = 0.45;
        break;
    }
    _syncVolumes();
  }

  Future<void> pauseAmbient() async {
    try {
      _isPlaying = false;
      await Future.wait([
        _dronePlayer.pause(),
        _rainPlayer.pause(),
        _resonancePlayer.pause(),
      ]).timeout(const Duration(milliseconds: 200), onTimeout: () => []);
    } catch (_) {}
  }

  Future<void> stopAmbient() async {
    try {
      _isPlaying = false;
      await Future.wait([
        _dronePlayer.stop(),
        _rainPlayer.stop(),
        _resonancePlayer.stop(),
      ]).timeout(const Duration(milliseconds: 200), onTimeout: () => []);
    } catch (_) {}
  }

  // --- Liturgical Tactile Haptic Engine ---

  /// Gentle physical tick when speech recognizes matching scripture words.
  void wordProgressTick() => HapticFeedback.selectionClick();

  /// Sacred three-stage celebration pulse when recitation passes.
  Future<void> sacredCelebrationHaptic() async {
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 120));
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 140));
    HapticFeedback.heavyImpact();
  }

  /// Double resonant chime sensation for liturgical bells and hourly alerts.
  Future<void> liturgicalHourChime() async {
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 180));
    HapticFeedback.lightImpact();
  }

  /// Heavy impact when the Word meets the burden in The Exchange.
  void triggerExchangeHaptic() => HapticFeedback.heavyImpact();

  /// Progressive ember crackle haptic during burden dissolution.
  void emberPulse() => HapticFeedback.mediumImpact();

  /// Soft tactile click at breathing cadence transitions.
  void breathTick() => HapticFeedback.lightImpact();

  /// UI interaction tick.
  void selectionTick() => HapticFeedback.selectionClick();
}

