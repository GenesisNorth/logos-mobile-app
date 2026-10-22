/// Build-time configuration via `--dart-define`.
///
/// Examples:
///   flutter run                                   # on-device speech (default)
///   flutter run --dart-define=SPEECH_ENGINE=deepgram \
///     --dart-define=TRANSCRIBE_URL=https://<project>.supabase.co/functions/v1/transcribe-recitation \
///     --dart-define=SUPABASE_ANON_KEY=<anon-key>
class AppConfig {
  /// `device` (Phase 0, default) or `deepgram` (Phase 1).
  static const speechEngine =
      String.fromEnvironment('SPEECH_ENGINE', defaultValue: 'device');

  /// Supabase Edge Function that proxies audio to Deepgram.
  /// The Deepgram key lives server-side only; it is never shipped in the app.
  static const transcribeUrl = String.fromEnvironment('TRANSCRIBE_URL');

  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Seconds of ambient listening required to complete Day 3 Stillness.
  static const stillnessSeconds =
      int.fromEnvironment('STILLNESS_SECONDS', defaultValue: 60);

  static bool get useDeepgram =>
      speechEngine == 'deepgram' && transcribeUrl.isNotEmpty;
}
