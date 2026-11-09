import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'features/journey/screens/translation_picker_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'core/services/audio_service.dart';
import 'core/services/widget_service.dart';
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
import 'core/services/supabase_service.dart';
import 'core/services/notification_service.dart';
import 'features/journey/data/supabase_progress_repository.dart';
import 'features/journey/data/content_repository.dart';
import 'features/journey/screens/scripture_packs_sheet.dart';
import 'core/theme/logos_icons.dart';
import 'core/config/app_flags.dart';
import 'core/services/verse_reader.dart';
import 'features/journey/widgets/today_card.dart';
import 'features/settings/reminder_controls.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Fonts ship in assets/google_fonts/ (tool/fetch_fonts.py): no network needed.
  GoogleFonts.config.allowRuntimeFetching = false;
  LicenseRegistry.addLicense(() async* {
    for (final family in ['inter', 'sourceserif4', 'newsreader', 'caveat']) {
      final text = await rootBundle.loadString('assets/google_fonts/OFL-$family.txt');
      yield LicenseEntryWithLineBreaks(['google_fonts'], text);
    }
  });
  await SupabaseService.instance.initialize();
  await Future.wait([
    NotificationService.instance.initialize(),
    AppFlags.instance.load(),
    VerseReader.instance.loadPreferences(),
  ]);
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
      create: (_) => JourneyBloc(
        progressRepo: SupabaseProgressRepository(),
      )..add(const LoadJourneyProgress()),
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
                          ? const Color(0xDD180F30)
                          : const Color(0xF8FFFFFF),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: isDark
                            ? const Color(0x33A855F7)
                            : const Color(0x247C3AED),
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
                          icon: LogosIcons.spaOutlined,
                          activeIcon: LogosIcons.spaRounded,
                          isDark: isDark,
                        ),
                        _buildFloatingTab(
                          index: 1,
                          label: 'Community',
                          icon: LogosIcons.forumOutlined,
                          activeIcon: LogosIcons.forumRounded,
                          isDark: isDark,
                        ),
                        _buildFloatingTab(
                          index: 2,
                          label: 'Altar',
                          icon: LogosIcons.shieldOutlined,
                          activeIcon: LogosIcons.shieldRounded,
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
    required LogosIconData icon,
    required LogosIconData activeIcon,
    required bool isDark,
  }) {
    final isSelected = _currentTabIndex == index;
    final ink = isDark ? LogosColors.examenInk : LogosColors.ink;

    return GestureDetector(
      key: Key('nav_tab_${label.toLowerCase()}'),
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
              ? LogosColors.coral.withValues(alpha: isDark ? 0.28 : 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(
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
  final GlobalKey _dayCardKey = GlobalKey();

  @override
  void dispose() {
    _stillnessTimer?.cancel();
    super.dispose();
  }

  String _getLiturgicalHour() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) return 'Lauds · Morning';
    if (hour >= 11 && hour < 14) return 'Sext · Midday';
    if (hour >= 14 && hour < 17) return 'None · Afternoon';
    if (hour >= 17 && hour < 20) return 'Vespers · Evening';
    return 'Compline · Night';
  }

  LogosIconData _getLiturgicalIcon() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) return LogosIcons.wbTwilightRounded;
    if (hour >= 11 && hour < 17) return LogosIcons.wbSunnyRounded;
    if (hour >= 17 && hour < 20) return LogosIcons.wbShadeRounded;
    return LogosIcons.nightlightRound;
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

  void _showRemindersSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final ink = isDark ? LogosColors.examenInk : LogosColors.ink;
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
          decoration: BoxDecoration(
            color: isDark ? LogosColors.examenSurface : LogosColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 8),
                  child: Text('Reminders',
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: ink)),
                ),
                ReminderControls(ink: ink),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _openDay(int day) {
    setState(() => _selectedDay = day);
    context.read<JourneyBloc>().add(SelectDay(day));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _dayCardKey.currentContext;
      if (target != null) {
        Scrollable.ensureVisible(target, duration: const Duration(milliseconds: 400), alignment: 0.1);
      }
    });
  }

  void _showWeekSelectorSheet(BuildContext context, JourneyState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? LogosColors.examenSurface : LogosColors.surface;
    final ink = isDark ? LogosColors.examenInk : LogosColors.ink;
    const contentRepo = ContentRepository();
    final allDrops = contentRepo.drops;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 34),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: LogosColors.taupe),
            boxShadow: LogosColors.softShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ink.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: LogosColors.coral.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const AppIcon(
                      LogosIcons.autoStories,
                      color: LogosColors.coral,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Weekly verses',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: ink,
                          ),
                        ),
                        Text(
                          state.canChangeWeek
                              ? 'Choose the verse for this week'
                              : 'Finish this week’s rhythm to change verse',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: ink.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: allDrops.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final drop = allDrops[i];
                    final isCurrent = drop.id == state.activeDrop.id;
                    final selectable = isCurrent || state.canChangeWeek;
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.pop(ctx);
                        if (isCurrent) return;
                        if (!selectable) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('You’re in the middle of this week’s verse. Finish its 4 days to move on.'),
                          ));
                          return;
                        }
                        context.read<JourneyBloc>().add(SelectWeek(i));
                        setState(() => _selectedDay = 1);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? LogosColors.coral.withValues(alpha: 0.08)
                              : ink.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isCurrent ? LogosColors.coral : LogosColors.taupe.withValues(alpha: 0.6),
                            width: isCurrent ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isCurrent ? LogosColors.coral : ink.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'WK ${drop.weekNumber}',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: isCurrent ? Colors.white : ink,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    drop.reference,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: ink,
                                    ),
                                  ),
                                  Text(
                                    drop.contextCards.first.title,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: ink.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isCurrent)
                              const AppIcon(LogosIcons.checkCircleRounded, color: LogosColors.coral, size: 20)
                            else if (selectable)
                              const AppIcon(LogosIcons.chevronRight, size: 16, color: Colors.grey)
                            else
                              AppIcon(LogosIcons.lockOutlineRounded, size: 16, color: ink.withValues(alpha: 0.35)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (state.isExchangeCompleted) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LogosColors.coral,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const AppIcon(LogosIcons.arrowForwardRounded, size: 16),
                    label: Text(
                      'Advance to Week ${state.activeDrop.weekNumber + 1}',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.read<JourneyBloc>().add(const AdvanceToNextWeek());
                      setState(() => _selectedDay = 1);
                    },
                  ),
                ),
              ],
              if (AppFlags.instance.isOn(AppFlags.scripturePacks)) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: LogosColors.coral,
                    side: BorderSide(color: LogosColors.coral.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const AppIcon(LogosIcons.fileDownload, size: 16),
                  label: Text(
                    'Offline Scripture packs',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScripturePacksSheet.show(context);
                  },
                ),
              ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showTranslationSelectorSheet(BuildContext context, JourneyState state) {
    showTranslationPicker(
      context,
      current: state.activeDrop.translation,
      previews: state.activeDrop.translations,
      onSelected: (key) {
        context.read<JourneyBloc>().add(SelectTranslation(key));
        LiturgicalWidgetService().syncWidgetData(
          state: state.copyWith(activeDrop: state.activeDrop.withTranslation(key)),
        );
      },
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
                        gradient: LogosColors.purpleGradient,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const AppIcon(LogosIcons.menuBook, size: 17, color: Colors.white),
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
                            AppIcon(_getLiturgicalIcon(), size: 11, color: LogosColors.coral),
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
                    tooltip: 'Reminders',
                    icon: AppIcon(
                      NotificationService.instance.isEnabled
                          ? LogosIcons.notificationsActive
                          : LogosIcons.notificationsNone,
                      color: LogosColors.coral,
                    ),
                    onPressed: () => _showRemindersSheet(context),
                  ),
                  IconButton(
                    tooltip: 'Evening mode',
                    icon: AppIcon(
                      widget.examenController.isExamenMode
                          ? LogosIcons.wbSunnyRounded
                          : LogosIcons.bedtimeRounded,
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
                            icon: LogosIcons.localFireDepartmentRounded,
                            iconColor: LogosColors.coral,
                            label: '${state.activeStreak()} Day Streak',
                            surface: surface,
                            ink: ink,
                          ),
                          const SizedBox(width: 8),
                          _buildPill(
                            icon: LogosIcons.ecoRounded,
                            iconColor: const Color(0xFF10B981),
                            label: '${state.rootsPlanted} Roots',
                            surface: surface,
                            ink: ink,
                          ),
                          const Spacer(),
                          _buildPill(
                            icon: LogosIcons.shieldRounded,
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
                              colors: [Color(0xFF241445), Color(0xFF160B30)],
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
                                  const AppIcon(
                                    LogosIcons.nightlightRound,
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
                            color: LogosColors.taupe,
                            width: 1.2,
                          ),
                          boxShadow: LogosColors.softShadow,
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
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(10),
                                        onTap: () {
                                          AudioService().selectionTick();
                                          _showWeekSelectorSheet(context, state);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: LogosColors.coral.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: LogosColors.coral.withValues(alpha: 0.3),
                                              width: 0.8,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const AppIcon(LogosIcons.autoStories, size: 12, color: LogosColors.coral),
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
                                              const SizedBox(width: 4),
                                              const AppIcon(
                                                LogosIcons.arrowDropDownRounded,
                                                size: 13,
                                                color: LogosColors.coral,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                                          _showTranslationSelectorSheet(context, state);
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: ink.withValues(alpha: 0.06),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: LogosColors.coral.withValues(alpha: 0.35),
                                              width: 0.8,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                drop.translation,
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: LogosColors.coral,
                                                ),
                                              ),
                                              const SizedBox(width: 3),
                                              const AppIcon(
                                                LogosIcons.arrowDropDownRounded,
                                                size: 13,
                                                color: LogosColors.coral,
                                              ),
                                            ],
                                          ),
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
                                    // Read the verse aloud (device text-to-speech)
                                    ListenableBuilder(
                                      listenable: VerseReader.instance,
                                      builder: (context, _) {
                                        final reading = VerseReader.instance.isReading(drop.verseText);
                                        return Semantics(
                                          button: true,
                                          label: reading ? 'Stop reading' : 'Listen to the verse',
                                          excludeSemantics: true,
                                          child: GestureDetector(
                                            onTap: () async {
                                              if (reading) {
                                                await VerseReader.instance.stop();
                                              } else if (!await VerseReader.instance.speak(drop.verseText, reference: drop.reference) &&
                                                  context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                                  content: Text('No reading voice is available on this phone.'),
                                                ));
                                              }
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: LogosColors.coral.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(color: LogosColors.coral.withValues(alpha: 0.3)),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  AppIcon(
                                                    reading ? LogosIcons.stopRounded : LogosIcons.volumeUpRounded,
                                                    size: 16,
                                                    color: LogosColors.coral,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    reading ? 'Stop' : 'Listen',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w700,
                                                      color: LogosColors.coral,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    Flexible(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              drop.reference,
                                              style: LogosTypography.scriptureCitation(
                                                color: LogosColors.coral,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            tooltip: 'Share verse',
                                            icon: AppIcon(LogosIcons.shareOutlined, size: 18, color: ink.withValues(alpha: 0.6)),
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
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      TodayCard(
                        state: state,
                        onOpenDay: _openDay,
                        onNextWeek: () {
                          context.read<JourneyBloc>().add(const AdvanceToNextWeek());
                          setState(() => _selectedDay = 1);
                        },
                      ),

                      const SizedBox(height: 26),

                      // 4-Day Sacred Rhythm Section Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'The 4-Day Sacred Rhythm',
                                  style: LogosTypography.sacredHeader(color: ink),
                                ),
                                Text(
                                  'One step each day · new steps open at midnight',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: ink.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (state.dayCompletionStatus[4] == true)
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: LogosColors.coral,
                              ),
                              icon: const AppIcon(LogosIcons.arrowForwardRounded, size: 14),
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
                                        final String message;
                                        if (durationUntilUnlock != null) {
                                          final hours = durationUntilUnlock.inHours;
                                          final mins = durationUntilUnlock.inMinutes % 60;
                                          message =
                                              'Pace-locked: Day $day unlocks at midnight ($hours hr $mins min remaining). Rest and meditate on today\'s word.';
                                        } else {
                                          // An earlier day is still unfinished.
                                          final pending = [1, 2, 3].firstWhere(
                                            (d) => d < day && state.dayCompletionStatus[d] != true,
                                            orElse: () => day - 1,
                                          );
                                          message =
                                              'Day $day opens after you complete Day $pending. One step at a time — return to today\'s word.';
                                        }
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(message)),
                                        );
                                      },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  margin: EdgeInsets.only(right: day < 4 ? 6 : 0),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? LogosColors.purpleGradient
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
                                              color: const Color(0xFF7C3AED).withValues(alpha: 0.22),
                                              blurRadius: 10,
                                              offset: const Offset(0, 3),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Column(
                                    children: [
                                      AppIcon(
                                        isCompleted
                                            ? LogosIcons.checkCircleRounded
                                            : (isUnlocked
                                                ? LogosIcons.radioButtonUncheckedRounded
                                                : LogosIcons.lockOutlineRounded),
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
                      KeyedSubtree(
                        key: _dayCardKey,
                        child: _buildDayDetailCard(
                        context: context,
                        day: _selectedDay,
                        drop: drop,
                        state: state,
                        surface: surface,
                        ink: ink,
                        isDark: isDark,
                      ),
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
    required LogosIconData icon,
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
          AppIcon(icon, size: 14, color: iconColor),
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
                'Meet the verse through a short guided reading, then recite it aloud twice.',
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
                        child: const AppIcon(LogosIcons.playArrowRounded, color: LogosColors.coral),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Meet the verse',
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: ink),
                            ),
                            Text(
                              'A short guided reading',
                              style: GoogleFonts.inter(fontSize: 11, color: ink.withValues(alpha: 0.55)),
                            ),
                          ],
                        ),
                      ),
                      const AppIcon(LogosIcons.chevronRight, size: 18, color: Colors.grey),
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
                  icon: const AppIcon(LogosIcons.micRounded),
                  label: Text(
                    isPassed
                        ? 'Both recitations done ✓'
                        : 'Recite aloud ($count of 2)',
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
                    'DAY 2 · CONTEXT',
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
                'Read the background and original words below, then recite the verse twice.',
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
                  icon: const AppIcon(LogosIcons.micRounded),
                  label: Text(
                    isPassed
                        ? 'Day 2 Complete ($count/2 Passed ✓)'
                        : 'Recite aloud ($count of 2)',
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
            gradient: LogosColors.whitePurpleBlend,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: LogosColors.taupe, width: 1.2),
            boxShadow: LogosColors.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'DAY 3 · STILLNESS',
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
                      color: isStillnessDone
                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                          : LogosColors.coral.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isStillnessDone ? 'Stillness Sealed ✓' : '60s Required',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isStillnessDone ? const Color(0xFF10B981) : LogosColors.coral,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Rest with the verse for one quiet, guided minute. Let your thoughts settle in Christ.',
                style: LogosTypography.body(color: ink.withValues(alpha: 0.8)),
              ),
              const SizedBox(height: 18),
              // Ambient player button
              GestureDetector(
                onTap: () => _toggleStillnessAudio(drop.ambientPreset),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: LogosColors.taupe),
                    boxShadow: LogosColors.softShadow,
                  ),
                  child: Row(
                    children: [
                      AppIcon(
                        _isStillnessPlaying ? LogosIcons.pauseCircleFilledRounded : LogosIcons.playCircleFillRounded,
                        color: LogosColors.coral,
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
                                color: ink,
                              ),
                            ),
                            Text(
                              _isStillnessPlaying
                                  ? 'Playing (${_stillnessSecondsElapsed}s / 60s elapsed)'
                                  : 'Tap to play quiet background sound',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: ink.withValues(alpha: 0.6),
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
                        backgroundColor: LogosColors.coral,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: AppIcon(isStillnessDone ? LogosIcons.checkCircleRounded : LogosIcons.spaRounded, size: 16),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => StillnessSanctuaryScreen(drop: drop),
                          ),
                        );
                      },
                      label: Text(
                        isStillnessDone ? 'Stillness complete ✓' : 'Begin stillness',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12.5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: LogosColors.coral),
                    icon: const AppIcon(LogosIcons.mic, size: 16, color: LogosColors.coral),
                    label: Text(count > 0 ? 'Recited ✓' : 'Recite (optional)'),
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
            border: Border.all(color: LogosColors.taupe, width: 1.2),
            boxShadow: LogosColors.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'DAY 4 · THE EXCHANGE',
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
                      state.isExchangeCompleted ? 'Week complete ✓' : 'Final day',
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
                'Recite the verse from memory, then lay a burden down at the cross. It is kept as a Tear Sheet on your Altar.',
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
                      icon: AppIcon(
                        hasPassedMaster ? LogosIcons.checkCircleRounded : LogosIcons.psychologyRounded,
                        color: hasPassedMaster ? const Color(0xFF10B981) : LogosColors.coral,
                      ),
                      label: Text(
                        hasPassedMaster ? 'Recited from memory ✓' : '1. Recite from memory',
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
                      icon: const AppIcon(LogosIcons.syncAltRounded, size: 16),
                      label: Text(
                        state.isExchangeCompleted ? 'Burden laid down ✓' : '2. Lay a burden down',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ExchangeCanvas(
                              verseText: drop.verseText,
                              reference: drop.reference,
                              weekNumber: drop.weekNumber,
                              onExchangeCompleted: (burden) {
                                context.read<JourneyBloc>().add(CompleteExchange(burdenSummary: burden));
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
