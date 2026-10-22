import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logos_mobile_app/core/clock.dart';
import 'package:logos_mobile_app/core/utils/scripture_verifier.dart';
import 'package:logos_mobile_app/features/journey/bloc/journey_bloc.dart';
import 'package:logos_mobile_app/features/journey/bloc/journey_event.dart';
import 'package:logos_mobile_app/features/journey/data/content_repository.dart';
import 'package:logos_mobile_app/features/journey/data/progress_repository.dart';
import 'package:logos_mobile_app/main.dart';

class InMemoryProgressRepository implements ProgressRepository {
  UserProfileData profile = const UserProfileData(
    username: 'pilgrim',
    displayName: 'Genesis A.',
    covenantSignature: 'mock_signature',
  );
  Map<String, dynamic> journeyData = {};
  List<TearSheetData> tearSheets = [];

  @override
  Future<UserProfileData> loadProfile() async => profile;

  @override
  Future<void> saveProfile(UserProfileData p) async => profile = p;

  @override
  Future<Map<String, dynamic>> loadJourneyData() async => journeyData;

  @override
  Future<void> saveJourneyData(Map<String, dynamic> d) async => journeyData = d;

  @override
  Future<List<TearSheetData>> loadTearSheets() async => tearSheets;

  @override
  Future<void> saveTearSheet(TearSheetData s) async => tearSheets.add(s);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

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
      expect(similarity, equals(1.0));
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

    test('matchedWordCount calculates forward progression correctly', () {
      final count = ScriptureVerifier.matchedWordCount(
        'I am the vine you are the branches',
        'I am the vine',
      );
      expect(count, equals(4));
    });
  });

  group('Midnight Pace-Lock & Journey Progression Tests', () {
    late FixedClock fixedClock;
    late InMemoryProgressRepository progressRepo;
    late ContentRepository contentRepo;
    late JourneyBloc bloc;

    setUp(() {
      final initialTime = DateTime(2026, 10, 22, 10, 0); // Oct 22 at 10:00 AM
      fixedClock = FixedClock(initialTime);
      progressRepo = InMemoryProgressRepository();
      contentRepo = const ContentRepository();
      bloc = JourneyBloc(
        progressRepo: progressRepo,
        contentRepo: contentRepo,
        clock: fixedClock,
      );
    });

    tearDown(() {
      bloc.close();
    });

    test('Day 1 is unlocked initially, while Day 2 is locked', () {
      final state = bloc.state;
      expect(state.isDayUnlocked(1, now: fixedClock.now()), isTrue);
      expect(state.isDayUnlocked(2, now: fixedClock.now()), isFalse);
    });

    test('Completing Day 1 keeps Day 2 locked until midnight strikes', () async {
      // 2 passed recitations on Day 1
      bloc.add(const CompleteDayRecitation(dayNumber: 1, score: 0.95));
      bloc.add(const CompleteDayRecitation(dayNumber: 1, score: 0.92));

      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.dayCompletionStatus[1], isTrue);

      // Same day (10:00 AM) -> Day 2 must be pace-locked
      expect(bloc.state.isDayUnlocked(2, now: fixedClock.now()), isFalse);
      final remaining = bloc.state.timeUntilUnlock(2, now: fixedClock.now());
      expect(remaining, isNotNull);
      expect(remaining!.inHours, equals(14)); // 10:00 AM to midnight = 14 hours

      // Advance clock past midnight (e.g. Oct 23 at 00:05 AM)
      fixedClock.advance(const Duration(hours: 14, minutes: 5));

      // Now Day 2 is unlocked!
      expect(bloc.state.isDayUnlocked(2, now: fixedClock.now()), isTrue);
    });

    test('Redeeming Grace Token unlocks missed day immediately', () async {
      bloc.add(const RedeemGraceToken(dayToRecover: 1));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.dayCompletionStatus[1], isTrue);
      expect(bloc.state.graceTokensBalance, equals(2));
      // Unlocks Day 2 immediately without waiting for midnight
      expect(bloc.state.isDayUnlocked(2, now: fixedClock.now()), isTrue);
    });
  });

  testWidgets('LogosApp renders Onboarding Covenant or Sanctuary successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const LogosApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('LOGOS IN ME'), findsAtLeastNWidgets(1));
  });
}
