import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logos_mobile_app/core/clock.dart';
import 'package:logos_mobile_app/core/utils/scripture_verifier.dart';
import 'package:logos_mobile_app/core/design/organic.dart';
import 'package:logos_mobile_app/features/journey/bloc/journey_bloc.dart';
import 'package:logos_mobile_app/features/journey/bloc/journey_event.dart';
import 'package:logos_mobile_app/features/journey/data/content_repository.dart';
import 'package:logos_mobile_app/features/journey/data/progress_repository.dart';
import 'package:logos_mobile_app/core/services/audio_service.dart';
import 'package:logos_mobile_app/features/community/data/community_repository.dart';
import 'package:logos_mobile_app/core/services/notification_service.dart';
import 'package:logos_mobile_app/features/journey/data/scripture_pack_repository.dart';
import 'package:logos_mobile_app/features/journey/screens/scripture_packs_sheet.dart';
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
  // Plain `test()`s below touch the audio plugin, which has no implementation
  // under `flutter test`: answer its channels with no-ops.
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final channel in ['xyz.luan/audioplayers.global', 'xyz.luan/audioplayers']) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(MethodChannel(channel), (_) async => null);
  }

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

    test('Grace token never completes unfinished content and is not spent without a missed day', () async {
      bloc.add(const RedeemGraceToken());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.dayCompletionStatus[1], isFalse);
      expect(bloc.state.graceTokensBalance, equals(3));
      expect(bloc.state.isDayUnlocked(2, now: fixedClock.now()), isFalse);
    });

    test('ContentRepository has 5 comprehensive drops with Greek and Hebrew exegesis', () {
      final drops = contentRepo.drops;
      expect(drops.length, equals(5));
      expect(drops[0].reference, equals('John 15:5'));
      expect(drops[1].reference, equals('Philippians 4:6-7'));
      expect(drops[2].reference, equals('Romans 8:1-2'));
      expect(drops[3].reference, equals('Psalm 23:1-3'));
      expect(drops[4].reference, equals('Colossians 3:1-3'));

      // Check Greek & Hebrew exegesis presence in context cards
      expect(drops[0].contextCards.any((c) => c.title.contains('Menō')), isTrue);
      expect(drops[1].contextCards.any((c) => c.content.contains('phroureō')), isTrue);
      expect(drops[2].contextCards.any((c) => c.title.contains('Katakrima')), isTrue);
      expect(drops[3].contextCards.any((c) => c.title.contains('Yahweh Rohi')), isTrue);
      expect(drops[4].contextCards.any((c) => c.title.contains('Synēgerthēte')), isTrue);
    });

    test('SelectWeek and AdvanceToNextWeek switches activeDrop correctly', () async {
      expect(bloc.state.activeDrop.weekNumber, equals(1));

      bloc.add(const SelectWeek(3)); // Select Week 4 (Psalm 23)
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.activeDrop.weekNumber, equals(4));
      expect(bloc.state.activeDrop.reference, equals('Psalm 23:1-3'));

      bloc.add(const AdvanceToNextWeek());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.activeDrop.weekNumber, equals(5));
      expect(bloc.state.activeDrop.reference, equals('Colossians 3:1-3'));
    });
  });

  group('CommunityRepository & Realtime Room Tests', () {
    late CommunityRepository communityRepo;

    setUp(() {
      communityRepo = CommunityRepository();
    });

    test('fetchPrayers returns cached pastoral and community petitions', () async {
      // The Well starts empty (private petitions are never seeded).
      final wellPrayers = await communityRepo.fetchPrayers(room: 'the_well');
      expect(wellPrayers.any((p) => p.pastorResponse != null), isFalse);

      final valleyPrayers = await communityRepo.fetchPrayers(room: 'valley');
      expect(valleyPrayers.isNotEmpty, isTrue);
    });

    test('submitPrayer prepends new petition and increments count on prayFor', () async {
      final newPetition = await communityRepo.submitPrayer(
        room: 'the_well',
        title: 'Peace in Decision',
        content: 'Praying for wisdom in a major life crossroads.',
        authorName: 'Pilgrim',
      );

      expect(newPetition.title, equals('Peace in Decision'));
      expect(newPetition.prayedCount, equals(1));

      await communityRepo.prayFor(room: 'the_well', prayerId: newPetition.id);
      final updated = await communityRepo.fetchPrayers(room: 'the_well');
      final found = updated.firstWhere((p) => p.id == newPetition.id);
      expect(found.prayedCount, equals(2));
    });
  });

  testWidgets('LogosApp renders Onboarding Covenant or Sanctuary successfully', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const LogosApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('LOGOS IN ME'), findsAtLeastNWidgets(1));
  });





  group('Multi-Track Ambient Stems & Liturgical Haptic Tests', () {
    test('AudioService configures multi-track stem volumes and mute correctly', () async {
      final audio = AudioService();

      await audio.setDroneVolume(0.8);
      expect(audio.droneVolume, equals(0.8));

      await audio.setRainVolume(0.5);
      expect(audio.rainVolume, equals(0.5));

      await audio.setResonanceVolume(0.6);
      expect(audio.resonanceVolume, equals(0.6));

      await audio.setBreezeVolume(0.7);
      expect(audio.breezeVolume, equals(0.7));

      await audio.setBellsVolume(0.9);
      expect(audio.bellsVolume, equals(0.9));

      audio.applyPreset('cloister_rain');
      expect(audio.activePreset, equals('cloister_rain'));
      expect(audio.rainVolume, equals(0.85));

      audio.applyPreset('gregorian_cathedral');
      expect(audio.activePreset, equals('gregorian_cathedral'));
      expect(audio.resonanceVolume, equals(0.85));

      audio.applyPreset('midnight_examen');
      expect(audio.activePreset, equals('midnight_examen'));
      expect(audio.breezeVolume, equals(0.80));

      audio.applyPreset('apostolic_sabbath');
      expect(audio.activePreset, equals('apostolic_sabbath'));
      expect(audio.bellsVolume, equals(0.75));

      final initialMute = audio.isMuted;
      await audio.toggleMute();
      expect(audio.isMuted, equals(!initialMute));
      await audio.toggleMute();
    });

    test('Liturgical haptic methods execute cleanly without throwing', () async {
      final audio = AudioService();
      expect(() => audio.wordProgressTick(), returnsNormally);
      expect(() => audio.triggerExchangeHaptic(), returnsNormally);
      expect(() => audio.emberPulse(), returnsNormally);
      expect(() => audio.breathTick(), returnsNormally);
      expect(() => audio.selectionTick(), returnsNormally);
      await expectLater(audio.sacredCelebrationHaptic(), completes);
      await expectLater(audio.liturgicalHourChime(), completes);
    });


    test('NotificationService registers and persists valid 64-char APNS hex token', () async {
      SharedPreferences.setMockInitialValues({});
      final token = await NotificationService.instance.registerDevicePushToken(
        customToken: 'a1b2c3d4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f90',
      );

      expect(token.length, equals(64));
      expect(NotificationService.instance.deviceToken, equals(token));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('logos_apns_device_token'), equals(token));
    });

    test('ScripturePackRepository handles pack lifecycle (fetch, download, delete, storage)', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = ScripturePackRepository();

      // 1. Fetch packs
      final packs = await repo.fetchPacks();
      expect(packs.length, equals(4));
      expect(packs.first.isBuiltIn, isTrue);
      expect(packs.first.isDownloaded, isTrue);

      // Pack 2 is not yet downloaded
      expect(packs[1].isDownloaded, isFalse);

      // 2. Download pack 2
      final progressValues = <double>[];
      await repo.downloadPack(packs[1].id, onProgress: (p) => progressValues.add(p));

      expect(progressValues, isNotEmpty);
      expect(progressValues.last, equals(1.0));

      final updatedPacks = await repo.fetchPacks();
      expect(updatedPacks[1].isDownloaded, isTrue);

      // 3. Storage calculation
      final storage = await repo.totalStorageUsedMb();
      expect(storage, isA<double>());
      expect(storage, greaterThan(0.0));

      // 4. Delete downloaded pack
      await repo.deletePack(packs[1].id);
      final afterDelete = await repo.fetchPacks();
      expect(afterDelete[1].isDownloaded, isFalse);
    });

    testWidgets('ScripturePacksSheet displays packs and handles cloister download', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({});
      final repo = ScripturePackRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: organicTheme(),
          home: Scaffold(
            body: ScripturePacksSheet(repository: repo),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verifies title and packs
      expect(find.text('Offline Scripture Packs'), findsOneWidget);
      expect(find.text('Foundation of Peace'), findsOneWidget);
      expect(find.text('Heavenly Ascent'), findsOneWidget);
      expect(find.text('Built-In Core ✓'), findsOneWidget);

      // Tap download on the second pack
      final downloadButtons = find.text('Download');
      expect(downloadButtons, findsWidgets);
      await tester.tap(downloadButtons.first);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
    });


  });

  group('Scripture Multi-Translation Bridge Tests', () {
    test('ScriptureDrop withTranslation switches verse text authentically across ESV, KJV, NASB, NIV', () {
      const repo = ContentRepository();
      for (final drop in repo.drops) {
        expect(drop.translations, isNotNull);
        expect(drop.translations!.containsKey('ESV'), isTrue);
        expect(drop.translations!.containsKey('KJV'), isTrue);
        expect(drop.translations!.containsKey('NASB'), isTrue);
        expect(drop.translations!.containsKey('NIV'), isTrue);

        final kjvDrop = drop.withTranslation('KJV');
        expect(kjvDrop.translation, equals('KJV'));
        expect(kjvDrop.verseText, equals(drop.translations!['KJV']));
        expect(kjvDrop.reference, equals(drop.reference));

        final nasbDrop = drop.withTranslation('NASB');
        expect(nasbDrop.translation, equals('NASB'));
        expect(nasbDrop.verseText, equals(drop.translations!['NASB']));

        final nivDrop = drop.withTranslation('NIV');
        expect(nivDrop.translation, equals('NIV'));
        expect(nivDrop.verseText, equals(drop.translations!['NIV']));
      }
    });

    test('JourneyBloc SelectTranslation switches active drop translation and preserves on next week', () async {
      final repo = InMemoryProgressRepository();
      final bloc = JourneyBloc(progressRepo: repo);

      expect(bloc.state.activeDrop.translation, equals('ESV'));

      bloc.add(const SelectTranslation('KJV'));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.activeDrop.translation, equals('KJV'));
      expect(bloc.state.activeDrop.verseText, contains('ye are the branches'));

      // Advancing week maintains chosen translation
      bloc.add(const AdvanceToNextWeek());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.activeDrop.weekNumber, equals(2));
      expect(bloc.state.activeDrop.translation, equals('KJV'));
      expect(bloc.state.activeDrop.verseText, contains('Be careful for nothing'));
    });

  });
}


