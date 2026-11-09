import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/design/components.dart';
import '../../../core/design/organic.dart';
import '../../journey/bloc/journey_state.dart';

/// Day metadata from the design (name, length, hero title & body).
class DayInfo {
  final String name;
  final String minutes;
  final String title;
  final String body;
  const DayInfo(this.name, this.minutes, this.title, this.body);
}

const dayInfo = {
  1: DayInfo('Encounter', '5 min', 'Meet the verse', 'A short encounter, then speak it aloud.'),
  2: DayInfo('Roots', '6 min', 'Dwell in the roots', ''),
  3: DayInfo('Stillness', '1 min', 'Sit in stillness', 'Sixty seconds of paced breath beneath the Word.'),
  4: DayInfo('Exchange', '4 min', 'Lay down a burden', 'Write what you carry. Hold to let it go.'),
};

String _clean(String w) => w.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');

/// Index of the week's key word in [words] (first match of any stem), or -1.
int keyWordIndex(List<String> words, List<String> stems) {
  for (var i = 0; i < words.length; i++) {
    if (stems.contains(_clean(words[i]))) return i;
  }
  return -1;
}

/// The verse in display type with the week's key word in terracotta.
class VerseView extends StatelessWidget {
  final String text;
  final List<String> keyStems;
  final double size;
  final Color color;
  final Color keyColor;

  const VerseView({
    super.key,
    required this.text,
    required this.keyStems,
    this.size = 30,
    this.color = OC.text,
    this.keyColor = OC.accent,
  });

  @override
  Widget build(BuildContext context) {
    final words = text.split(' ');
    final k = keyWordIndex(words, keyStems);
    final base = OT.verse(size: size, color: color);
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(children: [
          for (var i = 0; i < words.length; i++)
            TextSpan(text: '${words[i]}${i < words.length - 1 ? ' ' : ''}', style: i == k ? base.copyWith(color: keyColor) : base),
        ]),
      ),
    );
  }
}

enum SeedState { done, today, upcoming, locked }

/// Four seed-circles linked by a living vine line.
class RhythmSeeds extends StatelessWidget {
  final JourneyState state;
  final ValueChanged<int> onTap;

  /// Debug builds only: long-press opens any day (for design/QA review).
  final ValueChanged<int>? onDebugOpen;
  const RhythmSeeds({super.key, required this.state, required this.onTap, this.onDebugOpen});

  SeedState stateOf(int d) {
    if (state.dayCompletionStatus[d] == true) return SeedState.done;
    final today = state.todayDay;
    if (d == today) return state.isDayUnlocked(d) ? SeedState.today : SeedState.locked;
    return d == today + 1 && state.isDayUnlocked(today) ? SeedState.upcoming : SeedState.locked;
  }

  String statusOf(int d, SeedState s) => switch (s) {
        SeedState.done => 'Done',
        SeedState.today => 'Today',
        SeedState.upcoming => 'Tomorrow',
        SeedState.locked => d == state.todayDay ? 'Tomorrow' : 'Later',
      };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 124,
      child: Stack(
        children: [
          const Positioned(left: 0, right: 0, top: 0, height: 72, child: CustomPaint(painter: _VinePainter())),
          Row(
            children: [
              for (var d = 1; d <= 4; d++)
                Expanded(
                  child: _Seed(
                    day: d,
                    seed: stateOf(d),
                    status: statusOf(d, stateOf(d)),
                    onTap: () => onTap(d),
                    onLongPress: kDebugMode && onDebugOpen != null ? () => onDebugOpen!(d) : null,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Seed extends StatelessWidget {
  final int day;
  final SeedState seed;
  final String status;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  const _Seed({required this.day, required this.seed, required this.status, required this.onTap, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    const size = 68.0;
    Widget circle;
    switch (seed) {
      case SeedState.done:
        circle = Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(color: OC.s500, shape: BoxShape.circle),
          child: const Center(child: OIcon(OI.check, size: 26, color: OC.n100)),
        );
      case SeedState.today:
        circle = Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: OC.accent,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: OC.a200.withValues(alpha: 0.9), spreadRadius: 6)],
          ),
          child: Center(child: Text('$day', style: OT.display(26, color: OC.n100))),
        );
      case SeedState.upcoming:
      case SeedState.locked:
        circle = Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(color: OC.bg, shape: BoxShape.circle),
          child: CustomPaint(
            painter: const DashedCirclePainter(color: OC.n400),
            child: Center(
              child: seed == SeedState.locked
                  ? const OIcon(OI.lock, size: 20, color: OC.n600)
                  : Text('$day', style: OT.display(24, color: OC.n600)),
            ),
          ),
        );
    }
    final isToday = seed == SeedState.today;
    return Semantics(
      button: true,
      label: 'Day $day, ${dayInfo[day]!.name}, $status',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        onLongPress: onLongPress,
        child: Column(
          children: [
            Padding(padding: const EdgeInsets.only(top: 2), child: circle),
            const SizedBox(height: 10),
            Text(dayInfo[day]!.name,
                style: OT.label(size: 14, color: isToday ? OC.a600 : OC.text), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(status, style: OT.body(size: 12, color: OC.text.withValues(alpha: 0.6), height: 1.3)),
          ],
        ),
      ),
    );
  }
}

/// The sage vine that winds between the seeds.
class _VinePainter extends CustomPainter {
  const _VinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = OC.s300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final step = size.width / 4;
    const y = 36.0;
    final path = Path()..moveTo(step / 2, y);
    for (var i = 0; i < 3; i++) {
      final x0 = step / 2 + i * step, x1 = x0 + step;
      final dir = i.isEven ? -1 : 1;
      path.cubicTo(x0 + step * 0.35, y + dir * 26, x1 - step * 0.35, y - dir * 26, x1, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Small stat tile (7 · day streak).
class StatTile extends StatelessWidget {
  final List<List<dynamic>> icon;
  final Color iconColor;
  final String value;
  final String label;
  const StatTile({super.key, required this.icon, required this.iconColor, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$value $label',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
        decoration: BoxDecoration(color: OC.n100, borderRadius: BorderRadius.circular(ORadius.card)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OIcon(icon, size: 20, color: iconColor),
            const SizedBox(height: 14),
            Text(value, style: OT.display(26)),
            const SizedBox(height: 4),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: OT.small(alpha: 0.7)),
          ],
        ),
      ),
    );
  }
}

/// Floating nav pill — three places: Today, Community, Altar.
class NavPill extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelect;
  const NavPill({super.key, required this.index, required this.onSelect});

  static const _items = [(OI.home, 'Today'), (OI.community, 'Community'), (OI.flame, 'Altar')];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: OC.n900, borderRadius: BorderRadius.circular(ORadius.pill), boxShadow: OShadow.lg),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < _items.length; i++)
            Semantics(
              key: Key('nav_tab_${_items[i].$2.toLowerCase()}'),
              button: true,
              selected: i == index,
              label: _items[i].$2,
              excludeSemantics: true,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelect(i);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  height: 52,
                  padding: EdgeInsets.symmetric(horizontal: i == index ? 20 : 16),
                  decoration: BoxDecoration(
                    color: i == index ? OC.n100 : Colors.transparent,
                    borderRadius: BorderRadius.circular(ORadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OIcon(_items[i].$1, size: 21, color: i == index ? OC.text : OC.n400),
                      if (i == index) ...[
                        const SizedBox(width: 8),
                        Text(_items[i].$2, style: OT.label(size: 15)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Hero card for today's step (ember), a finished week (sage) or rest (dusk).
class HeroCard extends StatelessWidget {
  final String kicker;
  final String title;
  final String body;
  final String? action;
  final List<List<dynamic>>? actionIcon;
  final VoidCallback? onAction;
  final Color bg;
  final Color ink;
  final Color decorBig;
  final Color decorSmall;
  final OButtonStyle actionStyle;

  const HeroCard({
    super.key,
    required this.kicker,
    required this.title,
    required this.body,
    this.action,
    this.actionIcon,
    this.onAction,
    this.bg = OC.a700,
    this.ink = OC.n100,
    this.decorBig = OC.a600,
    this.decorSmall = OC.a500,
    this.actionStyle = OButtonStyle.light,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Container(
        color: bg,
        child: Stack(
          children: [
            Positioned.fill(
              child: ODecor(big: decorBig, small: decorSmall, bigSize: 230, bigOffset: const Offset(-60, -40), smallOffset: const Offset(30, 40)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(kicker, style: OT.kicker(color: ink.withValues(alpha: 0.85))),
                  const SizedBox(height: 10),
                  Text(title, style: OT.display(30, color: ink, height: 1.08)),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(body, style: OT.body(size: 15, color: ink.withValues(alpha: 0.92))),
                  ],
                  if (action != null) ...[
                    const SizedBox(height: 18),
                    OButton(action!, onPressed: onAction, style: actionStyle, icon: actionIcon, expand: false, height: 50),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Greeting by local hour.
String greeting([DateTime? now]) {
  final h = (now ?? DateTime.now()).hour;
  if (h >= 5 && h < 12) return 'Good morning,';
  if (h >= 12 && h < 17) return 'Good afternoon,';
  return 'Good evening,';
}

double clamp01(double v) => math.max(0, math.min(1, v));
