import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/logos_icons.dart';
import '../../../core/theme/logos_theme.dart';
import '../bloc/journey_state.dart';

const dayTitles = {1: 'Encounter', 2: 'Context', 3: 'Stillness', 4: 'The Exchange'};

/// What the pilgrim should do right now: continue today's step, rest until
/// the next step opens, or begin the next week.
class TodayCard extends StatefulWidget {
  final JourneyState state;
  final ValueChanged<int> onOpenDay;
  final VoidCallback onNextWeek;

  const TodayCard({super.key, required this.state, required this.onOpenDay, required this.onNextWeek});

  @override
  State<TodayCard> createState() => _TodayCardState();
}

class _TodayCardState extends State<TodayCard> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // Keeps the "opens in …" countdown current.
    _tick = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? LogosColors.examenInk : LogosColors.ink;
    final surface = isDark ? LogosColors.examenSurface : LogosColors.surface;

    final weekDone = s.dayCompletionStatus[4] == true;
    final nextDay = [1, 2, 3, 4].firstWhere((d) => s.dayCompletionStatus[d] != true, orElse: () => 4);
    final unlocked = s.isDayUnlocked(nextDay);

    late final String eyebrow;
    late final String title;
    late final String body;
    String? action;
    VoidCallback? onAction;
    var resting = false;

    if (weekDone) {
      eyebrow = 'WEEK ${s.activeDrop.weekNumber} COMPLETE';
      title = 'You carried this verse all week';
      body = 'Begin next week with a new verse whenever you are ready.';
      action = 'Begin next week';
      onAction = widget.onNextWeek;
    } else if (unlocked) {
      final count = s.dayRecitationCount[nextDay] ?? 0;
      eyebrow = 'TODAY · DAY $nextDay';
      title = dayTitles[nextDay]!;
      body = switch (nextDay) {
        1 => count == 0
            ? 'Meet the verse, then recite it aloud twice.'
            : 'One more recitation to finish today ($count of 2 done).',
        2 => count == 0
            ? 'Read the background cards, then recite twice.'
            : 'One more recitation to finish today ($count of 2 done).',
        3 => 'Sit in stillness with the verse for one minute.',
        _ => 'Recite from memory, then lay a burden down.',
      };
      action = count > 0 ? 'Continue' : 'Start';
      onAction = () => widget.onOpenDay(nextDay);
    } else {
      resting = true;
      final wait = s.timeUntilUnlock(nextDay);
      final h = wait?.inHours ?? 0;
      final m = (wait?.inMinutes ?? 0) % 60;
      eyebrow = 'DONE FOR TODAY';
      title = 'Rest in today’s word';
      body = 'Day $nextDay · ${dayTitles[nextDay]} opens at midnight'
          '${wait != null ? ' (in ${h > 0 ? '$h h ' : ''}$m min)' : ''}.';
    }

    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: resting ? surface : LogosColors.coral.withValues(alpha: isDark ? 0.18 : 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: resting ? LogosColors.taupe : LogosColors.coral.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            AppIcon(
              resting ? LogosIcons.bedtimeOutlined : (weekDone ? LogosIcons.checkCircleRounded : LogosIcons.autoStories),
              color: LogosColors.coral,
              size: 26,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(eyebrow,
                      style: GoogleFonts.inter(
                          fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: LogosColors.coral)),
                  const SizedBox(height: 3),
                  Text(title, style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: ink)),
                  const SizedBox(height: 3),
                  Text(body, style: GoogleFonts.inter(fontSize: 13, height: 1.35, color: ink.withValues(alpha: 0.7))),
                ],
              ),
            ),
            if (action != null) ...[
              const SizedBox(width: 10),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: LogosColors.coral,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: onAction,
                child: Text(action, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
