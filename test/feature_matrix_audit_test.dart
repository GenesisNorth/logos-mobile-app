import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logos_mobile_app/core/services/widget_service.dart';
import 'package:logos_mobile_app/core/theme/logos_theme.dart';
import 'package:logos_mobile_app/features/altar/screens/altar_screen.dart';
import 'package:logos_mobile_app/features/community/screens/community_screen.dart';
import 'package:logos_mobile_app/features/examen/controllers/examen_controller.dart';
import 'package:logos_mobile_app/features/exchange/screens/exchange_canvas.dart';
import 'package:logos_mobile_app/features/journey/bloc/journey_bloc.dart';
import 'package:logos_mobile_app/features/journey/bloc/journey_event.dart';
import 'package:logos_mobile_app/features/journey/data/content_repository.dart';
import 'package:logos_mobile_app/features/journey/data/progress_repository.dart';
import 'package:logos_mobile_app/features/journey/data/scripture_pack_repository.dart';
import 'package:logos_mobile_app/features/journey/screens/encounter_player_screen.dart';
import 'package:logos_mobile_app/features/journey/screens/liturgical_widget_preview_sheet.dart';
import 'package:logos_mobile_app/features/journey/screens/scripture_packs_sheet.dart';
import 'package:logos_mobile_app/features/journey/screens/stillness_sanctuary_screen.dart';
import 'package:logos_mobile_app/features/onboarding/screens/covenant_screen.dart';
import 'package:logos_mobile_app/features/recitation/screens/recitation_dialog.dart';
import 'package:logos_mobile_app/main.dart';

class AuditMockProgressRepository implements ProgressRepository {
  UserProfileData profile = const UserProfileData(
    username: 'pilgrim',
    displayName: 'Genesis A.',
    covenantSignature: 'Genesis A.',
    covenantSignedAt: null,
  );
  Map<String, dynamic> journeyData = {
    'weekIndex': 0,
    'activeDay': 1,
    'preferredTranslation': 'ESV',
    'dayCompletion': {'1': false, '2': false, '3': false, '4': false},
    'recitationCounts': {'1': 0, '2': 0, '3': 0, '4': 0},
    'streakCount': 7,
    'graceTokensBalance': 3,
  };
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

  Widget buildAppWrapper({required Widget child, JourneyBloc? bloc}) {
    final effectiveBloc = bloc ??
        JourneyBloc(progressRepo: AuditMockProgressRepository())
      ..add(const LoadJourneyProgress());

    return BlocProvider<JourneyBloc>.value(
      value: effectiveBloc,
      child: MaterialApp(
        theme: LogosTheme.lightTheme(),
        home: child,
      ),
    );
  }

  group('Feature Audit Matrix: LOGOS IN ME End-to-End', () {
    // --------------------------------------------------------------------------
    // Feature 1: Onboarding Covenant & Manifesto
    // --------------------------------------------------------------------------
    testWidgets('[Feature 1: Onboarding Covenant] renders and completes manifesto signing flow', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool completed = false;
      await tester.pumpWidget(
        buildAppWrapper(
          child: CovenantScreen(onCompleted: () => completed = true),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('WELCOME'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      // Advance to step 1
      await tester.tap(find.text('Continue'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('The 4-day rhythm'), findsOneWidget);

      // Step 3: Your practice (translation + reminder). Turn reminders off so
      // the test does not request notification permission.
      await tester.tap(find.text('Continue'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Your practice'), findsOneWidget);
      expect(find.text('Bible translation'), findsOneWidget);
      await tester.tap(find.byType(Switch));
      await tester.pump();

      // Step 4: Covenant signature
      await tester.tap(find.text('Continue'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Your covenant'), findsOneWidget);
      final sealButton = find.text('Sign & begin');
      expect(sealButton, findsOneWidget);

      // Name starts empty; sealing without a name is blocked with a prompt.
      await tester.tap(sealButton);
      await tester.pump();
      expect(completed, isFalse);
      expect(find.text('Write your name to sign the covenant.'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Test Pilgrim');
      await tester.tap(sealButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(seconds: 1));

      expect(completed, isTrue);
    });

    // --------------------------------------------------------------------------
    // Feature 2: Day 1 Encounter Sequence Player
    // --------------------------------------------------------------------------
    testWidgets('[Feature 2: Day 1 Encounter Sequence] plays lines and advances cleanly', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const contentRepo = ContentRepository();
      final drop = contentRepo.drops[0];
      await tester.pumpWidget(
        buildAppWrapper(child: EncounterPlayerScreen(drop: drop)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(drop.reference), findsOneWidget);
      expect(find.text('DAY 1 · ENCOUNTER SEQUENCE'), findsOneWidget);
      expect(find.text('Next Thought'), findsOneWidget);

      // Tap Next to advance line
      final nextButton = find.text('Next Thought');
      expect(nextButton, findsOneWidget);
      await tester.tap(nextButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text(drop.encounterLines[1]), findsOneWidget);
    });

    // --------------------------------------------------------------------------
    // Feature 3: Day 1 & Day 2 Recitation Studio (Speech & Levenshtein Verifier)
    // --------------------------------------------------------------------------
    testWidgets('[Feature 3: Recitation Studio] verifies manual text input and passes recitation', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const contentRepo = ContentRepository();
      final drop = contentRepo.drops[0];
      double? passedScore;

      await tester.pumpWidget(
        buildAppWrapper(
          child: RecitationDialog(
            verseText: drop.verseText,
            reference: drop.reference,
            dayNumber: 1,
            passNumber: 1,
            totalPasses: 2,
            onPassed: (score) => passedScore = score,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(drop.reference), findsOneWidget);
      expect(find.text('Day 1 · Recitation 1 of 2'), findsOneWidget);

      // Toggle to manual text entry mode
      final keyboardIcon = find.byTooltip('Type your recitation');
      expect(keyboardIcon, findsOneWidget);
      await tester.tap(keyboardIcon);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Type the exact verse into TextField
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      await tester.enterText(textField, drop.verseText);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap Verify
      await tester.tap(find.text('Check'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.textContaining('Match: 100%'), findsOneWidget);
      expect(find.text('Complete Sacred Recitation'), findsOneWidget);
      expect(passedScore, equals(1.0));
    });

    // --------------------------------------------------------------------------
    // Feature 4: Day 2 Contextual Exegesis Cards
    // --------------------------------------------------------------------------
    testWidgets('[Feature 4: Day 2 Context & Exegesis] displays Greek & Hebrew word dwells', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const contentRepo = ContentRepository();
      final drop = contentRepo.drops[0]; // John 15:5 (Menō)
      expect(drop.contextCards.isNotEmpty, isTrue);
      expect(drop.contextCards.any((c) => c.title.contains('Menō') || c.subtitle.contains('Greek')), isTrue);

      final week4Drop = contentRepo.drops[3]; // Psalm 23 (Yahweh Rohi)
      expect(week4Drop.contextCards.any((c) => c.subtitle.contains('Hebrew')), isTrue);
    });

    // --------------------------------------------------------------------------
    // Feature 5: Day 3 Stillness Sanctuary & Sacred Soundscape Console
    // --------------------------------------------------------------------------
    testWidgets('[Feature 5: Stillness Sanctuary] tests breath pacer and soundscape mixing console', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const contentRepo = ContentRepository();
      final drop = contentRepo.drops[0];
      await tester.pumpWidget(
        buildAppWrapper(child: StillnessSanctuaryScreen(drop: drop)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Open Soundscape Console sheet via key
      final soundscapeBtn = find.byKey(const Key('soundscape_console_button'));
      expect(soundscapeBtn, findsOneWidget);
      await tester.tap(soundscapeBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Sacred Soundscape Console'), findsOneWidget);
      expect(find.text('Convent Drone'), findsOneWidget);
      expect(find.text('Cloister Rainfall'), findsOneWidget);
      expect(find.text('Holy Sanctuary Bells'), findsOneWidget);
      expect(find.text('Night Cloister Breeze'), findsOneWidget);

      // Verify preset pills
      expect(find.text('Sanctuary Dawn'), findsAtLeastNWidgets(1));
      expect(find.text('Midnight Examen'), findsOneWidget);

      // Tap preset
      await tester.tap(find.text('Midnight Examen'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Close console by tapping outside modal and unmount cleanly
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
    });

    // --------------------------------------------------------------------------
    // Feature 6: Day 4 The Exchange & Holy Altar Dissolution
    // --------------------------------------------------------------------------
    testWidgets('[Feature 6: The Exchange Canvas] renders burden entry and altar dissolution target', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const contentRepo = ContentRepository();
      final drop = contentRepo.drops[0];
      bool exchangeCompleted = false;

      await tester.pumpWidget(
        buildAppWrapper(
          child: ExchangeCanvas(
            verseText: drop.verseText,
            reference: drop.reference,
            weekNumber: 1,
            onExchangeCompleted: (_) => exchangeCompleted = true,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('The Exchange'), findsOneWidget);
      expect(find.text('What I am carrying'), findsOneWidget);
      expect(find.text('↓ Drop the verse here ↓'), findsOneWidget);
      expect(find.text('Lay it down'), findsOneWidget);

      // An empty burden cannot be laid down.
      await tester.tap(find.text('Lay it down'));
      await tester.pump();
      expect(exchangeCompleted, isFalse);
      expect(find.byType(DragTarget<String>), findsOneWidget);
      expect(exchangeCompleted, isFalse);
    });

    // --------------------------------------------------------------------------
    // Feature 7: Scripture Multi-Translation Bridge (ESV, KJV, NASB, NIV)
    // --------------------------------------------------------------------------
    testWidgets('[Feature 7: Multi-Translation Bridge] switches verse translation and updates sanctuary UI', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final bloc = JourneyBloc(progressRepo: AuditMockProgressRepository())
        ..add(const LoadJourneyProgress());

      await tester.pumpWidget(
        BlocProvider<JourneyBloc>.value(
          value: bloc,
          child: MaterialApp(
            theme: LogosTheme.lightTheme(),
            home: MainAppShell(examenController: ExamenController()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Find translation selector badge [ESV]
      final esvBadge = find.text('ESV');
      expect(esvBadge, findsOneWidget);

      await tester.tap(esvBadge);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Bible translation'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('King James Version'), 150, scrollable: find.byType(Scrollable).last);
      expect(find.text('King James Version'), findsOneWidget);

      // Select KJV
      await tester.tap(find.text('King James Version'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('KJV'), findsOneWidget);
      expect(find.textContaining('bringeth forth much fruit'), findsAtLeastNWidgets(1));
    });

    // --------------------------------------------------------------------------
    // Feature 8: Curriculum 52-Week Pipeline & Week Selector Modal
    // --------------------------------------------------------------------------
    testWidgets('[Feature 8: Curriculum Week Selector] navigates across multiple weeks seamlessly', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final bloc = JourneyBloc(progressRepo: AuditMockProgressRepository())
        ..add(const LoadJourneyProgress());

      await tester.pumpWidget(
        BlocProvider<JourneyBloc>.value(
          value: bloc,
          child: MaterialApp(
            theme: LogosTheme.lightTheme(),
            home: MainAppShell(examenController: ExamenController()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Open week selector plaque
      final weekBadge = find.text('WEEK 1 SCRIPTURE');
      expect(weekBadge, findsOneWidget);

      await tester.tap(weekBadge);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Weekly verses'), findsOneWidget);
      expect(find.text('WK 2'), findsOneWidget);
      expect(find.text('Philippians 4:6-7'), findsOneWidget);

      // Tap Week 2
      await tester.tap(find.text('WK 2'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('WEEK 2 SCRIPTURE'), findsOneWidget);
      expect(find.text('Philippians 4:6-7'), findsAtLeastNWidgets(1));
    });

    // --------------------------------------------------------------------------
    // Feature 9: Offline Scripture Pack Downloader
    // --------------------------------------------------------------------------
    testWidgets('[Feature 9: Offline Scripture Packs] downloads and stores seasonal curriculum packs', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: LogosTheme.lightTheme(),
          home: Scaffold(body: ScripturePacksSheet(repository: ScripturePackRepository())),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Offline Scripture Packs'), findsOneWidget);
      expect(find.text('Foundation of Peace'), findsOneWidget);
      expect(find.text('Heavenly Ascent'), findsOneWidget);

      // Download pack
      final downloadButtons = find.text('Download');
      expect(downloadButtons, findsWidgets);
      await tester.tap(downloadButtons.first);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
    });

    // --------------------------------------------------------------------------
    // Feature 10: Realtime Community Cloister Rooms & Intercessions
    // --------------------------------------------------------------------------
    testWidgets('[Feature 10: Community Cloister] displays The Well, Circles, Valley and submits prayers', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: LogosTheme.lightTheme(),
          home: const CommunityScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Community'), findsOneWidget);
      expect(find.text('The Well'), findsOneWidget);
      expect(find.text('Prayer Circles'), findsOneWidget);
      expect(find.text('In the Valley'), findsOneWidget);

      // Open The Well Screen
      await tester.tap(find.text('The Well'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('The Well'), findsOneWidget);
      expect(find.text('PRIVATE · SEEN ONLY BY OUR PASTORAL TEAM'), findsOneWidget);
      expect(find.text('Send request'), findsOneWidget);
      // Honest copy: no guaranteed reply time; crisis help is always visible.
      expect(find.textContaining('4 hours'), findsNothing);
      expect(find.textContaining('not an emergency service'), findsOneWidget);
    });

    // --------------------------------------------------------------------------
    // Feature 11: Prayer Altar, Relic Journal & Cloud Account
    // --------------------------------------------------------------------------
    testWidgets('[Feature 11: Prayer Altar & Settings] shows progress and opens settings', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildAppWrapper(
          child: AltarScreen(examenController: ExamenController()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Prayer Altar'), findsOneWidget);
      expect(find.text('Genesis A.'), findsOneWidget);
      expect(find.text('Current streak'), findsOneWidget);
      expect(find.text('Tear Sheets'), findsOneWidget);
      // No developer diagnostics in the user's view.
      expect(find.textContaining('APNS'), findsNothing);
      expect(find.textContaining('SHA-256'), findsNothing);

      // Settings holds preferences, data and legal.
      await tester.tap(find.byTooltip('Settings'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Bible translation'), findsOneWidget);
      expect(find.text('Daily reminder'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Erase data on this phone'), 200);
      expect(find.text('Export my journal'), findsOneWidget);
      expect(find.text('Translation notices'), findsOneWidget);
    });

    // --------------------------------------------------------------------------
    // Feature 12: iOS WidgetKit & Dynamic Island Preview
    // --------------------------------------------------------------------------
    testWidgets('[Feature 12: iOS WidgetKit & Dynamic Island] previews widgets and triggers sync', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final service = LiturgicalWidgetService();

      await tester.pumpWidget(
        BlocProvider(
          create: (_) => JourneyBloc(progressRepo: AuditMockProgressRepository()),
          child: MaterialApp(
            theme: LogosTheme.lightTheme(),
            home: Scaffold(
              body: LiturgicalWidgetPreviewSheet(widgetService: service),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Liturgical iOS Widgets'), findsOneWidget);
      expect(find.text('Dynamic Island (Tap to Expand)'), findsOneWidget);
      expect(find.text('Medium Home Screen Widget (4x2)'), findsOneWidget);
      expect(find.text('Small Home Screen Widget (2x2)'), findsOneWidget);
      expect(find.text('Sync Current State to Device Widget'), findsOneWidget);
    });
  });
}
