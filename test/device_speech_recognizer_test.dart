import 'package:flutter_test/flutter_test.dart';
import 'package:logos_mobile_app/core/services/speech/device_speech_recognizer.dart';
import 'package:logos_mobile_app/core/services/speech/speech_recognizer.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Simulates the platform recognizer, including Android's habit of ending a
/// session by itself after a short silence.
class FakeStt extends Fake implements SpeechToText {
  bool available = true;
  bool listening = false;
  int listenCalls = 0;
  SpeechErrorListener? onError;
  SpeechStatusListener? onStatus;
  SpeechResultListener? onResult;

  @override
  Future<bool> initialize({
    SpeechErrorListener? onError,
    SpeechStatusListener? onStatus,
    debugLogging = false,
    Duration finalTimeout = const Duration(milliseconds: 2000),
    List<SpeechConfigOption>? options,
  }) async {
    this.onError = onError;
    this.onStatus = onStatus;
    return available;
  }

  @override
  bool get isListening => listening;

  @override
  Future listen({
    SpeechResultListener? onResult,
    Duration? listenFor,
    Duration? pauseFor,
    String? localeId,
    SpeechSoundLevelChange? onSoundLevelChange,
    cancelOnError = false,
    partialResults = true,
    onDevice = false,
    ListenMode listenMode = ListenMode.confirmation,
    sampleRate = 0,
    SpeechListenOptions? listenOptions,
  }) async {
    this.onResult = onResult;
    listening = true;
    listenCalls++;
    onStatus?.call(SpeechToText.listeningStatus);
  }

  @override
  Future<void> stop() async {
    listening = false;
    onStatus?.call(SpeechToText.notListeningStatus);
    onStatus?.call(SpeechToText.doneStatus);
  }

  @override
  Future<void> cancel() async {
    listening = false;
  }

  void words(String w, {bool isFinal = false}) {
    onResult?.call(SpeechRecognitionResult.init(
      [SpeechRecognitionWords(w, null, 0.9)],
      isFinal ? ResultType.finalResult : ResultType.partial,
    ));
  }

  /// Platform ends the session on its own (silence).
  void platformEnds() {
    listening = false;
    onStatus?.call(SpeechToText.notListeningStatus);
    onStatus?.call(SpeechToText.doneStatus);
  }

  void platformError(String msg) {
    listening = false;
    onError?.call(SpeechRecognitionError(msg, true));
  }
}

void main() {
  group('DeviceSpeechRecognizer (continuous recording)', () {
    test('keeps recording when platform session auto-ends and joins segments', () async {
      final stt = FakeStt();
      final rec = DeviceSpeechRecognizer(stt: stt);
      final phases = <SpeechPhase>[];
      rec.updates.listen((u) => phases.add(u.phase));

      await rec.start();
      stt.words('I am the vine');
      stt.words('I am the vine you are the branches', isFinal: true);
      stt.platformEnds();

      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(stt.listenCalls, 2, reason: 'should auto-restart after silence');
      expect(phases.contains(SpeechPhase.done), isFalse,
          reason: 'must not finish before the user taps stop');

      stt.words('whoever abides in me');
      final transcript = await rec.stop();

      expect(transcript, 'I am the vine you are the branches whoever abides in me');
      await Future<void>.delayed(Duration.zero);
      expect(phases.last, SpeechPhase.done);
      await rec.dispose();
    });

    test('silence errors (no_match) do not end the recording', () async {
      final stt = FakeStt();
      final rec = DeviceSpeechRecognizer(stt: stt);
      final errors = <String?>[];
      rec.updates.listen((u) {
        if (u.phase == SpeechPhase.error) errors.add(u.error);
      });

      await rec.start();
      stt.platformError('error_no_match');
      await Future<void>.delayed(const Duration(milliseconds: 400));

      expect(errors, isEmpty);
      expect(stt.listenCalls, 2);

      stt.words('abide in me');
      expect(await rec.stop(), 'abide in me');
      await rec.dispose();
    });

    test('permission error stops recording and reports a clear message', () async {
      final stt = FakeStt();
      final rec = DeviceSpeechRecognizer(stt: stt);
      final errors = <String?>[];
      rec.updates.listen((u) {
        if (u.phase == SpeechPhase.error) errors.add(u.error);
      });

      await rec.start();
      stt.platformError('error_permission');
      await Future<void>.delayed(const Duration(milliseconds: 400));

      expect(errors.single, contains('permission'));
      expect(stt.listenCalls, 1);
      await rec.dispose();
    });

    test('throws a helpful error when speech is unavailable on the phone', () async {
      final stt = FakeStt()..available = false;
      final rec = DeviceSpeechRecognizer(stt: stt);
      expect(rec.start(), throwsA(isA<StateError>()));
      await rec.dispose();
    });
  });
}
