import 'package:flutter/material.dart';
import '../../../core/design/components.dart';
import '../../../core/design/organic.dart';

/// Back · KICKER  then the room's display title and a one-line promise.
class RoomHeader extends StatelessWidget {
  final Atmosphere atmosphere;
  final String kicker;
  final String title;
  final String subtitle;
  final Color? kickerColor;
  final Widget? trailing;

  const RoomHeader({
    super.key,
    required this.atmosphere,
    required this.kicker,
    required this.title,
    required this.subtitle,
    this.kickerColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final ink = atmosphere.ink;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OTopBar(kicker: kicker, atmosphere: atmosphere, back: true, kickerColor: kickerColor, trailing: trailing),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: OT.display(40, color: ink, height: 1.05)),
              const SizedBox(height: 6),
              Text(subtitle, style: OT.body(size: 15, color: ink.withValues(alpha: 0.75))),
            ],
          ),
        ),
      ],
    );
  }
}
