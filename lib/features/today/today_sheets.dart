import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/config/app_flags.dart';
import '../../core/design/components.dart';
import '../../core/design/organic.dart';
import '../../core/services/notification_service.dart';
import '../journey/bloc/journey_bloc.dart';
import '../journey/bloc/journey_event.dart';
import '../journey/bloc/journey_state.dart';
import '../journey/data/bible_translations.dart';
import '../journey/data/content_repository.dart';
import '../journey/data/week_design.dart';
import '../journey/screens/scripture_packs_sheet.dart';
import '../journey/screens/translation_notices_screen.dart';

void _toast(BuildContext context, String msg) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

// ─── Translation ───────────────────────────────────────────────────────────

/// Translation picker: every version with a live preview of this week's verse.
Future<void> showTranslationSheet(
  BuildContext context, {
  required String current,
  required Map<String, String>? previews,
  required ValueChanged<String> onSelected,
}) {
  final options = bibleTranslations.where((t) => previews == null || previews.containsKey(t.key)).toList();
  return showOSheet(
    context,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Translation', style: OT.h2()),
        const SizedBox(height: 4),
        Text('You’ll read, hear and recite in this one.', style: OT.small()),
        const SizedBox(height: 14),
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: options.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final t = options[i];
              final on = t.key == current;
              return Semantics(
                button: true,
                selected: on,
                label: t.name,
                excludeSemantics: true,
                child: OCard(
                  color: on ? OC.a100 : OC.n100,
                  border: Border.all(color: on ? OC.accent : Colors.transparent, width: 1.6),
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  onTap: () {
                    Navigator.pop(ctx);
                    onSelected(t.key);
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(t.key, style: OT.label(size: 15)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(t.name, style: OT.small(), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ]),
                      if (previews?[t.key] != null) ...[
                        const SizedBox(height: 6),
                        Text(previews![t.key]!, maxLines: 3, overflow: TextOverflow.ellipsis, style: OT.display(15, height: 1.3)),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Center(
          child: TextButton(
            onPressed: () => Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => const TranslationNoticesScreen())),
            child: Text('Translation notices', style: OT.small(alpha: 0.6)),
          ),
        ),
      ],
    ),
  );
}

// ─── Weeks ─────────────────────────────────────────────────────────────────

Future<void> showWeekSheet(BuildContext context, JourneyState state, {VoidCallback? onWeekChanged}) {
  final drops = const ContentRepository().drops;
  final currentIndex = drops.indexWhere((d) => d.id == state.activeDrop.id);
  return showOSheet(
    context,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('One verse at a time', style: OT.h3()),
        const SizedBox(height: 4),
        Text(
          state.canChangeWeek ? 'Choose this week’s verse.' : 'Finish this week’s four days to move on.',
          style: OT.small(),
        ),
        const SizedBox(height: 16),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (var i = 0; i < drops.length; i++)
                _WeekRow(
                  index: i,
                  isCurrent: i == currentIndex,
                  isPast: i < currentIndex,
                  enabled: i == currentIndex || state.canChangeWeek,
                  offset: i - currentIndex,
                  onTap: () {
                    Navigator.pop(ctx);
                    if (i == currentIndex) return;
                    if (!state.canChangeWeek) {
                      _toast(context, 'You’re mid-week. Finish its four days to move on.');
                      return;
                    }
                    context.read<JourneyBloc>().add(SelectWeek(i));
                    onWeekChanged?.call();
                  },
                ),
            ],
          ),
        ),
        if (AppFlags.instance.isOn(AppFlags.scripturePacks)) ...[
          const SizedBox(height: 12),
          OButton('Offline scripture packs', style: OButtonStyle.outline, onPressed: () {
            Navigator.pop(ctx);
            ScripturePacksSheet.show(context);
          }),
        ],
      ],
    ),
  );
}

class _WeekRow extends StatelessWidget {
  final int index;
  final bool isCurrent;
  final bool isPast;
  final bool enabled;
  final int offset;
  final VoidCallback onTap;
  const _WeekRow({
    required this.index,
    required this.isCurrent,
    required this.isPast,
    required this.enabled,
    required this.offset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final drop = const ContentRepository().drops[index];
    final design = weekDesignFor(drop.weekNumber);
    final right = isCurrent
        ? 'This week'
        : !enabled
            ? 'Later'
            : isPast
                ? 'Revisit'
                : (offset == 1 ? 'Next' : 'Week ${drop.weekNumber}');
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: isCurrent
                  ? Container(
                      decoration: const BoxDecoration(color: OC.accent, shape: BoxShape.circle),
                      child: Center(child: Text('${drop.weekNumber}', style: OT.display(18, color: OC.n100))),
                    )
                  : CustomPaint(
                      painter: const DashedCirclePainter(color: OC.n400, strokeWidth: 1.6),
                      child: Center(child: Text('${drop.weekNumber}', style: OT.display(17, color: OC.n600))),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(drop.reference, style: OT.label(size: 15)),
                  Text('${design.title} · ${design.rootWord}', style: OT.small()),
                ],
              ),
            ),
            Text(right, style: OT.body(size: 13, weight: FontWeight.w700, color: OC.text.withValues(alpha: enabled ? 0.65 : 0.4))),
          ],
        ),
      ),
    );
  }
}

// ─── Locked day ────────────────────────────────────────────────────────────

Future<void> showLockedSheet(BuildContext context, JourneyState state, int day) {
  final wait = state.timeUntilUnlock(day);
  final prevDone = state.dayCompletionStatus[day - 1] == true;
  final n = NotificationService.instance;
  final laudsSet = n.isEnabled && n.isChimeOn(LiturgicalHour.lauds);
  return showOSheet(
    context,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(color: OC.n200, shape: BoxShape.circle),
          child: const Center(child: OIcon(OI.lock, size: 24, color: OC.n800)),
        ),
        const SizedBox(height: 18),
        Text(prevDone ? 'Day $day opens at midnight' : 'Day ${day - 1} comes first', style: OT.h3()),
        const SizedBox(height: 6),
        if (prevDone && wait != null)
          Text('in ${wait.inHours}h ${wait.inMinutes % 60}m', style: OT.label(size: 16, color: OC.a600)),
        const SizedBox(height: 14),
        Text(
          prevDone
              ? 'The rhythm is slow on purpose. Let today’s word keep working.'
              : 'Each day opens after the one before it. Return to Day ${day - 1} when you’re ready.',
          style: OT.body(color: OC.text.withValues(alpha: 0.8)),
        ),
        const SizedBox(height: 22),
        if (prevDone)
          OButton(
            laudsSet ? 'The Lauds bell will ring at 7 AM' : 'Remind me at Lauds · 7 AM',
            onPressed: laudsSet
                ? () => Navigator.pop(ctx)
                : () async {
                    await n.setChime(LiturgicalHour.lauds, true);
                    if (!n.isEnabled) await n.toggleNotifications(true);
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) {
                      _toast(context, n.isEnabled ? 'We’ll ring the Lauds bell at 7 AM.' : 'Allow notifications to hear the bell.');
                    }
                  },
          )
        else
          OButton('Okay', onPressed: () => Navigator.pop(ctx)),
      ],
    ),
  );
}

// ─── Liturgical hours ──────────────────────────────────────────────────────

/// Toggle list of the four liturgical chimes (used by onboarding and the sheet).
class ChimeList extends StatefulWidget {
  const ChimeList({super.key});

  @override
  State<ChimeList> createState() => _ChimeListState();
}

class _ChimeListState extends State<ChimeList> {
  final n = NotificationService.instance;

  @override
  Widget build(BuildContext context) {
    return OCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      child: Column(
        children: [
          for (final h in LiturgicalHour.values) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${h.label} · ${h.timeLabel}', style: OT.label(size: 16)),
                        const SizedBox(height: 2),
                        Text(h.description, style: OT.small()),
                      ],
                    ),
                  ),
                  OToggle(
                    value: n.isChimeOn(h),
                    semanticLabel: '${h.label} chime',
                    onChanged: (v) async {
                      await n.setChime(h, v);
                      if (mounted) setState(() {});
                    },
                  ),
                ],
              ),
            ),
            if (h != LiturgicalHour.values.last) Divider(height: 1, color: OC.divider),
          ],
        ],
      ),
    );
  }
}

Future<void> showHoursSheet(BuildContext context) {
  final n = NotificationService.instance;
  return showOSheet(
    context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Liturgical hours', style: OT.h2()),
            const SizedBox(height: 4),
            Text('Gentle chimes through the day.', style: OT.small()),
            const SizedBox(height: 16),
            const ChimeList(),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: Text('Chimes on', style: OT.label(size: 16))),
                OToggle(
                  value: n.isEnabled,
                  semanticLabel: 'Chimes on',
                  onChanged: (v) async {
                    await n.toggleNotifications(v);
                    setSheet(() {});
                    if (v && !n.isEnabled && ctx.mounted) {
                      _toast(ctx, 'Notifications are blocked. Allow them in your phone’s settings.');
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
