import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/app_flags.dart';
import '../../../core/design/components.dart';
import '../../../core/design/organic.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/date_format.dart';
import '../../examen/controllers/examen_controller.dart';
import '../../examen/examen_store.dart';
import '../../journey/bloc/journey_bloc.dart';
import '../../journey/bloc/journey_event.dart';
import '../../journey/bloc/journey_state.dart';
import '../../journey/data/bible_translations.dart';
import '../../journey/data/content_repository.dart';
import '../../journey/data/progress_repository.dart';
import '../../journey/screens/scripture_packs_sheet.dart';
import '../../today/today_sheets.dart';
import '../altar_sheets.dart';

/// Altar — your rhythm, kept gently: streak, grace, the vine of weeks,
/// tear sheets, and the quiet settings.
class AltarScreen extends StatefulWidget {
  final ExamenController examenController;
  const AltarScreen({super.key, required this.examenController});

  @override
  State<AltarScreen> createState() => _AltarScreenState();
}

class _AltarScreenState extends State<AltarScreen> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ExamenStore.instance,
      builder: (context, _) => BlocBuilder<JourneyBloc, JourneyState>(
        builder: (context, s) => OScreen(
          atmosphere: Atmosphere.parchment,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 120),
            children: [
              Text('Altar', style: OT.h1()),
              Text('Your rhythm, kept gently.', style: OT.body(color: OC.text.withValues(alpha: 0.7))),
              const SizedBox(height: 18),
              _StreakCard(state: s),
              const SizedBox(height: 14),
              _GraceCard(state: s),
              const SizedBox(height: 26),
              _VineSection(state: s),
              const SizedBox(height: 26),
              Text('Tear sheets', style: OT.h3()),
              const SizedBox(height: 6),
              Text('Burdens you lay down on Day 4 are kept here, sealed with the week’s verse.', style: OT.small()),
              const SizedBox(height: 14),
              if (s.savedTearSheets.isEmpty)
                OCard(
                  color: OC.surface,
                  child: Text('Your first tear sheet will rest here after Day 4.', style: OT.small(alpha: 0.75)),
                )
              else
                SizedBox(
                  height: 168,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    itemCount: s.savedTearSheets.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) => _TearSheetTile(sheet: s.savedTearSheets.reversed.toList()[i], index: i),
                  ),
                ),
              const SizedBox(height: 22),
              _Settings(state: s, onChanged: () => setState(() {})),
            ],
          ),
        ),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final JourneyState state;
  const _StreakCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final streak = state.activeStreak(now: now);
    final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final week = List.generate(7, (i) => monday.add(Duration(days: i)));
    final keptThisWeek = week.where((d) => !d.isAfter(now) && state.practisedOn(d)).length;
    final todayIdx = now.weekday - 1;
    final caption = streak == 0
        ? 'Your first day is waiting.'
        : keptThisWeek >= todayIdx + 1
            ? 'Every day this week, you returned.'
            : 'You returned $keptThisWeek ${keptThisWeek == 1 ? 'day' : 'days'} this week.';

    return OCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(color: OC.accent, shape: BoxShape.circle),
                child: Center(child: Text('$streak', style: OT.display(42, color: OC.n100))),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('day streak', style: OT.display(24)),
                    const SizedBox(height: 4),
                    Text(caption, style: OT.small(alpha: 0.75)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < 7; i++)
                Column(
                  children: [
                    _DayDot(kept: state.practisedOn(week[i]), today: i == todayIdx, future: i > todayIdx),
                    const SizedBox(height: 6),
                    Text('MTWTFSS'[i], style: OT.body(size: 12, weight: FontWeight.w700, color: OC.text.withValues(alpha: 0.6))),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  final bool kept;
  final bool today;
  final bool future;
  const _DayDot({required this.kept, required this.today, required this.future});

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: kept ? OC.s500 : (future ? Colors.transparent : OC.n200),
        shape: BoxShape.circle,
        border: future ? Border.all(color: OC.n300, width: 1.5) : null,
      ),
      child: kept ? const Center(child: OIcon(OI.check, size: 16, color: OC.n100)) : null,
    );
    if (!today) return dot;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: kept ? OC.s500 : OC.n400, width: 2)),
      child: dot,
    );
  }
}

class _GraceCard extends StatelessWidget {
  final JourneyState state;
  const _GraceCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return OCard(
      color: OC.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Grace tokens', style: OT.display(23))),
              graceTokenDots(state.graceTokensBalance),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            state.graceTokensBalance > 0
                ? 'Missed a day? A token restores your streak — no guilt, no reset.'
                : 'Finish a full week’s rhythm to earn a token back.',
            style: OT.small(alpha: 0.8),
          ),
          const SizedBox(height: 14),
          OButton('Redeem a token',
              expand: false,
              height: 44,
              style: OButtonStyle.outline,
              outlineColor: OC.a700,
              onPressed: () => showGraceSheet(context, state)),
        ],
      ),
    );
  }
}

class _VineSection extends StatelessWidget {
  final JourneyState state;
  const _VineSection({required this.state});

  @override
  Widget build(BuildContext context) {
    final drops = const ContentRepository().drops;
    final current = state.activeDrop.weekNumber;
    final weeksKept = state.rootsPlanted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Your vine', style: OT.h3())),
            Text('$weeksKept of ${drops.length} weeks', style: OT.small(alpha: 0.65)),
          ],
        ),
        const SizedBox(height: 12),
        OCard(
          color: OC.s100,
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
          child: SizedBox(
            height: 78,
            child: Stack(
              children: [
                Positioned(left: 0, right: 0, top: 22, child: Container(height: 3, color: OC.s300)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (final d in drops)
                      _Leaf(
                        number: d.weekNumber,
                        isNow: d.weekNumber == current,
                        kept: d.weekNumber < current || (d.weekNumber == current && state.dayCompletionStatus[4] == true),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Leaf extends StatelessWidget {
  final int number;
  final bool isNow;
  final bool kept;
  const _Leaf({required this.number, required this.isNow, required this.kept});

  @override
  Widget build(BuildContext context) {
    final color = isNow ? OC.accent : (kept ? OC.s500 : Colors.transparent);
    return Semantics(
      label: 'Week $number${isNow ? ', now' : kept ? ', kept' : ''}',
      excludeSemantics: true,
      child: Column(
        children: [
          Transform.rotate(
            angle: -0.78,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                border: color == Colors.transparent ? Border.all(color: OC.s400, width: 1.6) : null,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
              ),
              child: Transform.rotate(
                angle: 0.78,
                child: Center(
                  child: Text('$number',
                      style: OT.display(16, color: isNow || kept ? OC.n100 : OC.s700)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(isNow ? 'Now' : '', style: OT.body(size: 12, weight: FontWeight.w700, color: OC.s900)),
        ],
      ),
    );
  }
}

class _TearSheetTile extends StatelessWidget {
  final TearSheetData sheet;
  final int index;
  const _TearSheetTile({required this.sheet, required this.index});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: index.isEven ? -0.025 : 0.02,
      child: SizedBox(
        width: 220,
        child: OCard(
          shadow: OShadow.md,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          onTap: () => showTearSheet(context, sheet),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TEAR SHEET · ${formatLogosDate(sheet.completedAt).toUpperCase()}', style: OT.kicker(color: OC.a700, size: 10)),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  sheet.burdenText?.isNotEmpty == true ? sheet.burdenText! : 'A burden, laid down.',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: OT.display(17, height: 1.25),
                ),
              ),
              Text('EXCHANGED FOR · ${sheet.reference.toUpperCase()}', style: OT.kicker(color: OC.s700, size: 10)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Settings extends StatelessWidget {
  final JourneyState state;
  final VoidCallback onChanged;
  const _Settings({required this.state, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final n = NotificationService.instance;
    final hoursOn = [for (final h in LiturgicalHour.values) if (n.isChimeOn(h)) h.label].join(' · ');
    final tr = translationByKey(state.activeDrop.translation);
    final rows = <Widget>[
      _SettingRow(
        title: 'Examen evenings',
        subtitle: 'An evening prompt · 8 PM – 5 AM',
        trailing: OToggle(
          value: ExamenStore.instance.eveningsEnabled,
          semanticLabel: 'Examen evenings',
          onChanged: (v) => ExamenStore.instance.setEveningsEnabled(v),
        ),
      ),
      _SettingRow(
        title: 'Liturgical chimes',
        subtitle: hoursOn.isEmpty ? 'No hours chosen' : hoursOn,
        trailing: OToggle(
          value: n.isEnabled,
          semanticLabel: 'Liturgical chimes',
          onChanged: (v) async {
            await n.toggleNotifications(v);
            onChanged();
            if (v && !n.isEnabled && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Notifications are blocked. Allow them in your phone’s settings.'),
              ));
            }
          },
        ),
      ),
      _SettingRow(
        title: 'Translation',
        subtitle: tr?.name ?? state.activeDrop.translation,
        trailing: Text(state.activeDrop.translation, style: OT.label(size: 15, color: OC.a600)),
        onTap: () => showTranslationSheet(
          context,
          current: state.activeDrop.translation,
          previews: state.activeDrop.translations,
          onSelected: (k) => context.read<JourneyBloc>().add(SelectTranslation(k)),
        ),
      ),
      _SettingRow(
        title: 'Liturgical hours',
        subtitle: 'Lauds · Sext · Vespers · Midnight bell',
        onTap: () => showHoursSheet(context).then((_) => onChanged()),
      ),
      _SettingRow(
        title: Theme.of(context).platform == TargetPlatform.iOS ? 'Home widget & Dynamic Island' : 'Home screen widgets',
        subtitle: 'Today’s verse on your home & lock screen',
        onTap: () => showGlanceSheet(context, state),
      ),
      _SettingRow(
        title: 'Reading voice',
        subtitle: 'Speed of the verse read aloud',
        onTap: () => showVoiceSheet(context, state.activeDrop.verseText),
      ),
      if (AppFlags.instance.isOn(AppFlags.scripturePacks))
        _SettingRow(
          title: 'Offline scripture packs',
          subtitle: 'Weeks ready without signal',
          onTap: () => ScripturePacksSheet.show(context),
        ),
      _SettingRow(
        title: 'Account & export',
        subtitle: 'Your name · backup · export your journal',
        onTap: () => showAccountSheet(context, state),
      ),
      _SettingRow(
        title: 'About & privacy',
        subtitle: 'Privacy · terms · notices · erase data',
        onTap: () => showAboutSheet(context),
      ),
    ];
    return OCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i < rows.length - 1) Divider(height: 1, color: OC.divider),
          ],
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _SettingRow({required this.title, required this.subtitle, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: OT.label(size: 16)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: OT.small(alpha: 0.7)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            trailing ?? (onTap != null ? const OIcon(OI.next, size: 16) : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}
