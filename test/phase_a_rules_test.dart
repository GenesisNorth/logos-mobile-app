import 'package:flutter_test/flutter_test.dart';
import 'package:logos_mobile_app/core/clock.dart';
import 'package:logos_mobile_app/core/config/app_flags.dart';
import 'package:logos_mobile_app/core/services/glance_service.dart';
import 'package:logos_mobile_app/core/services/verse_reader.dart';
import 'package:logos_mobile_app/features/community/data/moderation_store.dart';
import 'package:logos_mobile_app/features/journey/bloc/journey_bloc.dart';
import 'package:logos_mobile_app/features/journey/bloc/journey_event.dart';
import 'package:logos_mobile_app/features/journey/data/bible_translations.dart';
import 'package:logos_mobile_app/features/journey/data/content_repository.dart';
import 'package:logos_mobile_app/features/journey/data/progress_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemoryRepo implements ProgressRepository {
  UserProfileData profile = const UserProfileData(username: 'pilgrim', displayName: 'Pilgrim');
  Map<String, dynamic> journeyData = {};
  final List<TearSheetData> sheets = [];
  @override
  Future<UserProfileData> loadProfile() async => profile;
  @override
  Future<void> saveProfile(UserProfileData p) async => profile = p;
  @override
  Future<Map<String, dynamic>> loadJourneyData() async => journeyData;
  @override
  Future<void> saveJourneyData(Map<String, dynamic> d) async => journeyData = d;
  @override
  Future<List<TearSheetData>> loadTearSheets() async => sheets;
  @override
  Future<void> saveTearSheet(TearSheetData s) async => sheets.add(s);
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Week selection integrity', () {
    test('verse can change before the rhythm starts, not mid-week', () async {
      final bloc = JourneyBloc(progressRepo: _MemoryRepo(), clock: FixedClock(DateTime(2026, 11, 9, 9)))
        ..add(const LoadJourneyProgress());
      await _settle();
      expect(bloc.state.canChangeWeek, isTrue);

      bloc.add(const CompleteDayRecitation(dayNumber: 1, score: 0.9));
      await _settle();
      expect(bloc.state.canChangeWeek, isFalse);

      bloc.add(const SelectWeek(2));
      await _settle();
      expect(bloc.state.activeDrop.weekNumber, 1, reason: 'mid-week switch is refused');
      expect(bloc.state.dayRecitationCount[1], 1, reason: 'progress is untouched');
      await bloc.close();
    });

    test('finishing the Exchange earns back one grace token (max 3)', () async {
      final repo = _MemoryRepo()..journeyData = {'graceTokensBalance': 1};
      final bloc = JourneyBloc(progressRepo: repo, clock: FixedClock(DateTime(2026, 11, 9, 9)))
        ..add(const LoadJourneyProgress());
      await _settle();
      bloc.add(const CompleteExchange(burdenSummary: 'anxiety'));
      await _settle();
      expect(bloc.state.graceTokensBalance, 2);
      expect(bloc.state.canChangeWeek, isTrue, reason: 'week finished');
      await bloc.close();
    });

    test('display name can be edited', () async {
      final repo = _MemoryRepo();
      final bloc = JourneyBloc(progressRepo: repo)..add(const LoadJourneyProgress());
      await _settle();
      bloc.add(const UpdateDisplayName('  Ruth N. '));
      await _settle();
      expect(bloc.state.profile.displayName, 'Ruth N.');
      expect(repo.profile.displayName, 'Ruth N.');
      await bloc.close();
    });
  });

  group('Translations', () {
    test('every week has text in all 16 catalogued translations', () {
      for (final drop in const ContentRepository().drops) {
        for (final t in bibleTranslations) {
          expect(drop.translations?[t.key], isNotNull, reason: '${drop.reference} missing ${t.key}');
          expect(drop.translations![t.key]!.length, greaterThan(40));
        }
      }
      expect(bibleTranslations.length, 16);
    });

    test('ESV Psalm 23:1-3 includes the end of verse 3', () {
      final psalm = const ContentRepository().drops.firstWhere((d) => d.reference == 'Psalm 23:1-3');
      expect(psalm.translations!['ESV'], contains('paths of righteousness'));
    });
  });

  group('Glance (widgets & Live Activity)', () {
    test('today, resting and complete snapshots', () async {
      final clock = FixedClock(DateTime(2026, 11, 9, 14));
      final bloc = JourneyBloc(progressRepo: _MemoryRepo(), clock: clock)..add(const LoadJourneyProgress());
      await _settle();
      var g = GlanceSnapshot.from(bloc.state, now: clock.now());
      expect(g.status, 'today');
      expect(g.headline, 'Day 1 · Today');
      expect(g.phrase, 'Abide in me.');
      expect(g.days, ['today', 'locked', 'locked', 'locked']);
      expect(g.unlockAt, isNull);

      bloc.add(const CompleteDayRecitation(dayNumber: 1, score: 0.9));
      await _settle();
      g = GlanceSnapshot.from(bloc.state, now: clock.now());
      expect(g.status, 'resting');
      expect(g.headline, 'Roots opens at midnight');
      expect(g.days, ['done', 'locked', 'locked', 'locked']);
      expect(g.unlockAt, DateTime(2026, 11, 10));
      expect(g.toWidgetData()['ref'], 'JOHN 15:5');

      bloc.add(const CompleteDay(2));
      bloc.add(const CompleteDay(3));
      bloc.add(const CompleteExchange(burdenSummary: 'x'));
      await _settle();
      g = GlanceSnapshot.from(bloc.state, now: clock.now());
      expect(g.status, 'complete');
      expect(g.doneCount, 4);
      await bloc.close();
    });

    test('short phrase from the stillness line', () {
      expect(GlanceSnapshot.shortPhrase('“The peace of God will guard your heart.”'), 'The peace of God will guard your heart.');
      expect(GlanceSnapshot.shortPhrase('“Abide in me, and I in you.”'), 'Abide in me.');
    });
  });

  test('speech text is normalised so engines do not spell out LORD', () {
    expect(VerseReader.speakable('The LORD is my shepherd; YHWH [is] near'),
        'The Lord is my shepherd; Yahweh is near');
  });

  test('v1 community: unready rooms are hidden by default', () {
    final flags = AppFlags.instance..setForTest({});
    expect(flags.isOn(AppFlags.roomPrayerCircles), isTrue);
    expect(flags.isOn(AppFlags.roomTheWell), isTrue);
    expect(flags.isOn(AppFlags.roomValley), isTrue);
    expect(flags.isOn(AppFlags.roomStudyPods), isFalse);
    expect(flags.isOn(AppFlags.roomVoiceComfort), isFalse);
    expect(flags.isOn(AppFlags.roomMilestones), isFalse);
    expect(flags.isOn(AppFlags.scripturePacks), isFalse);
    expect(flags.text(AppFlags.crisisLineUri), 'tel:988');
  });

  test('reporting a post records the reason and hides it', () async {
    final store = ModerationStore();
    await store.report('valley-sample-1', reportReasons.first);
    expect(await store.hiddenIds(), contains('valley-sample-1'));
    expect((await store.pendingReports()).single, startsWith('valley-sample-1|Harmful'));
  });
}
