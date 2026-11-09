import 'package:flutter/material.dart';
import '../../../core/design/components.dart';
import '../../../core/design/organic.dart';
import '../widgets/room_header.dart';

/// Milestones — spiritual celebrations in your streak family.
/// (Behind the `room_milestones` flag until friends sync with the cloud.)
class MilestonesScreen extends StatelessWidget {
  const MilestonesScreen({super.key});

  static const _people = [
    ('David M.', 'Completed Week 3 with zero skipped days'),
    ('Sarah K.', 'Crossed the 4-week threshold'),
    ('Grace E.', 'Spiritual birthday · 1 year in Christ'),
  ];

  @override
  Widget build(BuildContext context) {
    const atm = Atmosphere.parchment;
    return OScreen(
      atmosphere: atm,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 30),
        children: [
          const RoomHeader(atmosphere: atm, kicker: 'Community', title: 'Milestones', subtitle: 'Spiritual celebrations in your streak family.', kickerColor: OC.a700),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
            child: Column(
              children: [
                OCard(
                  color: OC.surface,
                  radius: 28,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('No vanity metrics.', style: OT.display(22)),
                      const SizedBox(height: 6),
                      Text('No likes, no leaderboards — only reasons to celebrate and pray for one another.', style: OT.small(alpha: 0.8)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                for (final p in _people) ...[
                  OCard(
                    radius: 26,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        OAvatar.auto(p.$1, size: 48),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [Text(p.$1, style: OT.label(size: 16)), Text(p.$2, style: OT.small(alpha: 0.75))],
                          ),
                        ),
                        OButton('Gentle ping', style: OButtonStyle.outline, outlineColor: OC.a600, expand: false, height: 40, onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${p.$1} will know you’re praying.')));
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
