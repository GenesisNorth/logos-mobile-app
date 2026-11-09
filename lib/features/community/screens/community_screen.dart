import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/logos_theme.dart';
import '../../../core/theme/logos_typography.dart';
import 'milestones_screen.dart';
import 'prayer_circles_screen.dart';
import 'study_pods_screen.dart';
import 'the_well_screen.dart';
import 'valley_screen.dart';
import 'voice_comfort_screen.dart';
import '../../../core/theme/logos_icons.dart';
import '../../../core/config/app_flags.dart';

class _Room {
  final String flag;
  final String title;
  final String description;
  final Color color;
  final LogosIconData icon;
  final WidgetBuilder builder;
  const _Room(this.flag, this.title, this.description, this.color, this.icon, this.builder);
}

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  static final List<_Room> _rooms = [
    _Room(AppFlags.roomPrayerCircles, 'Prayer Circles', 'Record a short spoken prayer. Voice prayers fade after 7 days.',
        LogosColors.prayerCircles, LogosIcons.recordVoiceOver, (_) => const PrayerCirclesScreen()),
    _Room(AppFlags.roomTheWell, 'The Well', 'Bring a private prayer request to our pastoral team.',
        LogosColors.theWell, LogosIcons.waterDrop, (_) => const TheWellScreen()),
    _Room(AppFlags.roomValley, 'In the Valley', 'Quiet rooms for grief, work stress and weariness, anchored in the Psalms.',
        LogosColors.valleyRooms, LogosIcons.terrain, (_) => const ValleyScreen()),
    _Room(AppFlags.roomStudyPods, 'Study Pods', 'Walk through the week’s verse with a small group.',
        LogosColors.studyPods, LogosIcons.menuBook, (_) => const StudyPodsScreen()),
    _Room(AppFlags.roomVoiceComfort, 'Voice Comfort', 'Hear Scripture read aloud by others.',
        LogosColors.voiceComfort, LogosIcons.hearing, (_) => const VoiceComfortScreen()),
    _Room(AppFlags.roomMilestones, 'Milestones', 'Celebrate spiritual birthdays and finished weeks.',
        const Color(0xFF6E6457), LogosIcons.cake, (_) => const MilestonesScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? LogosColors.examenInk : LogosColors.ink;
    final surface = isDark ? LogosColors.examenSurface : LogosColors.surface;

    return ListenableBuilder(
      listenable: AppFlags.instance,
      builder: (context, _) {
        final flags = AppFlags.instance;
        final rooms = _rooms.where((r) => flags.isOn(r.flag)).toList();
        return Scaffold(
          backgroundColor: isDark ? LogosColors.examenBg : LogosColors.sand,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
              children: [
                Text('Community', style: LogosTypography.headline(color: ink).copyWith(fontSize: 28)),
                const SizedBox(height: 4),
                Text(
                  'Pray with others and be prayed for.',
                  style: GoogleFonts.inter(fontSize: 14, color: ink.withValues(alpha: 0.65)),
                ),
                if (flags.isOn(AppFlags.streakFamily)) ...[
                  const SizedBox(height: 20),
                  Text('Streak Family', style: LogosTypography.label(color: ink)),
                  const SizedBox(height: 10),
                  _buildStreakFamilyRow(context, surface, ink),
                ],
                const SizedBox(height: 18),
                for (final room in rooms) ...[
                  _RoomCard(room: room, surface: surface, ink: ink),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStreakFamilyRow(BuildContext context, Color surface, Color ink) {
    final friends = [
      {'name': 'Sarah K.', 'streak': 12, 'initial': 'S'},
      {'name': 'David M.', 'streak': 28, 'initial': 'D'},
      {'name': 'Hannah L.', 'streak': 7, 'initial': 'H'},
      {'name': 'Grace E.', 'streak': 15, 'initial': 'G'},
      {'name': 'Elijah P.', 'streak': 4, 'initial': 'E'},
    ];

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: friends.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final f = friends[i];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MilestonesScreen()),
              );
            },
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: LogosColors.coral.withValues(alpha: 0.35),
                      child: Text(
                        f['initial'] as String,
                        style: TextStyle(fontWeight: FontWeight.bold, color: ink),
                      ),
                    ),
                    Positioned(
                      bottom: -2,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: LogosColors.coral,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const AppIcon(LogosIcons.localFireDepartment, size: 10, color: Colors.white),
                            Text(
                              '${f['streak']}',
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  f['name'] as String,
                  style: TextStyle(fontSize: 11, color: ink.withValues(alpha: 0.8)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final _Room room;
  final Color surface;
  final Color ink;
  const _RoomCard({required this.room, required this.surface, required this.ink});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: room.builder)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: LogosColors.taupe),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: room.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: AppIcon(room.icon, color: room.color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(room.title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: ink)),
                    const SizedBox(height: 3),
                    Text(room.description,
                        style: GoogleFonts.inter(fontSize: 13, height: 1.35, color: ink.withValues(alpha: 0.65))),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AppIcon(LogosIcons.chevronRight, size: 18, color: ink.withValues(alpha: 0.35)),
            ],
          ),
        ),
      ),
    );
  }
}
