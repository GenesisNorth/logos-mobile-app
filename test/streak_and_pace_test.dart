import 'package:flutter_test/flutter_test.dart';
import 'package:logos_mobile_app/core/clock.dart';
import 'package:logos_mobile_app/features/journey/bloc/journey_bloc.dart';
import 'package:logos_mobile_app/features/journey/bloc/journey_event.dart';
import 'package:logos_mobile_app/features/journey/bloc/journey_state.dart';
import 'package:logos_mobile_app/features/journey/data/content_repository.dart';
import 'package:logos_mobile_app/features/journey/data/progress_repository.dart';

class _MemoryRepo implements ProgressRepository {
  UserProfileData profile =
      const UserProfileData(username: 'pilgrim', displayName: UserProfileData.defaultDisplayName);
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
  group('Daily streak', () {
    late _MemoryRepo repo;
    late FixedClock clock;
    late JourneyBloc bloc;

    setUp(() async {
      repo = _MemoryRepo();
      clock = FixedClock(DateTime(2026, 11, 8, 19, 0));
      bloc = JourneyBloc(progressRepo: repo, clock: clock);
      bloc.add(const LoadJourneyProgress());
      await _settle();
    });

    tearDown(() => bloc.close());

    Future<void> recite() async {
      bloc.add(const CompleteDayRecitation(dayNumber: 1, score: 0.95));
      await _settle();
    }

    test('fresh pilgrim starts with zero streak and zero roots', () {
      expect(bloc.state.activeStreak(now: clock.now()), 0);
      expect(bloc.state.rootsPlanted, 0);
      expect(bloc.state.profile.displayName, UserProfileData.defaultDisplayName);
    });

    test('first practice starts streak at 1; more practice the same day keeps it', () async {
      await recite();
      expect(bloc.state.activeStreak(now: clock.now()), 1);
      await recite();
      expect(bloc.state.activeStreak(now: clock.now()), 1);
    });

    test('practice on consecutive days extends the streak', () async {
      await recite();
      clock.advance(const Duration(days: 1));
      await recite();
      clock.advance(const Duration(days: 1));
      await recite();
      expect(bloc.state.activeStreak(now: clock.now()), 3);
    });

    test('streak shows as broken after a missed day and restarts at 1', () async {
      await recite();
      clock.advance(const Duration(days: 1));
      await recite(); // streak 2
      clock.advance(const Duration(days: 2)); // missed one day
      expect(bloc.state.activeStreak(now: clock.now()), 0);
      expect(bloc.state.isStreakRecoverable(now: clock.now()), isTrue);
      await recite();
      expect(bloc.state.activeStreak(now: clock.now()), 1);
    });

    test('grace token restores a streak after exactly one missed day', () async {
      await recite();
      clock.advance(const Duration(days: 1));
      await recite(); // streak 2
      clock.advance(const Duration(days: 2));
      bloc.add(const RedeemGraceToken(dayToRecover: 2));
      await _settle();
      expect(bloc.state.graceTokensBalance, 2);
      expect(bloc.state.activeStreak(now: clock.now()), 2);
      await recite();
      expect(bloc.state.activeStreak(now: clock.now()), 3);
    });

    test('streak and last practice date survive a reload', () async {
      await recite();
      clock.advance(const Duration(days: 1));
      await recite();
      final reloaded = JourneyBloc(progressRepo: repo, clock: clock)
        ..add(const LoadJourneyProgress());
      await _settle();
      expect(reloaded.state.activeStreak(now: clock.now()), 2);
      await reloaded.close();
    });
  });

  group('Pace-lock timing', () {
    test('no midnight countdown while the previous day is unfinished', () {
      final state = JourneyState.initial(const ContentRepository().drops.first);
      expect(state.isDayUnlocked(2), isFalse);
      expect(state.timeUntilUnlock(2), isNull);
    });
  });
}
