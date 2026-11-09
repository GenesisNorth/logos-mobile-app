import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/design/components.dart';
import '../../core/design/organic.dart';
import '../../core/services/verse_reader.dart';
import '../examen/examen_store.dart';
import '../journey/bloc/journey_bloc.dart';
import '../journey/bloc/journey_event.dart';
import '../journey/bloc/journey_state.dart';
import '../journey/data/progress_repository.dart';
import '../journey/data/week_design.dart';
import 'day_router.dart';
import 'today_sheets.dart';
import 'widgets/today_widgets.dart';

/// Today — the verse is the hero; the week's rhythm is its spine.
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  void _openSeed(BuildContext context, JourneyState s, int day) {
    final done = s.dayCompletionStatus[day] == true;
    if (done || (day == s.todayDay && s.isDayUnlocked(day))) {
      openDay(context, day);
    } else {
      showLockedSheet(context, s, day);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ExamenStore.instance,
      builder: (context, _) => BlocBuilder<JourneyBloc, JourneyState>(
        builder: (context, s) {
          final drop = s.activeDrop;
          final design = weekDesignFor(drop.weekNumber);
          final now = DateTime.now();
          final anniversary = _anniversarySheet(s, now);
          final showMissed = s.graceTokensBalance > 0 && s.isStreakRecoverable(now: now);
          final showExamen = ExamenStore.instance.shouldOffer(now);

          return OScreen(
            atmosphere: Atmosphere.parchment,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 120),
              children: [
                _Header(name: s.profile.displayName),
                const SizedBox(height: 18),
                if (showMissed) ...[_MissedBanner(state: s), const SizedBox(height: 16)],
                if (anniversary != null) ...[_AnniversaryCard(sheet: anniversary, now: now), const SizedBox(height: 18)],
                if (showExamen) ...[const _ExamenBanner(), const SizedBox(height: 16)],
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OPill('Week ${drop.weekNumber} · ${design.title}',
                        chevron: true, bg: OC.surface, onTap: () => showWeekSheet(context, s)),
                    OPill(drop.translation,
                        chevron: true,
                        bg: Colors.transparent,
                        border: OC.divider,
                        onTap: () => showTranslationSheet(
                              context,
                              current: drop.translation,
                              previews: drop.translations,
                              onSelected: (key) {
                                context.read<JourneyBloc>().add(SelectTranslation(key));
                              },
                            )),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: Text(drop.reference.toUpperCase(), style: OT.kicker())),
                    _ListenButton(text: drop.verseText, reference: drop.reference),
                  ],
                ),
                const SizedBox(height: 6),
                VerseView(text: drop.verseText, keyStems: design.keyStems, size: 31),
                const SizedBox(height: 26),
                Row(
                  children: [
                    Expanded(child: Text('This week’s rhythm', style: OT.label(size: 15))),
                    Text('${s.todayDay > 4 ? 4 : s.todayDay} of 4', style: OT.small(alpha: 0.6)),
                  ],
                ),
                const SizedBox(height: 14),
                RhythmSeeds(state: s, onTap: (d) => _openSeed(context, s, d), onDebugOpen: (d) => openDay(context, d)),
                const SizedBox(height: 18),
                _TodayHero(state: s, design: design),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        icon: OI.flame,
                        iconColor: OC.a600,
                        value: '${s.activeStreak(now: now)}',
                        label: 'day streak',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatTile(icon: OI.sprout, iconColor: OC.s600, value: '${s.rootsPlanted}', label: 'roots planted'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatTile(icon: OI.heart, iconColor: OC.a600, value: '${s.graceTokensBalance}', label: 'grace tokens'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// The oldest laid-down burden (30+ days ago) still awaiting a check-in.
  TearSheetData? _anniversarySheet(JourneyState s, DateTime now) {
    final candidates = s.savedTearSheets
        .where((t) => t.checkIn == null && (t.burdenText ?? '').isNotEmpty && now.difference(t.completedAt).inDays >= 30)
        .toList()
      ..sort((a, b) => a.completedAt.compareTo(b.completedAt));
    return candidates.isEmpty ? null : candidates.first;
  }
}

class _Header extends StatelessWidget {
  final String name;
  const _Header({required this.name});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        OAvatar(name, size: 50),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting(), style: OT.small(alpha: 0.7)),
              Text(name, style: OT.display(21), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        OCircleButton(icon: OI.bell, tooltip: 'Liturgical hours', onTap: () => showHoursSheet(context), size: 48),
      ],
    );
  }
}

class _ListenButton extends StatelessWidget {
  final String text;
  final String reference;
  const _ListenButton({required this.text, required this.reference});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: VerseReader.instance,
      builder: (context, _) {
        final reading = VerseReader.instance.isReading(text);
        return OPill(
          reading ? 'Stop' : 'Listen',
          bg: Colors.transparent,
          fg: OC.a600,
          fontSize: 13,
          onTap: () async {
            if (reading) {
              await VerseReader.instance.stop();
            } else if (!await VerseReader.instance.speak(text, reference: reference) && context.mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('No reading voice is available on this phone.')));
            }
          },
        );
      },
    );
  }
}

class _TodayHero extends StatefulWidget {
  final JourneyState state;
  final WeekDesign design;
  const _TodayHero({required this.state, required this.design});

  @override
  State<_TodayHero> createState() => _TodayHeroState();
}

class _TodayHeroState extends State<_TodayHero> {
  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final day = s.todayDay;
    if (day > 4) {
      return HeroCard(
        kicker: 'WEEK ${s.activeDrop.weekNumber} COMPLETE',
        title: widget.design.rest,
        body: widget.design.nextLine,
        bg: OC.s700,
        decorBig: OC.s600,
        decorSmall: OC.s600,
        action: 'Begin Week ${s.activeDrop.weekNumber + 1}',
        actionStyle: OButtonStyle.paleSage,
        onAction: () => context.read<JourneyBloc>().add(const AdvanceToNextWeek()),
      );
    }
    final info = dayInfo[day]!;
    if (!s.isDayUnlocked(day)) {
      final wait = s.timeUntilUnlock(day);
      return HeroCard(
        kicker: 'DONE FOR TODAY',
        title: 'Rest in today’s word.',
        body: 'Day $day · ${info.name} opens at midnight'
            '${wait != null ? ' — in ${wait.inHours}h ${wait.inMinutes % 60}m' : ''}.',
        bg: OC.n800,
        decorBig: OC.n700,
        decorSmall: OC.n600,
        action: 'Set a morning bell',
        onAction: () => showLockedSheet(context, s, day),
      );
    }
    return HeroCard(
      kicker: 'TODAY · DAY $day',
      title: info.title,
      body: day == 2 ? widget.design.rootsSummary : info.body,
      action: 'Begin · ${info.minutes}',
      actionIcon: OI.play,
      onAction: () => openDay(context, day),
    );
  }
}

class _MissedBanner extends StatelessWidget {
  final JourneyState state;
  const _MissedBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    return OCard(
      color: OC.a100,
      padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(color: OC.a200, shape: BoxShape.circle),
            child: const Center(child: OIcon(OI.heart, size: 20, color: OC.a700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Yesterday slipped by', style: OT.label(size: 15)),
                Text('A grace token keeps your ${state.currentStreak}-day streak whole.', style: OT.small(alpha: 0.75)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OButton('Restore', expand: false, height: 40, onPressed: () {
            context.read<JourneyBloc>().add(const RedeemGraceToken());
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Grace received. Practise today to keep it going.')),
            );
          }),
        ],
      ),
    );
  }
}

class _ExamenBanner extends StatelessWidget {
  const _ExamenBanner();

  @override
  Widget build(BuildContext context) {
    return OCard(
      color: OC.n900,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      onTap: () => openExamen(context),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(color: OC.a700, shape: BoxShape.circle),
            child: const Center(child: OIcon(OI.moon, size: 20, color: OC.a200)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Evening examen', style: OT.display(19, color: OC.n100)),
                Text('Three questions before rest · 3 min', style: OT.small(color: OC.n100, alpha: 0.75)),
              ],
            ),
          ),
          const OIcon(OI.next, size: 18, color: OC.n100),
        ],
      ),
    );
  }
}

class _AnniversaryCard extends StatelessWidget {
  final TearSheetData sheet;
  final DateTime now;
  const _AnniversaryCard({required this.sheet, required this.now});

  @override
  Widget build(BuildContext context) {
    final days = now.difference(sheet.completedAt).inDays;
    void answer(String a) {
      context.read<JourneyBloc>().add(RecordTearSheetCheckIn(sheet.id, a));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(a == 'lighter' ? 'Thank God. Kept on your Altar.' : 'Bring it again. He is not tired of you.'),
      ));
    }

    return Transform.rotate(
      angle: -0.012,
      child: OCard(
        shadow: OShadow.md,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$days DAYS AGO YOU LAID THIS DOWN', style: OT.kicker(size: 11)),
            const SizedBox(height: 8),
            Text('“${sheet.burdenText}”', style: OT.display(20, height: 1.2)),
            const SizedBox(height: 10),
            Text('How is it now?', style: OT.small()),
            const SizedBox(height: 10),
            Wrap(spacing: 8, children: [
              OPill('Lighter', bg: OC.s200, fg: OC.s900, onTap: () => answer('lighter')),
              OPill('Still carrying', bg: Colors.transparent, border: OC.divider, onTap: () => answer('carrying')),
            ]),
          ],
        ),
      ),
    );
  }
}
