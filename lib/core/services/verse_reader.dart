import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Reading speeds offered in Settings.
enum ReadingSpeed {
  slow('Slow', 0.38),
  normal('Normal', 0.46),
  brisk('Brisk', 0.54);

  final String label;
  final double rate;
  const ReadingSpeed(this.label, this.rate);
}

/// Reads Scripture aloud with the device's text-to-speech engine (free, offline).
class VerseReader extends ChangeNotifier {
  VerseReader._();
  static final VerseReader instance = VerseReader._();

  static const _speedKey = 'logos_reading_speed';

  // Created lazily so tests and screens that never read aloud don't touch the plugin.
  FlutterTts? _tts;
  bool _speaking = false;
  String? _currentText;
  ReadingSpeed _speed = ReadingSpeed.normal;

  bool get isSpeaking => _speaking;
  ReadingSpeed get speed => _speed;

  /// Whether [text] is the passage currently being read.
  bool isReading(String text) => _speaking && _currentText == text;

  Future<void> loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_speedKey);
      _speed = ReadingSpeed.values.firstWhere((s) => s.name == name, orElse: () => ReadingSpeed.normal);
    } catch (_) {}
  }

  Future<void> setSpeed(ReadingSpeed speed) async {
    _speed = speed;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_speedKey, speed.name);
  }

  Future<FlutterTts> _engine() async {
    final existing = _tts;
    if (existing != null) return existing;
    final tts = FlutterTts();
    await tts.setLanguage('en-US');
    await tts.setPitch(1.0);
    await tts.awaitSpeakCompletion(false);
    tts.setCompletionHandler(_finished);
    tts.setCancelHandler(_finished);
    tts.setErrorHandler((_) => _finished());
    _tts = tts;
    return tts;
  }

  void _finished() {
    _speaking = false;
    _currentText = null;
    notifyListeners();
  }

  /// Reads [text] aloud, optionally followed by its [reference].
  /// Returns false if the device has no usable speech engine.
  Future<bool> speak(String text, {String? reference}) async {
    try {
      final tts = await _engine();
      await tts.stop();
      await tts.setSpeechRate(_speed.rate);
      _speaking = true;
      _currentText = text;
      notifyListeners();
      final spoken = speakable(reference == null ? text : '$text\n\n$reference.');
      final result = await tts.speak(spoken);
      if (result != 1) {
        _finished();
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('[VerseReader] speak failed: $e');
      _finished();
      return false;
    }
  }

  Future<void> stop() async {
    try {
      await _tts?.stop();
    } catch (_) {}
    _finished();
  }

  /// Rewrites text so speech engines pronounce it naturally
  /// ("LORD" is otherwise spelled out letter by letter).
  @visibleForTesting
  static String speakable(String text) {
    return text
        .replaceAll('LORD', 'Lord')
        .replaceAll('GOD', 'God')
        .replaceAll('YHWH', 'Yahweh')
        .replaceAll('I AM', 'I am')
        .replaceAll(RegExp(r'[\[\]⸤⸥|]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
