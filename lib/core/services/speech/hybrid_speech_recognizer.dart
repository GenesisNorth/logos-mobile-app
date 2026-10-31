import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../utils/scripture_verifier.dart';
import 'device_speech_recognizer.dart';
import 'groq_whisper_service.dart';
import 'speech_recognizer.dart';

/// Hybrid speech recognizer that provides the best of both worlds:
/// 1. Instant on-device streaming transcription with 0ms latency ($0 cost, 100% offline).
/// 2. Automatic Groq Whisper Large V3 cloud second opinion if the on-device match falls
///    below the 80% passing threshold on difficult biblical words or accents.
class HybridSpeechRecognizer implements SpeechRecognizer {
  final String? targetVerse;
  final DeviceSpeechRecognizer _deviceRecognizer;
  final GroqWhisperService _whisperService;
  final AudioRecorder _audioRecorder;
  final _controller = StreamController<SpeechUpdate>.broadcast();

  StreamSubscription<SpeechUpdate>? _deviceSub;
  String? _recordedAudioPath;
  String _latestTranscript = '';
  double _currentLevel = 0.0;

  HybridSpeechRecognizer({
    this.targetVerse,
    DeviceSpeechRecognizer? deviceRecognizer,
    GroqWhisperService? whisperService,
    AudioRecorder? audioRecorder,
  })  : _deviceRecognizer = deviceRecognizer ?? DeviceSpeechRecognizer(),
        _whisperService = whisperService ?? GroqWhisperService(),
        _audioRecorder = audioRecorder ?? AudioRecorder();

  @override
  String get engineLabel => GroqWhisperService.isAvailable
      ? 'Hybrid (On-Device + Whisper V3 Fallback)'
      : 'On-Device Speech Engine';

  @override
  bool get supportsPartials => true;

  @override
  Stream<SpeechUpdate> get updates => _controller.stream;

  @override
  Future<bool> initialize() async {
    final devOk = await _deviceRecognizer.initialize();
    _deviceSub?.cancel();
    _deviceSub = _deviceRecognizer.updates.listen((u) {
      _latestTranscript = u.transcript;
      _currentLevel = u.level;
      if (!_controller.isClosed) {
        _controller.add(u);
      }
    });

    if (GroqWhisperService.isAvailable) {
      await _audioRecorder.hasPermission();
    }
    return devOk;
  }

  @override
  Future<void> start() async {
    _latestTranscript = '';

    // 1. Start live on-device streaming recognition
    await _deviceRecognizer.start();

    // 2. Concurrently record high-fidelity audio for cloud fallback if configured
    if (GroqWhisperService.isAvailable) {
      try {
        final tmp = await getTemporaryDirectory();
        _recordedAudioPath =
            '${tmp.path}/recitation_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
          path: _recordedAudioPath!,
        );
      } catch (e) {
        debugPrint('[HybridSpeechRecognizer] Audio recorder fallback warning: $e');
        _recordedAudioPath = null;
      }
    }
  }

  @override
  Future<String> stop() async {

    // 1. Stop on-device engine
    final deviceTranscript = await _deviceRecognizer.stop();
    final chosenDevice =
        deviceTranscript.isNotEmpty ? deviceTranscript : _latestTranscript;

    // 2. Stop audio recorder
    if (_recordedAudioPath != null) {
      try {
        await _audioRecorder.stop();
      } catch (_) {}
    }

    // 3. Check if on-device speech already passes the sacred threshold (>= 80%)
    if (targetVerse != null && targetVerse!.isNotEmpty) {
      final similarity = ScriptureVerifier.calculateSimilarity(
        chosenDevice,
        targetVerse!,
      );

      if (similarity >= 0.80) {
        debugPrint(
            '[HybridSpeechRecognizer] On-device passed ($similarity). Skipping cloud call.');
        _emitFinal(chosenDevice);
        _cleanupAudio();
        return chosenDevice;
      }
    }

    // 4. If on-device fell below 80% and Groq Whisper is available, query second opinion
    if (GroqWhisperService.isAvailable && _recordedAudioPath != null) {
      final file = File(_recordedAudioPath!);
      if (await file.exists()) {
        _emitProcessing('Consulting sacred Whisper engine...');

        final whisperTranscript = await _whisperService.transcribe(
          file,
          scripturePrompt: targetVerse,
        );

        if (whisperTranscript != null && whisperTranscript.trim().isNotEmpty) {
          if (targetVerse != null && targetVerse!.isNotEmpty) {
            final devScore = ScriptureVerifier.calculateSimilarity(
              chosenDevice,
              targetVerse!,
            );
            final whisperScore = ScriptureVerifier.calculateSimilarity(
              whisperTranscript,
              targetVerse!,
            );

            debugPrint(
                '[HybridSpeechRecognizer] Device: $devScore vs Whisper: $whisperScore');

            if (whisperScore >= devScore) {
              _emitFinal(whisperTranscript);
              _cleanupAudio();
              return whisperTranscript;
            }
          } else {
            _emitFinal(whisperTranscript);
            _cleanupAudio();
            return whisperTranscript;
          }
        }
      }
    }

    _emitFinal(chosenDevice);
    _cleanupAudio();
    return chosenDevice;
  }

  @override
  Future<void> cancel() async {
    await _deviceRecognizer.cancel();
    if (_recordedAudioPath != null) {
      try {
        await _audioRecorder.stop();
      } catch (_) {}
      _cleanupAudio();
    }
  }

  @override
  Future<void> dispose() async {
    _deviceSub?.cancel();
    await _deviceRecognizer.dispose();
    await _audioRecorder.dispose();
    _cleanupAudio();
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }

  void _emitProcessing(String status) {
    if (_controller.isClosed) return;
    _controller.add(SpeechUpdate(
      transcript: _latestTranscript,
      isFinal: false,
      level: _currentLevel,
      phase: SpeechPhase.processing,
    ));
  }

  void _emitFinal(String transcript) {
    if (_controller.isClosed) return;
    _controller.add(SpeechUpdate(
      transcript: transcript,
      isFinal: true,
      level: 0,
      phase: SpeechPhase.done,
    ));
  }

  void _cleanupAudio() {
    if (_recordedAudioPath != null) {
      try {
        final f = File(_recordedAudioPath!);
        if (f.existsSync()) {
          f.deleteSync();
        }
      } catch (_) {}
      _recordedAudioPath = null;
    }
  }
}
