import 'package:flutter_test/flutter_test.dart';
import 'package:logos_mobile_app/core/utils/scripture_verifier.dart';
import 'package:logos_mobile_app/main.dart';

void main() {
  group('ScriptureVerifier & Levenshtein Engine Tests', () {
    const targetVerse =
        'I am the vine; you are the branches. Whoever abides in me and I in him, he it is that bears much fruit, for apart from me you can do nothing.';

    test('Identical verse yields 1.0 (100% similarity)', () {
      final similarity = ScriptureVerifier.calculateSimilarity(targetVerse, targetVerse);
      expect(similarity, equals(1.0));
      expect(ScriptureVerifier.hasPassed(targetVerse, targetVerse), isTrue);
    });

    test('Normalized punctuation still passes >= 80%', () {
      const transcribedWithoutPunctuation =
          'i am the vine you are the branches whoever abides in me and i in him he it is that bears much fruit for apart from me you can do nothing';
      final similarity = ScriptureVerifier.calculateSimilarity(targetVerse, transcribedWithoutPunctuation);
      expect(similarity, equals(1.0)); // After normalization, they are identical
      expect(ScriptureVerifier.hasPassed(targetVerse, transcribedWithoutPunctuation), isTrue);
    });

    test('Speech pause with single minor typo still passes >= 80%', () {
      const slightlyFlawedSpeech =
          'I am the vine, you are the branches. Whoever abides in me and I in him, he it is that bears much fruit, for apart from me you do nothing.';
      final similarity = ScriptureVerifier.calculateSimilarity(targetVerse, slightlyFlawedSpeech);
      expect(similarity, greaterThanOrEqualTo(0.80));
      expect(ScriptureVerifier.hasPassed(targetVerse, slightlyFlawedSpeech), isTrue);
    });

    test('Completely wrong text fails < 80%', () {
      const wrongText = 'The Lord is my shepherd I shall not want';
      final similarity = ScriptureVerifier.calculateSimilarity(targetVerse, wrongText);
      expect(similarity, lessThan(0.80));
      expect(ScriptureVerifier.hasPassed(targetVerse, wrongText), isFalse);
    });
  });

  testWidgets('LogosApp renders Sanctuary Home screen successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const LogosApp());
    await tester.pumpAndSettle();

    expect(find.text('LOGOS IN ME'), findsOneWidget);
    expect(find.text('The 4-Day Sacred Rhythm'), findsOneWidget);
  });
}
