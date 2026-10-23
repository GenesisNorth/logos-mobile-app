import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
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
import 'features/journey/screens/encounter_player_screen.dart';
import 'features/journey/screens/stillness_sanctuary_screen.dart';
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

    return BlocBuilder<JourneyBloc, JourneyState>(
      builder: (context, state) {
        if (state.isLoading) {
          return Scaffold(
            backgroundColor: isDark ? LogosColors.examenBg : LogosColors.sand,
            body: const Center(
              child: CircularProgressIndicator(color: LogosColors.coral),
            ),
          );
        }

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
          extendBody: true,
          body: IndexedStack(
            index: _currentTabIndex,
            children: pages,
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0, left: 24.0, right: 24.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    height: 64,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xDD1F1B17)
                          : const Color(0xEEFFFDF9),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: isDark
                            ? const Color(0x33FFFFFF)
                            : const Color(0x40E29578),
                        width: 1,
                      ),
                      boxShadow: LogosColors.floatingDockShadow,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildFloatingTab(
                          index: 0,
                          label: 'Sanctuary',
                          icon: Icons.spa_outlined,
                          activeIcon: Icons.spa_rounded,
                          isDark: isDark,
                        ),
                        _buildFloatingTab(
                          index: 1,
                          label: 'Community',
                          icon: Icons.forum_outlined,
                          activeIcon: Icons.forum_rounded,
                          isDark: isDark,
                        ),
                        _buildFloatingTab(
                          index: 2,
                          label: 'Altar',
                          icon: Icons.shield_outlined,
                          activeIcon: Icons.shield_rounded,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingTab({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
    required bool isDark,
  }) {
    final isSelected = _currentTabIndex == index;
    final ink = isDark ? LogosColors.examenInk : LogosColors.ink;

    return GestureDetector(
      onTap: () {
        AudioService().selectionTick();
        setState(() => _currentTabIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 18 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? LogosColors.coral.withValues(alpha: isDark ? 0.28 : 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 20,
              color: isSelected ? LogosColors.coral : ink.withValues(alpha: 0.5),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? LogosColors.coral : ink,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SanctuaryHomeScreen extends StatefulWidget {
  final ExamenController examenController;
  const SanctuaryHomeScreen({super.key, required this.examenController});

  @override
  State<SanctuaryHomeScreen> createState() => _SanctuaryHomeScreenState();
}

class _SanctuaryHomeScreenState extends State<SanctuaryHomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedDay = 1;

  // Day 3 Stillness state
  bool _isStillnessPlaying = false;
  int _stillnessSecondsElapsed = 0;
  Timer? _stillnessTimer;

  // Audio preview on plaque
  bool _isPlayingPlaqueChime = false;

  @override
  void dispose() {
    _stillnessTimer?.cancel();
    super.dispose();
  }

  String _getLiturgicalHour() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Morning Matins · Dawn Light';
    if (hour >= 12 && hour < 17) return 'Noonday Sext · Midday Rest';
    if (hour >= 17 && hour < 20) return 'Vespers · Golden Hour';
    return 'Compline · Sacred Quiet';
  }

  IconData _getLiturgicalIcon() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return Icons.wb_twilight_rounded;
    if (hour >= 12 && hour < 17) return Icons.wb_sunny_rounded;
    if (hour >= 17 && hour < 20) return Icons.wb_shade_rounded;
    return Icons.nightlight_round;
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
          context.read<JourneyBloc>().add(const CompleteDayStillness(3));
        }
      });
    }
  }

  void _playPlaqueChime() async {
    setState(() => _isPlayingPlaqueChime = true);
    await AudioService().playSanctuaryChime();
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _isPlayingPlaqueChime = false);
    }
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
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Liturgical App Bar
              SliverAppBar(
                floating: true,
                pinned: true,
                backgroundColor: surface.withValues(alpha: 0.95),
                elevation: 0,
                title: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFE29578), Color(0xFFD4AF37)],
                        ),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LOGOS IN ME',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.8,
                            color: ink,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(_getLiturgicalIcon(), size: 11, color: LogosColors.coral),
                            const SizedBox(width: 4),
                            Text(
                              _getLiturgicalHour(),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: LogosColors.coral,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    tooltip: 'Toggle Examen Contemplation Mode',
                    icon: Icon(
                      widget.examenController.isExamenMode
                          ? Icons.wb_sunny_rounded
                          : Icons.bedtime_rounded,
                      color: LogosColors.coral,
                    ),
                    onPressed: () {
                      AudioService().selectionTick();
                      widget.examenController.toggleExamenPreview();
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ),

              // Sanctuary Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 14),

                      // Metrics & Streak Frosted Pill Bar
                      Row(
                        children: [
                          _buildPill(
                            icon: Icons.local_fire_department_rounded,
                            iconColor: LogosColors.coral,
                            label: '${state.currentStreak} Day Streak',
                            surface: surface,
                            ink: ink,
                          ),
                          const SizedBox(width: 8),
                          _buildPill(
                            icon: Icons.eco_rounded,
                            iconColor: const Color(0xFF10B981),
                            label: '${state.rootsPlanted} Roots',
                            surface: surface,
                            ink: ink,
                          ),
                          const Spacer(),
                          _buildPill(
                            icon: Icons.shield_rounded,
                            iconColor: const Color(0xFFD4AF37),
                            label: '${state.graceTokensBalance} Grace',
                            surface: surface,
                            ink: ink,
                          ),
                        ],
                      ),

                      // Examen Evening Card
                      if (widget.examenController.isExamenMode) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF2E2620), Color(0xFF1F1B17)],
                            ),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: LogosColors.coral.withValues(alpha: 0.35),
                            ),
                            boxShadow: LogosColors.softShadow,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.nightlight_round,
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
                              const SizedBox(height: 12),
                              _buildExamenPrompt(
                                '1. Where did you sense the presence of Christ today?',
                              ),
                              _buildExamenPrompt(
                                '2. What heavy weight can you leave at the cross tonight?',
                              ),
                              _buildExamenPrompt(
                                '3. What gratitude fills your heart before sleep?',
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Illuminated Scripture Relic Plaque
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: isDark
                              ? LogosColors.examenParchmentGradient
                              : LogosColors.parchmentGradient,
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: LogosColors.coral.withValues(alpha: 0.35),
                            width: 1.2,
                          ),
                          boxShadow: LogosColors.relicShadow,
                        ),
                        child: Stack(
                          children: [
                            // Ambient quotation watermark
                            Positioned(
                              top: -8,
                              right: 0,
                              child: Text(
                                '“',
                                style: GoogleFonts.sourceSerif4(
                                  fontSize: 84,
                                  fontWeight: FontWeight.w700,
                                  color: LogosColors.coral.withValues(alpha: 0.12),
                                  height: 1,
                                ),
                              ),
                            ),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: LogosColors.coral.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.auto_stories, size: 12, color: LogosColors.coral),
                                          const SizedBox(width: 6),
                                          Text(
                                            'WEEK ${drop.weekNumber} SCRIPTURE',
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 1.4,
                                              color: LogosColors.coral,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: ink.withValues(alpha: 0.06),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        drop.translation,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: ink.withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '“${drop.verseText}”',
                                  style: LogosTypography.scriptureHero(color: ink),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Audio chime preview chip
                                    GestureDetector(
                                      onTap: _playPlaqueChime,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: LogosColors.coral.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: LogosColors.coral.withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              _isPlayingPlaqueChime ? Icons.graphic_eq : Icons.volume_up_rounded,
                                              size: 14,
                                              color: LogosColors.coral,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              _isPlayingPlaqueChime ? 'Sanctuary Bell...' : 'Listen Chime',
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: LogosColors.coral,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          drop.reference,
                                          style: LogosTypography.scriptureCitation(
                                            color: LogosColors.coral,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          constraints: const BoxConstraints(),
                                          padding: EdgeInsets.zero,
                                          icon: Icon(Icons.share_outlined, size: 16, color: ink.withValues(alpha: 0.5)),
                                          onPressed: () {
                                            SharePlus.instance.share(
                                              ShareParams(
                                                text: '“${drop.verseText}” — ${drop.reference} (LOGOS IN ME)',
                                                subject: 'Scripture of the Week',
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 26),

                      // 4-Day Sacred Rhythm Section Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'The 4-Day Sacred Rhythm',
                                style: LogosTypography.sacredHeader(color: ink),
                              ),
                              Text(
                                'Pace-locked: One divine step per day',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: ink.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                          if (state.dayCompletionStatus[4] == true)
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: LogosColors.coral,
                              ),
                              icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                              label: const Text('Next Week', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              onPressed: () {
                                context.read<JourneyBloc>().add(const AdvanceToNextWeek());
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Connected Rhythm Pathway Dock
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: LogosColors.taupe.withValues(alpha: 0.6)),
                          boxShadow: LogosColors.softShadow,
                        ),
                        child: Row(
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
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  margin: EdgeInsets.only(right: day < 4 ? 6 : 0),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? const LinearGradient(
                                            colors: [Color(0xFFE29578), Color(0xFFD4AF37)],
                                          )
                                        : null,
                                    color: isSelected
                                        ? null
                                        : (isUnlocked ? surface : surface.withValues(alpha: 0.35)),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.transparent
                                          : (isUnlocked ? LogosColors.taupe : LogosColors.taupe.withValues(alpha: 0.4)),
                                      width: 1,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFFE29578).withValues(alpha: 0.4),
                                              blurRadius: 10,
                                              offset: const Offset(0, 3),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        isCompleted
                                            ? Icons.check_circle_rounded
                                            : (isUnlocked
                                                ? Icons.radio_button_unchecked_rounded
                                                : Icons.lock_outline_rounded),
                                        size: 16,
                                        color: isSelected
                                            ? Colors.white
                                            : (isUnlocked
                                                ? (isCompleted ? const Color(0xFF10B981) : ink)
                                                : ink.withValues(alpha: 0.3)),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        'Day $day',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: isSelected
                                              ? Colors.white
                                              : (isUnlocked ? ink : ink.withValues(alpha: 0.4)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Active Day Detail Card View
                      _buildDayDetailCard(
                        context: context,
                        day: _selectedDay,
                        drop: drop,
                        state: state,
                        surface: surface,
                        ink: ink,
                        isDark: isDark,
                      ),

                      const SizedBox(height: 100), // clearance for floating dock
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: LogosColors.taupe),
        boxShadow: LogosColors.softShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamenPrompt(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          height: 1.4,
          color: LogosColors.examenInk.withValues(alpha: 0.9),
        ),
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
    required bool isDark,
  }) {
    switch (day) {
      case 1:
        final count = state.dayRecitationCount[1] ?? 0;
        final isPassed = count >= 2;
        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: LogosColors.taupe),
            boxShadow: LogosColors.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'DAY 1 · ENCOUNTER',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                      color: LogosColors.coral,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isPassed
                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                          : LogosColors.coral.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isPassed ? 'Completed ✓' : '$count/2 Recitations',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isPassed ? const Color(0xFF10B981) : LogosColors.coral,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Immerse in the introductory cinematic encounter lines, then complete your first 2 microphone recitation passes.',
                style: LogosTypography.body(color: ink.withValues(alpha: 0.8)),
              ),
              const SizedBox(height: 18),
              // Cinematic Video Watch Button
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EncounterPlayerScreen(drop: drop),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: ink.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: LogosColors.taupe),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: LogosColors.coral.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded, color: LogosColors.coral),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Watch Encounter Sequence',
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: ink),
                            ),
                            Text(
                              'Cinematic visual & audio immersion',
                              style: GoogleFonts.inter(fontSize: 11, color: ink.withValues(alpha: 0.55)),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // Recitation CTA
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPassed ? const Color(0xFF10B981) : LogosColors.coral,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.mic_rounded),
                  label: Text(
                    isPassed
                        ? 'Recitations Complete ($count/2 Passed ✓)'
                        : 'Begin Recitation Ritual ($count/2)',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
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
              ),
            ],
          ),
        );

      case 2:
        final count = state.dayRecitationCount[2] ?? 0;
        final isPassed = count >= 2;
        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: LogosColors.taupe),
            boxShadow: LogosColors.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'DAY 2 · CONTEXT & EXEGESIS',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                      color: LogosColors.coral,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isPassed
                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                          : LogosColors.coral.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isPassed ? 'Completed ✓' : '$count/2 Recitations',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isPassed ? const Color(0xFF10B981) : LogosColors.coral,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Dwell on the theological and historical background of this Scripture, then complete 2 recitations.',
                style: LogosTypography.body(color: ink.withValues(alpha: 0.8)),
              ),
              const SizedBox(height: 16),
              ...drop.contextCards.map((card) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ink.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: LogosColors.taupe.withValues(alpha: 0.7)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: LogosColors.coral.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  card.subtitle,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: LogosColors.coral,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            card.title,
                            style: LogosTypography.sacredHeader(color: ink).copyWith(fontSize: 16),
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
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPassed ? const Color(0xFF10B981) : LogosColors.coral,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.mic_rounded),
                  label: Text(
                    isPassed
                        ? 'Day 2 Complete ($count/2 Passed ✓)'
                        : 'Begin Day 2 Recitation ($count/2)',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
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
              ),
            ],
          ),
        );

      case 3:
        final count = state.dayRecitationCount[3] ?? 0;
        final isStillnessDone = state.dayCompletionStatus[3] == true;

        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF24484D), Color(0xFF173337)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: LogosColors.relicShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'DAY 3 · LOGOS & STILLNESS',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                      color: const Color(0xFFE29578),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isStillnessDone
                          ? const Color(0xFF10B981).withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isStillnessDone ? 'Stillness Sealed ✓' : '60s Required',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isStillnessDone ? const Color(0xFF86EFAC) : Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Full-bleed sanctuary contemplation with 432 Hz ambient soundscapes. Rest your thoughts in Christ for at least 60 seconds.',
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, height: 1.45),
              ),
              const SizedBox(height: 18),
              // Ambient player button
              GestureDetector(
                onTap: () => _toggleStillnessAudio(drop.ambientPreset),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isStillnessPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                        color: const Color(0xFFE29578),
                        size: 30,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              drop.ambientLabel,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              _isStillnessPlaying
                                  ? 'Playing (${_stillnessSecondsElapsed}s / 60s elapsed)'
                                  : 'Tap to start 432 Hz loop',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1E3C40),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: Icon(isStillnessDone ? Icons.check_circle_rounded : Icons.spa_rounded, size: 16),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => StillnessSanctuaryScreen(drop: drop),
                          ),
                        );
                      },
                      label: Text(
                        isStillnessDone ? 'Sanctuary Sealed ✓' : 'Enter Sanctuary',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12.5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    icon: const Icon(Icons.mic, size: 16),
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
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: LogosColors.coral, width: 1.5),
            boxShadow: LogosColors.relicShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'DAY 4 · THE SACRED CLIMAX',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                      color: LogosColors.coral,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: state.isExchangeCompleted
                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                          : const Color(0xFFD4AF37).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      state.isExchangeCompleted ? 'Week Completed ✓' : 'Master Test',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: state.isExchangeCompleted ? const Color(0xFF10B981) : const Color(0xFFD4AF37),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'The sacred climax of the week: pass your master recitation test in Memory Mode (from the heart), then drag the Scripture over your heavy burden to dissolve it into a Tear Sheet.',
                style: LogosTypography.body(color: ink.withValues(alpha: 0.85)),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ink,
                        side: BorderSide(color: hasPassedMaster ? const Color(0xFF10B981) : LogosColors.coral),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: Icon(
                        hasPassedMaster ? Icons.check_circle_rounded : Icons.psychology_rounded,
                        color: hasPassedMaster ? const Color(0xFF10B981) : LogosColors.coral,
                      ),
                      label: Text(
                        hasPassedMaster ? 'Master Test Passed ✓' : '1. Master Recitation',
                        style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600),
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
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.sync_alt_rounded, size: 16),
                      label: Text(
                        state.isExchangeCompleted ? 'Exchange Done ✓' : '2. The Exchange',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
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
