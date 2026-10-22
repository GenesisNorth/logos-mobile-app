import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/logos_theme.dart';
import 'core/theme/logos_typography.dart';
import 'features/journey/bloc/journey_bloc.dart';
import 'features/journey/bloc/journey_event.dart';
import 'features/journey/bloc/journey_state.dart';
import 'features/journey/models/scripture_drop.dart';
import 'features/recitation/screens/recitation_dialog.dart';
import 'features/exchange/screens/exchange_canvas.dart';
import 'features/examen/controllers/examen_controller.dart';

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
      create: (_) => JourneyBloc(),
      child: MaterialApp(
        title: 'LOGOS IN ME',
        debugShowCheckedModeBanner: false,
        theme: LogosTheme.lightTheme(),
        darkTheme: LogosTheme.examenTheme(),
        themeMode: _examenController.isExamenMode
            ? ThemeMode.dark
            : ThemeMode.light,
        home: HomeScreen(examenController: _examenController),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final ExamenController examenController;
  const HomeScreen({super.key, required this.examenController});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedDay = 1;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? LogosColors.examenInk : LogosColors.ink;
    final surface = isDark ? LogosColors.examenSurface : LogosColors.surface;

    return BlocBuilder<JourneyBloc, JourneyState>(
      builder: (context, state) {
        final drop = state.activeDrop;

        return Scaffold(
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
                            label: '${state.graceTokensBalance} Grace Tokens',
                            surface: surface,
                            ink: ink,
                          ),
                        ],
                      ),

                      // Examen Evening Card (Surfaced during 8 PM - 5 AM)
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
                              const SizedBox(height: 6),
                              Text(
                                'Where did you sense the presence of Christ today? What weight can you leave at the cross tonight?',
                                style: LogosTypography.body(
                                  color: LogosColors.examenInk.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

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
                                  ),
                                ),
                                Text(
                                  drop.translation,
                                  style: LogosTypography.caption(
                                    color: ink.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
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
                                  color: ink.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 4-Day Journey Step Selector
                      Text(
                        'The 4-Day Sacred Rhythm',
                        style: LogosTypography.headline(color: ink),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: List.generate(4, (index) {
                          final day = index + 1;
                          final isSelected = _selectedDay == day;
                          final isCompleted =
                              state.dayCompletionStatus[day] ?? false;
                          final isUnlocked = state.isDayUnlocked(day);

                          return Expanded(
                            child: GestureDetector(
                              onTap: isUnlocked
                                  ? () => setState(() => _selectedDay = day)
                                  : null,
                              child: Container(
                                margin: EdgeInsets.only(
                                  right: day < 4 ? 8 : 0,
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
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
                'Watch the introductory visual title card, then complete your first 2 microphone recitation passes.',
                style: LogosTypography.body(color: ink.withValues(alpha: 0.8)),
              ),
              const SizedBox(height: 16),
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
                      ? 'Recitations Complete (2/2 Passed ✓)'
                      : 'Begin Recitation Ritual ($count/2)',
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => RecitationDialog(
                      verseText: drop.verseText,
                      reference: drop.reference,
                      dayNumber: 1,
                      onPassed: (score) {
                        context.read<JourneyBloc>().add(
                              CompleteDayRecitation(
                                dayNumber: 1,
                                score: score,
                              ),
                            );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        );

      case 2:
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
              const SizedBox(height: 12),
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
            ],
          ),
        );

      case 3:
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
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Full-bleed sanctuary contemplation with ambient soundscapes.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.graphic_eq, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      drop.ambientSoundPreset,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      case 4:
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
                'Day 4: Master & The Exchange',
                style: LogosTypography.label(color: LogosColors.coral),
              ),
              const SizedBox(height: 6),
              Text(
                'The spiritual climax of the week: pass your master recitation test, then drag the Scripture over your heavy burden to dissolve it into a Tear Sheet.',
                style: LogosTypography.body(color: ink.withValues(alpha: 0.85)),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: LogosColors.coral,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.sync_alt),
                label: Text(
                  state.isExchangeCompleted
                      ? 'The Exchange Completed (Tear Sheet Saved)'
                      : 'Enter The Exchange Canvas',
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ExchangeCanvas(
                        verseText: drop.verseText,
                        reference: drop.reference,
                        onExchangeCompleted: () {
                          context.read<JourneyBloc>().add(
                                const CompleteExchange(
                                  burdenSummary: "Dissolved burden",
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

      default:
        return const SizedBox.shrink();
    }
  }
}
