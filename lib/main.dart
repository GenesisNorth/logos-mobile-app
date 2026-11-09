import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/config/app_flags.dart';
import 'core/design/organic.dart';
import 'core/services/notification_service.dart';
import 'core/services/supabase_service.dart';
import 'core/services/glance_service.dart';
import 'core/services/verse_reader.dart';
import 'features/altar/screens/altar_screen.dart';
import 'features/community/screens/community_screen.dart';
import 'features/examen/controllers/examen_controller.dart';
import 'features/examen/examen_store.dart';
import 'features/journey/bloc/journey_bloc.dart';
import 'features/journey/bloc/journey_event.dart';
import 'features/journey/bloc/journey_state.dart';
import 'features/journey/data/supabase_progress_repository.dart';
import 'features/onboarding/screens/covenant_screen.dart';
import 'features/today/today_screen.dart';
import 'features/today/widgets/today_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Fonts ship in assets/google_fonts/ (tool/fetch_fonts.py): no network needed.
  GoogleFonts.config.allowRuntimeFetching = false;
  LicenseRegistry.addLicense(() async* {
    for (final family in ['caprasimo', 'figtree']) {
      final text = await rootBundle.loadString('assets/google_fonts/OFL-$family.txt');
      yield LicenseEntryWithLineBreaks(['google_fonts'], text);
    }
  });
  await SupabaseService.instance.initialize();
  await Future.wait([
    NotificationService.instance.initialize(),
    AppFlags.instance.load(),
    VerseReader.instance.loadPreferences(),
    ExamenStore.instance.load(),
    GlanceService.instance.init(),
  ]);
  runApp(const LogosApp());
}

/// Debug builds only (`--dart-define=DEBUG_SEED=resting`): sign in and finish
/// today's step so the "opens at midnight" widgets and Live Activity can be
/// reviewed on a simulator. Compiled out of release builds.
const _debugSeed = String.fromEnvironment('DEBUG_SEED');

void _applyDebugSeed(JourneyBloc bloc) {
  if (!kDebugMode || _debugSeed != 'resting') return;
  Future<void>.delayed(const Duration(seconds: 2), () {
    if (!bloc.state.profile.hasSignedCovenant) bloc.add(const SignCovenant('Pilgrim'));
    if (bloc.state.dayCompletionStatus[1] != true) {
      bloc.add(const CompleteDayRecitation(dayNumber: 1, score: 0.96));
    }
  });
}

class LogosApp extends StatefulWidget {
  const LogosApp({super.key});

  @override
  State<LogosApp> createState() => _LogosAppState();
}

class _LogosAppState extends State<LogosApp> {
  final ExamenController _examenController = ExamenController();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final bloc = JourneyBloc(progressRepo: SupabaseProgressRepository())..add(const LoadJourneyProgress());
        _applyDebugSeed(bloc);
        return bloc;
      },
      child: MaterialApp(
        title: 'LOGOS IN ME',
        debugShowCheckedModeBanner: false,
        theme: organicTheme(),
        home: MainAppShell(examenController: _examenController),
      ),
    );
  }
}

/// Three places — Today, Community, Altar — behind one floating pill.
/// Practices open full-screen on top.
class MainAppShell extends StatefulWidget {
  final ExamenController examenController;
  const MainAppShell({super.key, required this.examenController});

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> with WidgetsBindingObserver {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Widgets and the Live Activity follow the journey; refresh on resume so
  /// countdowns and "today" stay true after midnight.
  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed || s == AppLifecycleState.paused) {
      GlanceService.instance.sync(context.read<JourneyBloc>().state, force: s == AppLifecycleState.resumed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<JourneyBloc, JourneyState>(
      listener: (context, state) => GlanceService.instance.sync(state),
      buildWhen: (a, b) => a.isLoading != b.isLoading || a.profile.hasSignedCovenant != b.profile.hasSignedCovenant,
      builder: (context, state) {
        if (state.isLoading) {
          return const Scaffold(
            backgroundColor: OC.bg,
            body: Center(child: CircularProgressIndicator(color: OC.accent)),
          );
        }
        if (!state.profile.hasSignedCovenant) {
          return CovenantScreen(onCompleted: () => setState(() => _tab = 0));
        }
        return Scaffold(
          backgroundColor: OC.bg,
          body: Stack(
            children: [
              IndexedStack(
                index: _tab,
                children: [
                  const TodayScreen(),
                  const CommunityScreen(),
                  AltarScreen(examenController: widget.examenController),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Center(child: NavPill(index: _tab, onSelect: (i) => setState(() => _tab = i))),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
