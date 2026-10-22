import 'package:flutter/material.dart';
import '../../../core/theme/logos_theme.dart';
import '../../../core/theme/logos_typography.dart';

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
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('No unread pings or notifications.')),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Search & Ping bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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

                    const SizedBox(height: 20),

                    // Streak Family section
                    Text(
                      'Streak Family',
                      style: LogosTypography.label(color: ink),
                    ),
                    const SizedBox(height: 10),
                    _buildStreakFamilyRow(surface, ink),

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
                    onTap: () => _showModuleDetail(
                      context,
                      'Study Pods',
                      'Small intimate groups of 4-6 members matched by timezone. Study Scripture drops together with weekly guided discussion questions.',
                    ),
                  ),
                  _buildModuleCard(
                    context,
                    title: 'Prayer Circles',
                    subtitle: '3 new voice notes\n7-day ephemeral prayers',
                    color: LogosColors.prayerCircles,
                    icon: Icons.record_voice_over,
                    onTap: () => _showModuleDetail(
                      context,
                      'Prayer Circles',
                      'Share audio voice prayers (up to 120 seconds). In keeping with digital sanctification, all voice notes automatically purge after 7 days.',
                    ),
                  ),
                  _buildModuleCard(
                    context,
                    title: 'In the Valley',
                    subtitle: 'Grief · Workplace · Digital\nThemed quiet sanctuaries',
                    color: LogosColors.valleyRooms,
                    icon: Icons.terrain,
                    onTap: () => _showModuleDetail(
                      context,
                      'In the Valley',
                      'Quiet rooms for specific seasons of suffering and contemplation. Moderated gently to preserve peace and vulnerability without algorithmic noise.',
                    ),
                  ),
                  _buildModuleCard(
                    context,
                    title: 'Voice Comfort',
                    subtitle: 'Hear the Word read\nBeloved voices worldwide',
                    color: LogosColors.voiceComfort,
                    icon: Icons.hearing,
                    onTap: () => _showModuleDetail(
                      context,
                      'Voice Comfort Library',
                      'Listen to approved audio recitations of the weekly Scripture from believers navigating anxiety, gratitude, or sleeplessness.',
                    ),
                  ),
                  _buildModuleCard(
                    context,
                    title: 'The Well',
                    subtitle: 'Pastoral Care & Prayer\nGuaranteed 4h reply',
                    color: LogosColors.theWell,
                    icon: Icons.water_drop,
                    onTap: () => _showModuleDetail(
                      context,
                      'The Well (Pastoral Care)',
                      'Submit a confidential prayer request to ordained pastors. We commit to a heartfelt written or voice pastoral response within 4 hours.',
                    ),
                  ),
                  _buildModuleCard(
                    context,
                    title: 'Milestones',
                    subtitle: 'Birthdays & Roots\nLift up your family',
                    color: const Color(0xFF6E6457),
                    icon: Icons.cake,
                    onTap: () => _showModuleDetail(
                      context,
                      'Milestones & Birthdays',
                      'Celebrate spiritual anniversaries, completed 4-day loops, and send gentle encouragement pings without social media vanity metrics.',
                    ),
                  ),
                ],
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakFamilyRow(Color surface, Color ink) {
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
          return Column(
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

  void _showModuleDetail(BuildContext context, String title, String body) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: LogosTypography.headline(color: LogosColors.ink)),
            const SizedBox(height: 12),
            Text(body, style: LogosTypography.body(color: LogosColors.ink.withValues(alpha: 0.85))),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: LogosColors.coral),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Enter Sanctuary Space', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
