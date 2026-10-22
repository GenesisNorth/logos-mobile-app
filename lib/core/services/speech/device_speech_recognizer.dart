import 'dart:async';

import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'speech_recognizer.dart';

/// Phase 0 engine: the phone's built-in speech recognition
/// (Apple Speech on iOS, Google RecognitionService on Android).
class DeviceSpeechRecognizer implements SpeechRecognizer {
  final SpeechToText _stt;
  final _controller = StreamController<SpeechUpdate>.broadcast();

  String _transcript = '';
  double _level = 0;
  bool _initialized = false;
  Completer<String>? _finalCompleter;

  DeviceSpeechRecognizer({SpeechToText? stt}) : _stt = stt ?? SpeechToText();

  @override
  String get engineLabel => 'Built-in speech recognition';

  @override
  bool get supportsPartials => true;

  @override
  Stream<SpeechUpdate> get updates => _controller.stream;

  void _emit(SpeechPhase phase, {bool isFinal = false, String? error}) {
    if (_controller.isClosed) return;
    _controller.add(SpeechUpdate(
      transcript: _transcript,
      isFinal: isFinal,
      level: _level,
      phase: phase,
      error: error,
    ));
  }

  @override
  Future<bool> initialize() async {
    if (_initialized) return true;
    _initialized = await _stt.initialize(
      onError: _onError,
      onStatus: _onStatus,
    );
    return _initialized;
  }

  void _onError(SpeechRecognitionError e) {
    final msg = switch (e.errorMsg) {
      'error_no_match' || 'error_speech_timeout' =>
        'We didn\'t catch that. Tap the mic and try again.',
      'error_permission' || 'error_insufficient_permissions' =>
        'Microphone or speech permission is off. Enable it in Settings.',
      _ => 'Speech recognition error (${e.errorMsg}).',
    };
    _complete();
    _emit(SpeechPhase.error, error: msg);
  }

  void _onStatus(String status) {
    if (status == SpeechToText.doneStatus ||
        status == SpeechToText.notListeningStatus) {
      _complete();
    }
  }

  void _onResult(SpeechRecognitionResult r) {
    _transcript = r.recognizedWords;
    _emit(SpeechPhase.listening, isFinal: r.finalResult);
    if (r.finalResult) _complete();
  }

  void _complete() {
    final c = _finalCompleter;
    if (c != null && !c.isCompleted) {
      c.complete(_transcript);
      _emit(SpeechPhase.done, isFinal: true);
    }
  }

  @override
  Future<void> start() async {
    if (!await initialize()) {
      _emit(SpeechPhase.error,
          error: 'Speech recognition is not available on this device.');
      return;
    }
    _transcript = '';
    _level = 0;
    _finalCompleter = Completer<String>();
    _emit(SpeechPhase.listening);
    await _stt.listen(
      onResult: _onResult,
      onSoundLevelChange: (level) {
        _level = ((level + 2) / 12).clamp(0.0, 1.0);
        _emit(SpeechPhase.listening);
      },
      listenOptions: SpeechListenOptions(
        partialResults: true,
        listenMode: ListenMode.dictation,
        cancelOnError: true,
        listenFor: const Duration(seconds: 90),
        pauseFor: const Duration(seconds: 6),
      ),
    );
  }

  @override
  Future<String> stop() async {
    final c = _finalCompleter;
    if (c == null) return _transcript;
    _emit(SpeechPhase.processing);
    await _stt.stop();
    return c.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        _complete();
        return _transcript;
      },
    );
  }

  @override
  Future<void> cancel() async {
    _finalCompleter = null;
    await _stt.cancel();
    _emit(SpeechPhase.idle);
  }

  @override
  Future<void> dispose() async {
    await _stt.cancel();
    await _controller.close();
  }
}
