import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'speech_recognizer.dart';

/// Phase 0 engine: the phone's built-in speech recognition
/// (Apple Speech on iOS, Google RecognitionService on Android).
///
/// Android's recognizer ends a session on its own after a short silence
/// (often 1–2 s) and reports `error_no_match` / `error_speech_timeout` when the
/// user hasn't started speaking yet. To make recitation feel like a single
/// continuous recording, this class transparently restarts the platform
/// session until the user taps stop (or [maxSession] elapses), accumulating
/// the transcript across segments.
class DeviceSpeechRecognizer implements SpeechRecognizer {
  final SpeechToText _stt;
  final Duration maxSession;
  final _controller = StreamController<SpeechUpdate>.broadcast();

  /// Text from platform segments that have already ended.
  String _committed = '';

  /// Live partial text from the current platform segment.
  String _segment = '';

  /// Last segment committed, used to ignore late duplicate final results.
  String _lastCommittedSegment = '';

  double _level = 0;
  bool _initialized = false;

  /// True while the user wants to be recording.
  bool _active = false;
  bool _restartScheduled = false;
  DateTime? _startedAt;
  Completer<String>? _finalCompleter;

  DeviceSpeechRecognizer({
    SpeechToText? stt,
    this.maxSession = const Duration(seconds: 90),
  }) : _stt = stt ?? SpeechToText();

  @override
  String get engineLabel => 'Built-in speech recognition';

  @override
  bool get supportsPartials => true;

  @override
  Stream<SpeechUpdate> get updates => _controller.stream;

  String get _transcript =>
      [_committed, _segment].where((s) => s.trim().isNotEmpty).join(' ').trim();

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
    try {
      _initialized = await _stt.initialize(
        onError: _onError,
        onStatus: _onStatus,
        debugLogging: kDebugMode,
        // Recitation uses the phone mic; skip the "nearby devices" (Bluetooth) prompt.
        options: [SpeechToText.androidNoBluetooth],
      );
    } catch (e) {
      debugPrint('[DeviceSpeechRecognizer] initialize failed: $e');
      _initialized = false;
    }
    return _initialized;
  }

  void _onError(SpeechRecognitionError e) {
    debugPrint('[DeviceSpeechRecognizer] error: ${e.errorMsg} (permanent: ${e.permanent})');
    final benign = e.errorMsg == 'error_no_match' ||
        e.errorMsg == 'error_speech_timeout' ||
        e.errorMsg == 'error_busy' ||
        e.errorMsg == 'error_client';
    if (_active && benign) {
      // Silence or a recognizer hiccup — keep the recording alive.
      _scheduleRestart();
      return;
    }
    if (!_active) {
      // Errors after the user pressed stop just mean "nothing more to add".
      _finish();
      return;
    }
    final msg = switch (e.errorMsg) {
      'error_permission' || 'error_insufficient_permissions' =>
        'Microphone or speech permission is off. Enable it in Settings.',
      'error_network' || 'error_network_timeout' || 'error_server' =>
        'Speech service needs a connection on this phone. Check your internet or type your recitation.',
      'error_language_not_supported' || 'error_language_unavailable' =>
        'English speech recognition isn\'t installed on this phone.',
      'error_audio_error' || 'error_audio' =>
        'The microphone couldn\'t be opened. Close other apps using it and try again.',
      _ => 'Speech recognition error (${e.errorMsg}). Try again or type your recitation.',
    };
    _active = false;
    _commitSegment();
    final c = _finalCompleter;
    if (c != null && !c.isCompleted) c.complete(_transcript);
    _emit(SpeechPhase.error, error: msg);
  }

  void _onStatus(String status) {
    debugPrint('[DeviceSpeechRecognizer] status: $status');
    if (status == SpeechToText.doneStatus ||
        status == SpeechToText.notListeningStatus) {
      if (_active) {
        _scheduleRestart();
      } else {
        _finish();
      }
    }
  }

  void _onResult(SpeechRecognitionResult r) {
    final words = r.recognizedWords.trim();
    if (r.finalResult && words.isNotEmpty && words == _lastCommittedSegment && _segment.isEmpty) {
      return; // Late duplicate of a segment we already committed.
    }
    _segment = words;
    if (r.finalResult) _commitSegment();
    _emit(SpeechPhase.listening);
    if (!_active && r.finalResult) _finish();
  }

  void _commitSegment() {
    if (_segment.isEmpty) return;
    _committed = [_committed, _segment].where((s) => s.isNotEmpty).join(' ');
    _lastCommittedSegment = _segment;
    _segment = '';
  }

  void _scheduleRestart() {
    if (_restartScheduled) return;
    final started = _startedAt;
    if (started != null && DateTime.now().difference(started) >= maxSession) {
      _active = false;
      _finish();
      return;
    }
    _restartScheduled = true;
    _commitSegment();
    Future.delayed(const Duration(milliseconds: 250), () async {
      _restartScheduled = false;
      if (!_active || _controller.isClosed) return;
      if (_stt.isListening) return;
      try {
        await _listen();
      } catch (e) {
        debugPrint('[DeviceSpeechRecognizer] restart failed: $e');
        _active = false;
        _finish();
      }
    });
  }

  void _finish() {
    _commitSegment();
    final c = _finalCompleter;
    if (c != null && !c.isCompleted) {
      c.complete(_transcript);
      _emit(SpeechPhase.done, isFinal: true);
    }
  }

  Future<void> _listen() {
    return _stt.listen(
      onResult: _onResult,
      onSoundLevelChange: (level) {
        _level = ((level + 2) / 12).clamp(0.0, 1.0);
        _emit(SpeechPhase.listening);
      },
      listenOptions: SpeechListenOptions(
        partialResults: true,
        listenMode: ListenMode.dictation,
        cancelOnError: true,
        listenFor: maxSession,
        pauseFor: const Duration(seconds: 8),
      ),
    );
  }

  @override
  Future<void> start() async {
    if (!await initialize()) {
      throw StateError(
          'Speech recognition isn\'t available on this phone. On Android, make sure the Google app / "Speech Recognition & Synthesis" is installed and enabled, then try again — or type your recitation.');
    }
    if (_stt.isListening) {
      await _stt.cancel();
    }
    _committed = '';
    _segment = '';
    _lastCommittedSegment = '';
    _level = 0;
    _active = true;
    _restartScheduled = false;
    _startedAt = DateTime.now();
    _finalCompleter = Completer<String>();
    _emit(SpeechPhase.listening);
    await _listen();
  }

  @override
  Future<String> stop() async {
    final c = _finalCompleter;
    if (c == null) return _transcript;
    _active = false;
    if (c.isCompleted) return c.future;
    _emit(SpeechPhase.processing);
    try {
      await _stt.stop();
    } catch (_) {}
    if (!_stt.isListening) {
      // Already idle (e.g. between auto-restarts) — finish right away.
      Future.delayed(const Duration(milliseconds: 600), _finish);
    }
    return c.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        _finish();
        return _transcript;
      },
    );
  }

  @override
  Future<void> cancel() async {
    _active = false;
    _finalCompleter = null;
    await _stt.cancel();
    _emit(SpeechPhase.idle);
  }

  @override
  Future<void> dispose() async {
    _active = false;
    try {
      await _stt.cancel();
    } catch (_) {}
    await _controller.close();
  }
}
