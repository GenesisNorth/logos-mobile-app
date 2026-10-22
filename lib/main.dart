import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/services/audio_service.dart';
import 'core/theme/logos_theme.dart';
import 'core/theme/logos_typography.dart';
import 'features/altar/screens/altar_screen.dart';
import 'features/community/screens/community_screen.dart';
import 'features/examen/controllers/examen_controller.dart';
import 'features/exchange/screens/exchange_canvas.dart';
import 'features/journey/bloc/journey_bloc.dart';
import 'features/journey/bloc/journey_event.dart';
import 'features/journey/bloc/journey_state.dart';
import 'features/journey/models/scripture_drop.dart';
import 'features/onboarding/screens/covenant_screen.dart';
import 'features/recitation/screens/recitation_dialog.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LogosApp());
}

class LogosApp extends StatefulWidget {
  const LogosApp({super.key});

  @override
  State<LogosApp> createState() => _LogosAppState();
}

class _LogosAppState extends State<LogosApp> {
  final ExamenController _examenController = ExamenController();

  @override
  void initState() {
    super.initState();
    _examenController.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => JourneyBloc()..add(const LoadJourneyProgress()),
      child: MaterialApp(
        title: 'LOGOS IN ME',
        debugShowCheckedModeBanner: false,
        theme: LogosTheme.lightTheme(),
        darkTheme: LogosTheme.examenTheme(),
        themeMode: _examenController.isExamenMode
            ? ThemeMode.dark
            : ThemeMode.light,
        home: MainAppShell(examenController: _examenController),
      ),
    );
  }
}

class MainAppShell extends StatefulWidget {
  final ExamenController examenController;
  const MainAppShell({super.key, required this.examenController});

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  int _currentTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? LogosColors.examenSurface : LogosColors.surface;
    final ink = isDark ? LogosColors.examenInk : LogosColors.ink;

    return BlocBuilder<JourneyBloc, JourneyState>(
      builder: (context, state) {
        // If loading initial state
        if (state.isLoading) {
          return Scaffold(
            backgroundColor: isDark ? LogosColors.examenBg : LogosColors.sand,
            body: const Center(
              child: CircularProgressIndicator(color: LogosColors.coral),
            ),
          );
        }

        // If user hasn't signed the covenant yet, present Onboarding & Covenant first
        if (!state.profile.hasSignedCovenant) {
          return CovenantScreen(
            onCompleted: () {
              setState(() {});
            },
          );
        }

        final pages = [
          SanctuaryHomeScreen(examenController: widget.examenController),
          const CommunityScreen(),
          AltarScreen(examenController: widget.examenController),
        ];

        return Scaffold(
          body: IndexedStack(
            index: _currentTabIndex,
            children: pages,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: surface,
              border: Border(
                top: BorderSide(color: LogosColors.taupe.withValues(alpha: 0.5)),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentTabIndex,
              backgroundColor: surface,
              selectedItemColor: LogosColors.coral,
              unselectedItemColor: ink.withValues(alpha: 0.5),
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              onTap: (index) {
                AudioService().selectionTick();
                setState(() => _currentTabIndex = index);
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Sanctuary',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people_outline),
                  activeIcon: Icon(Icons.people),
                  label: 'Community',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.shield_outlined),
                  activeIcon: Icon(Icons.shield),
                  label: 'Altar',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class SanctuaryHomeScreen extends StatefulWidget {
  final ExamenController examenController;
  const SanctuaryHomeScreen({super.key, required this.examenController});

  @override
  State<SanctuaryHomeScreen> createState() => _SanctuaryHomeScreenState();
}

class _SanctuaryHomeScreenState extends State<SanctuaryHomeScreen> {
  int _selectedDay = 1;

  // Day 3 Stillness state
  bool _isStillnessPlaying = false;
  int _stillnessSecondsElapsed = 0;
  Timer? _stillnessTimer;

  @override
  void dispose() {
    _stillnessTimer?.cancel();
    super.dispose();
  }

  void _toggleStillnessAudio(String preset) {
    if (_isStillnessPlaying) {
      AudioService().pauseAmbient();
      _stillnessTimer?.cancel();
      setState(() => _isStillnessPlaying = false);
    } else {
      AudioService().startAmbient(preset);
      setState(() => _isStillnessPlaying = true);
      _stillnessTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() {
          _stillnessSecondsElapsed++;
        });
        if (_stillnessSecondsElapsed >= 60) {
          // 60-second stillness completed
          context.read<JourneyBloc>().add(const CompleteDayStillness(3));
        }
      });
    }
  }

  void _showEncounterSequence(BuildContext context, ScriptureDrop drop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          gradient: LogosColors.sanctuaryGradient,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Day 1: Encounter Sequence',
                  style: LogosTypography.label(color: Colors.white),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Spacer(),
            ...drop.encounterLines.map((line) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    line,
                    textAlign: TextAlign.center,
                    style: LogosTypography.scriptureHero(color: Colors.white).copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                )),
            const Spacer(),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: LogosColors.coral,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Encounter Received',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? LogosColors.examenInk : LogosColors.ink;
    final surface = isDark ? LogosColors.examenSurface : LogosColors.surface;

    return BlocBuilder<JourneyBloc, JourneyState>(
      builder: (context, state) {
        final drop = state.activeDrop;

        return Scaffold(
          backgroundColor: isDark ? LogosColors.examenBg : LogosColors.sand,
          body: CustomScrollView(
            slivers: [
              // Liturgical App Bar
              SliverAppBar(
                floating: true,
                pinned: true,
                backgroundColor: surface,
                elevation: 0,
                title: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: LogosColors.coral,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '✝',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'LOGOS IN ME',
                      style: LogosTypography.label(color: ink),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    tooltip: 'Toggle Examen Contemplation Mode',
                    icon: Icon(
                      widget.examenController.isExamenMode
                          ? Icons.wb_sunny_outlined
                          : Icons.bedtime_outlined,
                      color: LogosColors.coral,
                    ),
                    onPressed: widget.examenController.toggleExamenPreview,
                  ),
                  const SizedBox(width: 8),
                ],
              ),

              // Sanctuary Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),

                      // Metrics & Streak Pill Bar
                      Row(
                        children: [
                          _buildPill(
                            icon: Icons.local_fire_department,
                            iconColor: LogosColors.coral,
                            label: '${state.currentStreak} Day Streak',
                            surface: surface,
                            ink: ink,
                          ),
                          const SizedBox(width: 8),
                          _buildPill(
                            icon: Icons.eco,
                            iconColor: const Color(0xFF10B981),
                            label: '${state.rootsPlanted} Roots',
                            surface: surface,
                            ink: ink,
                          ),
                          const Spacer(),
                          _buildPill(
                            icon: Icons.shield,
                            iconColor: Colors.amber.shade700,
                            label: '${state.graceTokensBalance} Grace',
                            surface: surface,
                            ink: ink,
                          ),
                        ],
                      ),

                      // Examen Evening Card (Surfaced during 8 PM - 5 AM or preview)
                      if (widget.examenController.isExamenMode) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E2620),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: LogosColors.coral.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.nights_stay,
                                    size: 18,
                                    color: LogosColors.coral,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Evening Examen (Contemplation Hour)',
                                    style: LogosTypography.label(
                                      color: LogosColors.coral,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '1. Where did you sense the presence of Christ today?',
                                style: LogosTypography.body(
                                  color: LogosColors.examenInk.withValues(alpha: 0.9),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '2. What heavy weight can you leave at the cross tonight?',
                                style: LogosTypography.body(
                                  color: LogosColors.examenInk.withValues(alpha: 0.9),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '3. What gratitude fills your heart before sleep?',
                                style: LogosTypography.body(
                                  color: LogosColors.examenInk.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 18),

                      // Scripture Plaque
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: LogosColors.taupe),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'WEEK ${drop.weekNumber} SCRIPTURE',
                                  style: LogosTypography.caption(
                                    color: LogosColors.coral,
                                  ).copyWith(letterSpacing: 1.5, fontWeight: FontWeight.bold),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: ink.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    drop.translation,
                                    style: LogosTypography.caption(
                                      color: ink.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              '"${drop.verseText}"',
                              style: LogosTypography.scriptureHero(color: ink),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                drop.reference,
                                style: LogosTypography.scriptureCitation(
                                  color: LogosColors.coral,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 4-Day Journey Step Selector
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'The 4-Day Sacred Rhythm',
                            style: LogosTypography.headline(color: ink),
                          ),
                          if (state.dayCompletionStatus[4] == true)
                            TextButton.icon(
                              icon: const Icon(Icons.arrow_forward, size: 14),
                              label: const Text('Next Week', style: TextStyle(fontSize: 12)),
                              onPressed: () {
                                context.read<JourneyBloc>().add(const AdvanceToNextWeek());
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: List.generate(4, (index) {
                          final day = index + 1;
                          final isSelected = _selectedDay == day;
                          final isCompleted = state.dayCompletionStatus[day] ?? false;
                          final isUnlocked = state.isDayUnlocked(day);
                          final durationUntilUnlock = state.timeUntilUnlock(day);

                          return Expanded(
                            child: GestureDetector(
                              onTap: isUnlocked
                                  ? () {
                                      AudioService().selectionTick();
                                      setState(() => _selectedDay = day);
                                      context.read<JourneyBloc>().add(SelectDay(day));
                                    }
                                  : () {
                                      final hours = durationUntilUnlock != null ? durationUntilUnlock.inHours : 0;
                                      final mins = durationUntilUnlock != null ? (durationUntilUnlock.inMinutes % 60) : 0;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Pace-locked: Day $day unlocks at midnight ($hours hr $mins min remaining). Rest and meditate on today\'s word.',
                                          ),
                                        ),
                                      );
                                    },
                              child: Container(
                                margin: EdgeInsets.only(
                                  right: day < 4 ? 8 : 0,
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? LogosColors.coral
                                      : (isUnlocked
                                          ? surface
                                          : surface.withValues(alpha: 0.4)),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? LogosColors.coral
                                        : LogosColors.taupe,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      isCompleted
                                          ? Icons.check_circle
                                          : (isUnlocked
                                              ? Icons.circle_outlined
                                              : Icons.lock_outline),
                                      size: 16,
                                      color: isSelected
                                          ? Colors.white
                                          : (isUnlocked
                                              ? (isCompleted
                                                  ? Colors.green
                                                  : ink)
                                              : ink.withValues(alpha: 0.3)),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Day $day',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.white
                                            : (isUnlocked
                                                ? ink
                                                : ink.withValues(alpha: 0.4)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 20),

                      // Active Day Card View
                      _buildDayDetailCard(
                        context: context,
                        day: _selectedDay,
                        drop: drop,
                        state: state,
                        surface: surface,
                        ink: ink,
                      ),

                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPill({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Color surface,
    required Color ink,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: LogosColors.taupe),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayDetailCard({
    required BuildContext context,
    required int day,
    required ScriptureDrop drop,
    required JourneyState state,
    required Color surface,
    required Color ink,
  }) {
    switch (day) {
      case 1:
        final count = state.dayRecitationCount[1] ?? 0;
        final isPassed = count >= 2;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: LogosColors.taupe),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Day 1: Encounter',
                style: LogosTypography.label(color: LogosColors.coral),
              ),
              const SizedBox(height: 6),
              Text(
                'Immerse in the introductory cinematic encounter lines, then complete your first 2 microphone recitation passes.',
                style: LogosTypography.body(color: ink.withValues(alpha: 0.8)),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: ink,
                  side: const BorderSide(color: LogosColors.taupe),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.play_circle_outline, size: 20),
                label: const Text('Watch Encounter Sequence'),
                onPressed: () => _showEncounterSequence(context, drop),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: LogosColors.coral,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.mic),
                label: Text(
                  isPassed
                      ? 'Recitations Complete ($count/2 Passed ✓)'
                      : 'Begin Recitation Ritual ($count/2)',
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (_) => RecitationDialog(
                        verseText: drop.verseText,
                        reference: drop.reference,
                        dayNumber: 1,
                        passNumber: count < 2 ? count + 1 : 2,
                        totalPasses: 2,
                        onPassed: (score) {
                          context.read<JourneyBloc>().add(
                                CompleteDayRecitation(
                                  dayNumber: 1,
                                  score: score,
                                ),
                              );
                        },
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );

      case 2:
        final count = state.dayRecitationCount[2] ?? 0;
        final isPassed = count >= 2;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: LogosColors.taupe),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Day 2: Context & Exegesis',
                style: LogosTypography.label(color: LogosColors.coral),
              ),
              const SizedBox(height: 6),
              Text(
                'Dwell on the theological and historical background of this Scripture, then complete 2 recitations.',
                style: LogosTypography.body(color: ink.withValues(alpha: 0.8)),
              ),
              const SizedBox(height: 14),
              ...drop.contextCards.map((card) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: ink.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            card.title,
                            style: LogosTypography.label(color: ink),
                          ),
                          Text(
                            card.subtitle,
                            style: LogosTypography.caption(
                              color: LogosColors.coral,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            card.content,
                            style: LogosTypography.body(
                              color: ink.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: LogosColors.coral,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.mic),
                label: Text(
                  isPassed
                      ? 'Recitations Complete ($count/2 Passed ✓)'
                      : 'Day 2 Recitation ($count/2)',
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (_) => RecitationDialog(
                        verseText: drop.verseText,
                        reference: drop.reference,
                        dayNumber: 2,
                        passNumber: count < 2 ? count + 1 : 2,
                        totalPasses: 2,
                        onPassed: (score) {
                          context.read<JourneyBloc>().add(
                                CompleteDayRecitation(
                                  dayNumber: 2,
                                  score: score,
                                ),
                              );
                        },
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );

      case 3:
        final count = state.dayRecitationCount[3] ?? 0;
        final isStillnessDone = state.dayCompletionStatus[3] == true;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LogosColors.sanctuaryGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Day 3: Logos & Stillness',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Full-bleed sanctuary contemplation with 432 Hz ambient soundscapes. Rest your thoughts in Christ for at least 60 seconds.',
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              // Ambient player pill
              GestureDetector(
                onTap: () => _toggleStillnessAudio(drop.ambientPreset),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isStillnessPlaying ? Icons.pause_circle : Icons.play_circle,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isStillnessPlaying
                            ? '${drop.ambientLabel} (${_stillnessSecondsElapsed}s / 60s)'
                            : 'Play ${drop.ambientLabel}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF2D5A60),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      context.read<JourneyBloc>().add(const CompleteDayStillness(3));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Day 3 Stillness Contemplation Complete ✓')),
                      );
                    },
                    child: Text(
                      isStillnessDone ? 'Stillness Sealed ✓' : 'Mark Stillness Complete',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    icon: const Icon(Icons.mic, size: 18),
                    label: Text('Recite ($count)'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          fullscreenDialog: true,
                          builder: (_) => RecitationDialog(
                            verseText: drop.verseText,
                            reference: drop.reference,
                            dayNumber: 3,
                            passNumber: 1,
                            totalPasses: 1,
                            onPassed: (score) {
                              context.read<JourneyBloc>().add(
                                    CompleteDayRecitation(
                                      dayNumber: 3,
                                      score: score,
                                    ),
                                  );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );

      case 4:
        final count = state.dayRecitationCount[4] ?? 0;
        final hasPassedMaster = count >= 1;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: LogosColors.coral, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Day 4: Master Recitation & The Exchange',
                style: LogosTypography.label(color: LogosColors.coral),
              ),
              const SizedBox(height: 6),
              Text(
                'The sacred climax of the week: pass your master recitation test in Memory Mode (from the heart), then drag the Scripture over your heavy burden to dissolve it into a Tear Sheet.',
                style: LogosTypography.body(color: ink.withValues(alpha: 0.85)),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ink,
                        side: BorderSide(color: hasPassedMaster ? Colors.green : LogosColors.coral),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: Icon(
                        hasPassedMaster ? Icons.check_circle : Icons.psychology,
                        color: hasPassedMaster ? Colors.green : LogosColors.coral,
                      ),
                      label: Text(
                        hasPassedMaster ? 'Master Test Passed ✓' : '1. Master Test (Memory)',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            fullscreenDialog: true,
                            builder: (_) => RecitationDialog(
                              verseText: drop.verseText,
                              reference: drop.reference,
                              dayNumber: 4,
                              passNumber: 1,
                              totalPasses: 1,
                              memoryModeDefault: true,
                              onPassed: (score) {
                                context.read<JourneyBloc>().add(
                                      CompleteDayRecitation(
                                        dayNumber: 4,
                                        score: score,
                                      ),
                                    );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LogosColors.coral,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.sync_alt, size: 16),
                      label: Text(
                        state.isExchangeCompleted ? 'Exchange Done ✓' : '2. The Exchange',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ExchangeCanvas(
                              verseText: drop.verseText,
                              reference: drop.reference,
                              weekNumber: drop.weekNumber,
                              onExchangeCompleted: () {
                                context.read<JourneyBloc>().add(
                                      const CompleteExchange(
                                        burdenSummary: "Dissolved burden into Scripture",
                                      ),
                                    );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}
