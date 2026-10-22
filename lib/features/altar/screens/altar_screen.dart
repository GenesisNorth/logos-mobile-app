import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/logos_theme.dart';
import '../../../core/theme/logos_typography.dart';
import '../../examen/controllers/examen_controller.dart';
import '../../journey/bloc/journey_bloc.dart';
import '../../journey/bloc/journey_event.dart';
import '../../journey/bloc/journey_state.dart';
import '../../journey/data/progress_repository.dart';

class AltarScreen extends StatelessWidget {
  final ExamenController examenController;
  const AltarScreen({super.key, required this.examenController});

  void _showRedeemGraceDialog(BuildContext context, JourneyState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Redeem Grace Token'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You have ${state.graceTokensBalance} Grace Tokens remaining.\n\nGrace Tokens embody biblical grace: if life, illness, or fatigue interrupted your sacred rhythm, redeem a token to unlock the missed day and preserve your streak without shame.',
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select day to restore:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(4, (index) {
                final day = index + 1;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LogosColors.coral,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () {
                        context.read<JourneyBloc>().add(RedeemGraceToken(dayToRecover: day));
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Day $day restored through Grace Token!')),
                        );
                      },
                      child: Text('Day $day', style: const TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? LogosColors.examenInk : LogosColors.ink;
    final surface = isDark ? LogosColors.examenSurface : LogosColors.surface;

    return BlocBuilder<JourneyBloc, JourneyState>(
      builder: (context, state) {
        final profile = state.profile;
        final signedDate = profile.covenantSignedAt;
        final dateStr = signedDate != null
            ? '${signedDate.day}/${signedDate.month}/${signedDate.year}'
            : '22/10/2026';

        return Scaffold(
          backgroundColor: isDark ? LogosColors.examenBg : LogosColors.sand,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Prayer Altar & Covenant',
                    style: LogosTypography.headline(color: ink).copyWith(fontSize: 26),
                  ),
                  const SizedBox(height: 16),

                  // User Profile & Covenant Plaque
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: LogosColors.taupe),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: LogosColors.coral.withValues(alpha: 0.3),
                              child: Text(
                                profile.displayName.isNotEmpty
                                    ? profile.displayName[0]
                                    : 'P',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: ink,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profile.displayName,
                                    style: LogosTypography.headline(color: ink).copyWith(fontSize: 18),
                                  ),
                                  Text(
                                    '@${profile.username}',
                                    style: LogosTypography.caption(color: ink.withValues(alpha: 0.6)),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.verified_user, size: 14, color: Colors.green),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Covenant Sealed',
                                    style: TextStyle(
                                      color: Colors.green.shade900,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Divider(color: LogosColors.taupe.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Signed on $dateStr',
                              style: LogosTypography.caption(color: ink.withValues(alpha: 0.7)),
                            ),
                            Text(
                              'SHA-256 Verified',
                              style: LogosTypography.caption(color: LogosColors.coral),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Metrics Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          icon: Icons.local_fire_department,
                          iconColor: LogosColors.coral,
                          label: 'Daily Streak',
                          value: '${state.currentStreak} Days',
                          surface: surface,
                          ink: ink,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricTile(
                          icon: Icons.eco,
                          iconColor: const Color(0xFF10B981),
                          label: 'Roots Planted',
                          value: '${state.rootsPlanted} Verses',
                          surface: surface,
                          ink: ink,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Grace Tokens Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.shield, color: Colors.amber.shade700, size: 28),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${state.graceTokensBalance} Grace Tokens Available',
                                style: LogosTypography.label(color: ink),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Redeem to recover a missed day or preserve your streak.',
                                style: LogosTypography.caption(color: ink.withValues(alpha: 0.6)),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => _showRedeemGraceDialog(context, state),
                          child: const Text('Redeem'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Saved Tear Sheets Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Saved Tear Sheets',
                        style: LogosTypography.label(color: ink),
                      ),
                      Text(
                        '${state.savedTearSheets.length} Dissolved',
                        style: LogosTypography.caption(color: ink.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (state.savedTearSheets.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: LogosColors.taupe),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.layers_clear, size: 36, color: ink.withValues(alpha: 0.3)),
                          const SizedBox(height: 10),
                          Text(
                            'No Tear Sheets yet',
                            style: LogosTypography.label(color: ink),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Complete Day 4 (The Exchange) to lay down your first burden and save a permanent Tear Sheet.',
                            textAlign: TextAlign.center,
                            style: LogosTypography.caption(color: ink.withValues(alpha: 0.6)),
                          ),
                        ],
                      ),
                    )
                  else
                    ...state.savedTearSheets.map((sheet) => _buildTearSheetCard(sheet, surface, ink)),

                  const SizedBox(height: 24),

                  // Circadian Contemplation Settings Tile
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: LogosColors.taupe),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.bedtime_outlined, color: LogosColors.coral),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Examen Contemplation Mode', style: LogosTypography.label(color: ink)),
                                Text('Active 8:00 PM – 5:00 AM', style: LogosTypography.caption(color: ink.withValues(alpha: 0.6))),
                              ],
                            ),
                          ],
                        ),
                        Switch(
                          value: examenController.isExamenMode,
                          activeThumbColor: LogosColors.coral,
                          onChanged: (_) => examenController.toggleExamenPreview(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color surface,
    required Color ink,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LogosColors.taupe),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 10),
          Text(value, style: LogosTypography.headline(color: ink).copyWith(fontSize: 18)),
          Text(label, style: LogosTypography.caption(color: ink.withValues(alpha: 0.6))),
        ],
      ),
    );
  }

  Widget _buildTearSheetCard(TearSheetData sheet, Color surface, Color ink) {
    final d = sheet.completedAt;
    final dateStr = '${d.day}/${d.month}/${d.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
              Text('TEAR SHEET · $dateStr', style: LogosTypography.caption(color: LogosColors.coral)),
              IconButton(
                icon: const Icon(Icons.share, size: 18, color: LogosColors.coral),
                onPressed: () {
                  SharePlus.instance.share(ShareParams(text: '✝ THE EXCHANGE · ${sheet.reference}\n"${sheet.verseText}"\n\nA burden was laid down here on $dateStr.\nLOGOS IN ME'));
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '"${sheet.verseText}"',
            style: LogosTypography.scriptureBody(color: ink).copyWith(fontSize: 15),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              sheet.reference,
              style: LogosTypography.caption(color: ink.withValues(alpha: 0.7)),
            ),
          ),
        ],
      ),
    );
  }
}
