import 'package:flutter/material.dart';
import '../../../core/config/app_flags.dart';
import '../../../core/design/components.dart';
import '../../../core/design/organic.dart';
import '../../today/today_sheets.dart';
import 'milestones_screen.dart';
import 'prayer_circles_screen.dart';
import 'study_pods_screen.dart';
import 'the_well_screen.dart';
import 'valley_screen.dart';
import 'voice_comfort_screen.dart';

class _Space {
  final String flag;
  final String title;
  final String subtitle;
  final List<List<dynamic>> icon;
  final Color bg;
  final Color ink;
  final Color iconBg;
  final Color iconFg;
  final WidgetBuilder builder;
  const _Space(this.flag, this.title, this.subtitle, this.icon, this.bg, this.ink, this.iconBg, this.iconFg, this.builder);
}

/// Community — sacred spaces for praying with others.
class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  static final _well = _Space(AppFlags.roomTheWell, 'The Well', 'Private prayer requests · pastoral care', OI.droplet,
      OC.s700, OC.s100, OC.s200, OC.s800, (_) => const TheWellScreen());

  static final _tiles = <_Space>[
    _Space(AppFlags.roomPrayerCircles, 'Prayer Circles', 'Voice prayers · fade in 7 days', OI.mic, OC.a200, OC.a900,
        OC.accent, OC.n100, (_) => const PrayerCirclesScreen()),
    _Space(AppFlags.roomStudyPods, 'Study Pods', 'Four pilgrims · one verse', OI.book, OC.n100, OC.text, OC.surface,
        OC.text, (_) => const StudyPodsScreen()),
    _Space(AppFlags.roomValley, 'In the Valley', 'Grief · Workplace · Weariness', OI.mountain, OC.n800, OC.n100, OC.n700,
        OC.n100, (_) => const ValleyScreen()),
    _Space(AppFlags.roomVoiceComfort, 'Voice Comfort', 'Hear the Word read', OI.wave, OC.s200, OC.s900, OC.s600, OC.n100,
        (_) => const VoiceComfortScreen()),
  ];

  static final _milestones = _Space(AppFlags.roomMilestones, 'Milestones', 'Spiritual birthdays — lift up your family',
      OI.bell, OC.surface, OC.text, OC.n100, OC.text, (_) => const MilestonesScreen());

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppFlags.instance,
      builder: (context, _) {
        final flags = AppFlags.instance;
        final tiles = _tiles.where((t) => flags.isOn(t.flag)).toList();
        final rows = <Widget>[];
        for (var i = 0; i < tiles.length; i += 2) {
          final pair = tiles.sublist(i, (i + 2).clamp(0, tiles.length));
          rows.add(Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: pair.length == 2
                ? IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _Tile(space: pair[0])),
                        const SizedBox(width: 12),
                        Expanded(child: _Tile(space: pair[1])),
                      ],
                    ),
                  )
                : _Tile(space: pair[0], wide: true),
          ));
        }

        return OScreen(
          atmosphere: Atmosphere.parchment,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 120),
            children: [
              Row(
                children: [
                  Expanded(child: Text('Community', style: OT.h1())),
                  OCircleButton(icon: OI.bell, tooltip: 'Liturgical hours', size: 48, onTap: () => showHoursSheet(context)),
                ],
              ),
              Text('Never pray alone.', style: OT.body(color: OC.text.withValues(alpha: 0.7))),
              const SizedBox(height: 22),
              Text('Sacred spaces', style: OT.label(size: 15)),
              const SizedBox(height: 12),
              if (flags.isOn(_well.flag)) ...[_WellCard(space: _well), const SizedBox(height: 12)],
              ...rows,
              if (flags.isOn(_milestones.flag)) _WideRow(space: _milestones),
            ],
          ),
        );
      },
    );
  }
}

void _open(BuildContext context, _Space s) => Navigator.of(context).push(MaterialPageRoute(builder: s.builder));

class _IconDisc extends StatelessWidget {
  final _Space space;
  final double size;
  const _IconDisc({required this.space, this.size = 48});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: space.iconBg, shape: BoxShape.circle),
        child: Center(child: OIcon(space.icon, size: size * 0.42, color: space.iconFg)),
      );
}

class _WellCard extends StatelessWidget {
  final _Space space;
  const _WellCard({required this.space});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${space.title}. ${space.subtitle}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => _open(context, space),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Container(
            height: 168,
            color: space.bg,
            child: Stack(
              children: [
                const Positioned.fill(
                  child: ODecor(big: OC.s600, small: Colors.transparent, bigSize: 200, bigOffset: Offset(-60, -40), smallSize: 0),
                ),
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _IconDisc(space: space),
                      const Spacer(),
                      Text(space.title, style: OT.display(30, color: space.ink)),
                      Text(space.subtitle, style: OT.small(color: space.ink, alpha: 0.85)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final _Space space;
  final bool wide;
  const _Tile({required this.space, this.wide = false});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${space.title}. ${space.subtitle}',
      excludeSemantics: true,
      child: OCard(
        color: space.bg,
        radius: 28,
        padding: const EdgeInsets.all(18),
        onTap: () => _open(context, space),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: wide ? 0 : 150),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _IconDisc(space: space, size: 44),
              SizedBox(height: wide ? 18 : 26),
              Text(space.title, style: OT.display(21, color: space.ink, height: 1.1)),
              const SizedBox(height: 4),
              Text(space.subtitle, style: OT.small(color: space.ink, alpha: 0.8)),
            ],
          ),
        ),
      ),
    );
  }
}

class _WideRow extends StatelessWidget {
  final _Space space;
  const _WideRow({required this.space});

  @override
  Widget build(BuildContext context) {
    return OCard(
      color: space.bg,
      radius: 28,
      padding: const EdgeInsets.all(16),
      onTap: () => _open(context, space),
      child: Row(
        children: [
          _IconDisc(space: space, size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(space.title, style: OT.display(21, color: space.ink)),
                Text(space.subtitle, style: OT.small(color: space.ink, alpha: 0.8)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
