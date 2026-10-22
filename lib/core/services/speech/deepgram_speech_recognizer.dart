import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'speech_recognizer.dart';

/// Phase 1 engine: records the recitation locally, then sends it to the
/// `transcribe-recitation` Supabase Edge Function, which forwards it to
/// Deepgram. The Deepgram API key never leaves the server.
///
/// Enable with `--dart-define=SPEECH_ENGINE=deepgram --dart-define=TRANSCRIBE_URL=...`.
class DeepgramSpeechRecognizer implements SpeechRecognizer {
  final Uri endpoint;
  final String anonKey;
  final String? Function()? accessToken;
  final AudioRecorder _recorder;
  final http.Client _http;
  final _controller = StreamController<SpeechUpdate>.broadcast();

  StreamSubscription<Amplitude>? _ampSub;
  String? _path;

  DeepgramSpeechRecognizer({
    required this.endpoint,
    required this.anonKey,
    this.accessToken,
    AudioRecorder? recorder,
    http.Client? client,
  })  : _recorder = recorder ?? AudioRecorder(),
        _http = client ?? http.Client();

  @override
  String get engineLabel => 'Deepgram (cloud)';

  @override
  bool get supportsPartials => false;

  @override
  Stream<SpeechUpdate> get updates => _controller.stream;

  void _emit(SpeechPhase phase,
      {String transcript = '', double level = 0, String? error}) {
    if (_controller.isClosed) return;
    _controller.add(SpeechUpdate(
      transcript: transcript,
      isFinal: phase == SpeechPhase.done,
      level: level,
      phase: phase,
      error: error,
    ));
  }

  @override
  Future<bool> initialize() => _recorder.hasPermission();

  @override
  Future<void> start() async {
    if (!await initialize()) {
      _emit(SpeechPhase.error, error: 'Microphone permission is off.');
      return;
    }
    final dir = await getTemporaryDirectory();
    _path = '${dir.path}/recitation_${DateTime.now().millisecondsSinceEpoch}.wav';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: _path!,
    );
    _ampSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 80))
        .listen((a) {
      // dBFS (-60..0) -> 0..1
      final level = ((a.current + 60) / 60).clamp(0.0, 1.0);
      _emit(SpeechPhase.listening, level: level);
    });
    _emit(SpeechPhase.listening);
  }

  @override
  Future<String> stop() async {
    await _ampSub?.cancel();
    final path = await _recorder.stop() ?? _path;
    if (path == null) return '';
    _emit(SpeechPhase.processing);
    final file = File(path);
    try {
      final token = accessToken?.call() ?? anonKey;
      final res = await _http
          .post(
            endpoint,
            headers: {
              'Content-Type': 'audio/wav',
              'apikey': anonKey,
              'Authorization': 'Bearer $token',
            },
            body: await file.readAsBytes(),
          )
          .timeout(const Duration(seconds: 30));
      if (res.statusCode != 200) {
        throw HttpException('Transcription failed (${res.statusCode})');
      }
      final transcript =
          (jsonDecode(res.body) as Map<String, dynamic>)['transcript'] as String? ?? '';
      _emit(SpeechPhase.done, transcript: transcript);
      return transcript;
    } catch (e) {
      _emit(SpeechPhase.error,
          error: 'Couldn\'t reach the transcription service. Check your connection.');
      return '';
    } finally {
      if (await file.exists()) await file.delete();
    }
  }

  @override
  Future<void> cancel() async {
    await _ampSub?.cancel();
    await _recorder.cancel();
    _emit(SpeechPhase.idle);
  }

  @override
  Future<void> dispose() async {
    await _ampSub?.cancel();
    await _recorder.dispose();
    _http.close();
    await _controller.close();
  }
}
