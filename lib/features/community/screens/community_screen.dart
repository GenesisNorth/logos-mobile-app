import 'package:flutter/material.dart';
import '../../../core/theme/logos_theme.dart';
import '../../../core/theme/logos_typography.dart';
import 'milestones_screen.dart';
import 'prayer_circles_screen.dart';
import 'study_pods_screen.dart';
import 'the_well_screen.dart';
import 'valley_screen.dart';
import 'voice_comfort_screen.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? LogosColors.examenInk : LogosColors.ink;
    final surface = isDark ? LogosColors.examenSurface : LogosColors.surface;

    return Scaffold(
      backgroundColor: isDark ? LogosColors.examenBg : LogosColors.sand,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Community',
                          style: LogosTypography.headline(color: ink).copyWith(fontSize: 28),
                        ),
                        IconButton(
                          icon: Icon(Icons.notifications_none, color: ink),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const MilestonesScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Search & Ping bar
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MilestonesScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: LogosColors.taupe),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, size: 20, color: ink.withValues(alpha: 0.5)),
                            const SizedBox(width: 8),
                            Text(
                              'Search friends & ping...',
                              style: LogosTypography.body(color: ink.withValues(alpha: 0.5)),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Streak Family section
                    Text(
                      'Streak Family',
                      style: LogosTypography.label(color: ink),
                    ),
                    const SizedBox(height: 10),
                    _buildStreakFamilyRow(context, surface, ink),

                    const SizedBox(height: 24),

                    Text(
                      'Sacred Spaces',
                      style: LogosTypography.label(color: ink),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // 2-Column Grid of Modules
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              sliver: SliverGrid.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.88,
                children: [
                  _buildModuleCard(
                    context,
                    title: 'Study Pods',
                    subtitle: '4 members · Thu 8pm\nFocused peer exegesis',
                    color: LogosColors.studyPods,
                    icon: Icons.menu_book,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StudyPodsScreen()),
                    ),
                  ),
                  _buildModuleCard(
                    context,
                    title: 'Prayer Circles',
                    subtitle: '3 new voice notes\n7-day ephemeral prayers',
                    color: LogosColors.prayerCircles,
                    icon: Icons.record_voice_over,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PrayerCirclesScreen()),
                    ),
                  ),
                  _buildModuleCard(
                    context,
                    title: 'In the Valley',
                    subtitle: 'Grief · Workplace · Digital\nThemed quiet sanctuaries',
                    color: LogosColors.valleyRooms,
                    icon: Icons.terrain,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ValleyScreen()),
                    ),
                  ),
                  _buildModuleCard(
                    context,
                    title: 'Voice Comfort',
                    subtitle: 'Hear the Word read\nBeloved voices worldwide',
                    color: LogosColors.voiceComfort,
                    icon: Icons.hearing,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const VoiceComfortScreen()),
                    ),
                  ),
                  _buildModuleCard(
                    context,
                    title: 'The Well',
                    subtitle: 'Pastoral Care & Prayer\nGuaranteed 4h reply',
                    color: LogosColors.theWell,
                    icon: Icons.water_drop,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TheWellScreen()),
                    ),
                  ),
                  _buildModuleCard(
                    context,
                    title: 'Milestones',
                    subtitle: 'Birthdays & Roots\nLift up your family',
                    color: const Color(0xFF6E6457),
                    icon: Icons.cake,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MilestonesScreen()),
                    ),
                  ),
                ],
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
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
                            const Icon(Icons.local_fire_department, size: 10, color: Colors.white),
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

  Widget _buildModuleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const Icon(Icons.arrow_forward_ios, color: Colors.white60, size: 12),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
