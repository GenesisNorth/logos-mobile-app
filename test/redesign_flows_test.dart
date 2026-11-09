import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logos_mobile_app/core/clock.dart';
import 'package:logos_mobile_app/core/config/app_flags.dart';
import 'package:logos_mobile_app/core/design/organic.dart';
import 'package:logos_mobile_app/core/utils/scripture_verifier.dart';
import 'package:logos_mobile_app/features/altar/screens/altar_screen.dart';
import 'package:logos_mobile_app/features/community/screens/community_screen.dart';
import 'package:logos_mobile_app/features/community/screens/the_well_screen.dart';
import 'package:logos_mobile_app/features/encounter/encounter_screen.dart';
import 'package:logos_mobile_app/features/examen/controllers/examen_controller.dart';
import 'package:logos_mobile_app/features/examen/examen_store.dart';
import 'package:logos_mobile_app/features/exchange/exchange_screen.dart';
import 'package:logos_mobile_app/features/journey/bloc/journey_bloc.dart';
import 'package:logos_mobile_app/features/journey/bloc/journey_event.dart';
import 'package:logos_mobile_app/features/journey/data/content_repository.dart';
import 'package:logos_mobile_app/features/journey/data/progress_repository.dart';
import 'package:logos_mobile_app/features/onboarding/screens/covenant_screen.dart';
import 'package:logos_mobile_app/features/recap/recap_screen.dart';
import 'package:logos_mobile_app/features/roots/roots_screen.dart';
import 'package:logos_mobile_app/features/stillness/stillness_screen.dart';
import 'package:logos_mobile_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Repo implements ProgressRepository {
  UserProfileData profile;
  Map<String, dynamic> journeyData;
  final List<TearSheetData> sheets;
  _Repo({bool signed = true, Map<String, dynamic>? data, List<TearSheetData>? sheets})
      : profile = UserProfileData(
          username: 'pilgrim',
          displayName: 'Ruth N.',
          covenantSignature: signed ? 'sig' : null,
          covenantSignedAt: signed ? DateTime(2026, 11, 1) : null,
        ),
        journeyData = data ?? {},
        sheets = sheets ?? [];

  @override
  Future<UserProfileData> loadProfile() async => profile;
  @override
  Future<void> saveProfile(UserProfileData p) async => profile = p;
  @override
  Future<Map<String, dynamic>> loadJourneyData() async => journeyData;
  @override
  Future<void> saveJourneyData(Map<String, dynamic> d) async => journeyData = d;
  @override
  Future<List<TearSheetData>> loadTearSheets() async => List.of(sheets);
  @override
  Future<void> saveTearSheet(TearSheetData s) async {
    sheets.removeWhere((x) => x.id == s.id);
    sheets.add(s);
  }
}

final _drop = const ContentRepository().drops.first;

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppFlags.instance.setForTest({});
  });

  Future<JourneyBloc> pumpWith(WidgetTester tester, Widget child, {_Repo? repo, Clock? clock}) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    final bloc = JourneyBloc(progressRepo: repo ?? _Repo(), clock: clock)..add(const LoadJourneyProgress());
    await tester.pumpWidget(BlocProvider.value(
      value: bloc,
      child: MaterialApp(theme: organicTheme(), home: child),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    return bloc;
  }

  group('Onboarding', () {
    testWidgets('covenant → chimes → translation, sealed only at the end', (tester) async {
      var done = false;
      final repo = _Repo(signed: false);
      final bloc = await pumpWith(tester, CovenantScreen(onCompleted: () => done = true), repo: repo);

      expect(find.text('A covenant\nof returning.'), findsOneWidget);
      await tester.tap(find.text('Sign the covenant'));
      await tester.pump();
      expect(find.text('Write your name to sign the covenant.'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Ruth');
      await tester.tap(find.text('Sign the covenant'));
      await tester.pumpAndSettle();
      expect(find.text('When should we chime?'), findsOneWidget);
      expect(find.text('Lauds · 7:00 AM'), findsOneWidget);
      expect(bloc.state.profile.hasSignedCovenant, isFalse);

      // Turn every chime off so no permission prompt is needed in tests.
      for (final label in ['Lauds chime', 'Vespers chime']) {
        await tester.tap(find.bySemanticsLabel(label));
        await tester.pump();
      }
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Choose your translation'), findsOneWidget);

      await tester.tap(find.text('KJV'));
      await tester.pump();
      await tester.tap(find.text('Begin Week 1'));
      await tester.pumpAndSettle();
      expect(done, isTrue);
      expect(bloc.state.profile.displayName, 'Ruth');
      expect(bloc.state.activeDrop.translation, 'KJV');
    });
  });

  group('Today', () {
    testWidgets('verse hero with key word, rhythm seeds and today’s hero card', (tester) async {
      await pumpWith(tester, MainAppShell(examenController: ExamenController()));
      expect(find.text('Ruth N.'), findsOneWidget);
      expect(find.text('Week 1 · The Vine'), findsOneWidget);
      expect(find.text('JOHN 15:5'), findsOneWidget);
      expect(find.text('This week’s rhythm'), findsOneWidget);
      for (final d in ['Encounter', 'Roots', 'Stillness', 'Exchange']) {
        expect(find.text(d), findsWidgets);
      }
      expect(find.text('TODAY · DAY 1'), findsOneWidget);
      expect(find.text('Begin · 5 min'), findsOneWidget);
      expect(find.text('grace tokens'), findsOneWidget);
    });

    testWidgets('tapping a locked seed explains when it opens', (tester) async {
      await pumpWith(tester, MainAppShell(examenController: ExamenController()));
      await tester.tap(find.bySemanticsLabel(RegExp(r'^Day 3, Stillness')));
      await tester.pumpAndSettle();
      expect(find.text('Day 2 comes first'), findsOneWidget);
    });

    testWidgets('done for today after Day 1, week complete after Day 4', (tester) async {
      final clock = FixedClock(DateTime(2026, 11, 9, 14));
      final repo = _Repo(data: {
        'dayCompletion': {'1': true, '2': false, '3': false, '4': false},
        'dayCompletedAt': {'1': DateTime(2026, 11, 9, 9).toIso8601String()},
      });
      final bloc = await pumpWith(tester, MainAppShell(examenController: ExamenController()), repo: repo, clock: clock);
      // The UI reads the real clock for unlocks; Day 1 was completed "today" at 09:00
      // only relative to the fixed clock, so assert via state instead.
      expect(bloc.state.todayDay, 2);

      bloc.add(const CompleteDay(2));
      bloc.add(const CompleteDay(3));
      bloc.add(const CompleteExchange(burdenSummary: 'deadline'));
      await tester.pumpAndSettle();
      expect(find.text('WEEK 1 COMPLETE'), findsOneWidget);
      expect(find.text('Rest in the vine.'), findsOneWidget);
      expect(find.text('Begin Week 2'), findsOneWidget);
    });

    testWidgets('nav pill switches between Today, Community and Altar', (tester) async {
      await pumpWith(tester, MainAppShell(examenController: ExamenController()));
      await tester.tap(find.byKey(const Key('nav_tab_community')));
      await tester.pumpAndSettle();
      expect(find.text('Sacred spaces'), findsOneWidget);
      await tester.tap(find.byKey(const Key('nav_tab_altar')));
      await tester.pumpAndSettle();
      expect(find.text('Your rhythm, kept gently.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('nav_tab_today')));
      await tester.pumpAndSettle();
      expect(find.text('This week’s rhythm'), findsOneWidget);
    });
  });

  group('Practices', () {
    testWidgets('Encounter: story → recite by typing → result completes Day 1', (tester) async {
      final bloc = await pumpWith(tester, EncounterScreen(drop: _drop));
      expect(find.text('DAY 1 · ENCOUNTER'), findsOneWidget);
      expect(find.text('The night before the cross,'), findsOneWidget);

      await tester.tap(find.text('Skip to recitation'));
      await tester.pumpAndSettle();
      expect(find.text('Full text'), findsOneWidget);
      expect(find.text('From memory'), findsOneWidget);

      await tester.tap(find.text('Type it instead'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), _drop.verseText.replaceFirst('abides', 'abide'));
      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();

      expect(find.text('Spoken by heart'), findsOneWidget);
      expect(find.textContaining('One small slip'), findsOneWidget);
      expect(find.text('Complete Day 1'), findsOneWidget);
      expect(bloc.state.dayCompletionStatus[1], isTrue);
    });

    testWidgets('Roots: three readings, Complete Day 2', (tester) async {
      final bloc = await pumpWith(tester, RootsScreen(drop: _drop));
      expect(find.text('ampelos'), findsOneWidget);
      expect(find.text('1/3'), findsOneWidget);
      await tester.tap(find.text('Next reading'));
      await tester.pumpAndSettle();
      expect(find.text('Abiding'), findsOneWidget);
      await tester.tap(find.text('Next reading'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Complete Day 2'));
      await tester.pumpAndSettle();
      expect(bloc.state.dayCompletionStatus[2], isTrue);
    });

    testWidgets('Stillness: breath phases, soundscape presets and stem mixer', (tester) async {
      await pumpWith(tester, StillnessScreen(drop: _drop, seconds: 8));
      expect(find.text('Ready'), findsOneWidget);
      expect(find.text('“Abide in me, and I in you.”'), findsOneWidget);
      expect(find.text('Cloister Rain'), findsOneWidget);

      await tester.tap(find.text('Begin · 8s'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Breathe in'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      expect(find.text('Hold'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('Be still'), findsOneWidget);
      expect(find.text('Complete Day 3'), findsOneWidget);

      await tester.tap(find.text('Mix stems'));
      await tester.pumpAndSettle();
      expect(find.text('Soundscape'), findsOneWidget);
      expect(find.text('Master intensity'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('Exchange: empty burden is refused; laid down → received → recap', (tester) async {
      final repo = _Repo();
      final bloc = await pumpWith(tester, ExchangeScreen(drop: _drop), repo: repo);
      expect(find.text('What are you carrying today?'), findsOneWidget);

      // Screen-reader activation of "Lay it down" with nothing written.
      tester.semantics.tap(find.semantics.byLabel('Lay it down'));
      await tester.pump();
      expect(find.textContaining('First write what you’re carrying'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'The deadline I cannot control.');
      tester.semantics.tap(find.semantics.byLabel('Lay it down'));
      await tester.pumpAndSettle();
      expect(find.text('LAID DOWN. RECEIVED INSTEAD'), findsOneWidget);

      await tester.tap(find.text('Keep tear sheet · Complete Day 4'));
      await tester.pumpAndSettle();
      expect(find.byType(RecapScreen), findsOneWidget);
      expect(find.text('Rest in the vine.'), findsOneWidget);
      expect(bloc.state.savedTearSheets.single.burdenText, 'The deadline I cannot control.');
    }, semanticsEnabled: true);
  });

  group('Altar & evening', () {
    testWidgets('Altar shows streak, grace, vine, tear sheets and settings', (tester) async {
      final sheet = TearSheetData(
        id: 't1',
        dropId: _drop.id,
        verseText: _drop.verseText,
        reference: _drop.reference,
        burdenHash: 'h',
        burdenText: 'The deadline I cannot control.',
        completedAt: DateTime(2026, 11, 8),
      );
      await pumpWith(tester, AltarScreen(examenController: ExamenController()), repo: _Repo(sheets: [sheet]));
      expect(find.text('Altar'), findsOneWidget);
      expect(find.text('day streak'), findsOneWidget);
      expect(find.text('Grace tokens'), findsOneWidget);
      expect(find.text('Your vine'), findsOneWidget);
      expect(find.text('Tear sheets'), findsOneWidget);
      expect(find.text('The deadline I cannot control.'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('About & privacy'), 200, scrollable: find.byType(Scrollable).first);
      expect(find.text('Liturgical chimes'), findsOneWidget);
      expect(find.text('Account & export'), findsOneWidget);
      expect(find.textContaining('APNS'), findsNothing);
    });

    testWidgets('30-day check-in on a laid-down burden', (tester) async {
      final sheet = TearSheetData(
        id: 't1',
        dropId: _drop.id,
        verseText: _drop.verseText,
        reference: _drop.reference,
        burdenHash: 'h',
        burdenText: 'The deadline I can’t control.',
        completedAt: DateTime.now().subtract(const Duration(days: 31)),
      );
      final repo = _Repo(sheets: [sheet]);
      final bloc = await pumpWith(tester, MainAppShell(examenController: ExamenController()), repo: repo);
      expect(find.text('31 DAYS AGO YOU LAID THIS DOWN'), findsOneWidget);
      await tester.tap(find.text('Lighter'));
      await tester.pumpAndSettle();
      expect(bloc.state.savedTearSheets.single.checkIn, 'lighter');
      expect(find.text('31 DAYS AGO YOU LAID THIS DOWN'), findsNothing);
    });

    test('Examen is offered in the evening until kept, and saved for that evening', () async {
      final store = ExamenStore.instance;
      await store.load();
      await store.setEveningsEnabled(true);
      final night = DateTime(2026, 11, 9, 21);
      expect(store.shouldOffer(night), isTrue);
      expect(store.shouldOffer(DateTime(2026, 11, 9, 15)), isFalse);
      await store.save(['a', 'b', 'c'], now: DateTime(2026, 11, 10, 0, 30)); // after midnight
      expect(store.shouldOffer(night), isFalse, reason: 'kept for the evening of Nov 9');
    });
  });

  group('Community', () {
    testWidgets('v1 shows The Well, Prayer Circles and the Valley only', (tester) async {
      await pumpWith(tester, const CommunityScreen());
      expect(find.text('The Well'), findsOneWidget);
      expect(find.text('Prayer Circles'), findsOneWidget);
      expect(find.text('In the Valley'), findsOneWidget);
      expect(find.text('Study Pods'), findsNothing);
      expect(find.text('Voice Comfort'), findsNothing);
      expect(find.text('Milestones'), findsNothing);
    });

    testWidgets('admin flags reveal hidden rooms', (tester) async {
      AppFlags.instance.setForTest({AppFlags.roomStudyPods: true, AppFlags.roomVoiceComfort: true});
      await pumpWith(tester, const CommunityScreen());
      expect(find.text('Study Pods'), findsOneWidget);
      expect(find.text('Voice Comfort'), findsOneWidget);
    });

    testWidgets('The Well is honest and shows crisis help', (tester) async {
      await pumpWith(tester, const TheWellScreen());
      expect(find.text('Bring to The Well'), findsOneWidget);
      expect(find.textContaining('4 hours'), findsNothing);
      expect(find.textContaining('If you’re in danger right now', findRichText: true), findsOneWidget);
    });
  });

  test('slip detection marks missed and misspoken words', () {
    const v = 'I am the vine; you are the branches.';
    expect(ScriptureVerifier.slipWordIndices(v, 'I am the vine you are the branches'), isEmpty);
    expect(ScriptureVerifier.slipWordIndices(v, 'I am the vines you are branches'), [3, 6]);
  });
}
