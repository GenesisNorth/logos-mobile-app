import '../../config/app_config.dart';
import 'deepgram_speech_recognizer.dart';
import 'device_speech_recognizer.dart';

enum SpeechPhase { idle, listening, processing, done, error }

class SpeechUpdate {
  final String transcript;
  final bool isFinal;

  /// Normalised microphone level 0..1 for the waveform ring.
  final double level;
  final SpeechPhase phase;
  final String? error;

  const SpeechUpdate({
    this.transcript = '',
    this.isFinal = false,
    this.level = 0,
    this.phase = SpeechPhase.idle,
    this.error,
  });
}

/// Engine-agnostic speech-to-text used by the Recitation Studio.
///
/// Phase 0 uses [DeviceSpeechRecognizer] (OS speech services).
/// Phase 1 can switch to [DeepgramSpeechRecognizer] with no UI changes.
abstract class SpeechRecognizer {
  String get engineLabel;

  /// Whether live partial transcripts are emitted while speaking.
  bool get supportsPartials;

  Stream<SpeechUpdate> get updates;

  /// Requests permissions and prepares the engine. Returns false if unavailable.
  Future<bool> initialize();

  Future<void> start();

  /// Stops listening and resolves with the final transcript.
  Future<String> stop();

  Future<void> cancel();

  Future<void> dispose();

  static SpeechRecognizer create() => AppConfig.useDeepgram
      ? DeepgramSpeechRecognizer(
          endpoint: Uri.parse(AppConfig.transcribeUrl),
          anonKey: AppConfig.supabaseAnonKey,
        )
      : DeviceSpeechRecognizer();
}
