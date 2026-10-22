import 'package:flutter/material.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/theme/logos_theme.dart';
import '../../../core/theme/logos_typography.dart';

class MilestonesScreen extends StatefulWidget {
  const MilestonesScreen({super.key});

  @override
  State<MilestonesScreen> createState() => _MilestonesScreenState();
}

class _MilestonesScreenState extends State<MilestonesScreen> {
  final Map<String, DateTime> _lastPinged = {};

  final List<Map<String, dynamic>> _friends = [
    {
      'name': 'Sarah K.',
      'streak': 12,
      'roots': 3,
      'milestone': 'Completed Week 3 with zero skipped days',
      'birthday': 'Nov 14',
    },
    {
      'name': 'David M.',
      'streak': 28,
      'roots': 7,
      'milestone': 'Crossed 4-week Master threshold',
      'birthday': 'Oct 29',
    },
    {
      'name': 'Hannah L.',
      'streak': 7,
      'roots': 2,
      'milestone': 'Spiritual Birthday (1 Year in Christ)',
      'birthday': 'Today 🎉',
    },
  ];

  void _sendGentlePing(String friendName) {
    final now = DateTime.now();
    final lastTime = _lastPinged[friendName];

    if (lastTime != null && now.difference(lastTime).inHours < 4) {
      final hoursLeft = 4 - now.difference(lastTime).inHours;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gentle Ping cooldown active. You can ping $friendName again in $hoursLeft hours.'),
        ),
      );
      return;
    }

    _lastPinged[friendName] = now;
    AudioService().playSanctuaryChime();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Gentle Ping "Standing with you in the Word" sent to $friendName.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? LogosColors.examenInk : LogosColors.ink;
    final surface = isDark ? LogosColors.examenSurface : LogosColors.surface;

    return Scaffold(
      backgroundColor: isDark ? LogosColors.examenBg : LogosColors.sand,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text('Milestones & Family', style: TextStyle(color: Color(0xFF6E6457), fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Spiritual Celebrations', style: LogosTypography.caption(color: ink.withValues(alpha: 0.6))),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF6E6457),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'No Vanity Metrics.',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'In LOGOS IN ME, we do not celebrate followers or social clout. We celebrate roots sunk deep into Jesus and persistent obedience.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text('Streak Family Milestones', style: LogosTypography.label(color: ink)),
            const SizedBox(height: 10),

            ..._friends.map((f) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: LogosColors.taupe),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: LogosColors.coral.withValues(alpha: 0.25),
                              child: Text(
                                (f['name'] as String)[0],
                                style: TextStyle(fontWeight: FontWeight.bold, color: ink),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(f['name'] as String, style: LogosTypography.label(color: ink)),
                                Text('Birthday: ${f['birthday']}', style: LogosTypography.caption(color: ink.withValues(alpha: 0.5))),
                              ],
                            ),
                          ],
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: LogosColors.coral),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                          icon: const Icon(Icons.notifications_active, size: 14, color: LogosColors.coral),
                          label: const Text('Gentle Ping', style: TextStyle(fontSize: 11, color: LogosColors.coral)),
                          onPressed: () => _sendGentlePing(f['name'] as String),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ink.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified, size: 18, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              f['milestone'] as String,
                              style: LogosTypography.body(color: ink.withValues(alpha: 0.85)).copyWith(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text('🔥 ${f['streak']} Days', style: LogosTypography.caption(color: ink.withValues(alpha: 0.7))),
                        const SizedBox(width: 14),
                        Text('🌱 ${f['roots']} Roots Planted', style: LogosTypography.caption(color: ink.withValues(alpha: 0.7))),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
