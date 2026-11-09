import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/logos_icons.dart';
import '../../../core/theme/logos_theme.dart';
import '../../../core/theme/logos_typography.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/logos_dialog.dart';
import '../../examen/controllers/examen_controller.dart';
import '../../journey/bloc/journey_bloc.dart';
import '../../journey/bloc/journey_event.dart';
import '../../journey/bloc/journey_state.dart';
import '../../journey/data/progress_repository.dart';
import '../../settings/settings_screen.dart';

/// The pilgrim's progress: covenant, streak, verses planted, grace and Tear Sheets.
/// Preferences and account live in [SettingsScreen] (gear icon).
class AltarScreen extends StatelessWidget {
  final ExamenController examenController;
  const AltarScreen({super.key, required this.examenController});

  Future<void> _useGraceToken(BuildContext context, JourneyState state) async {
    final streak = state.currentStreak;
    final used = await showLogosDialog<bool>(
      context,
      title: 'Keep your $streak-day streak?',
      message:
          'Life happens. A grace token covers the day you missed so your streak continues when you practise today. '
          'You have ${state.graceTokensBalance} left; finishing a full week earns one back.',
      confirmLabel: 'Use a grace token',
      onConfirm: () => true,
    );
    if (used == true && context.mounted) {
      context.read<JourneyBloc>().add(const RedeemGraceToken());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grace received. Practise today to continue your streak.')),
      );
    }
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
        final streak = state.activeStreak();
        final initial = profile.displayName.isNotEmpty ? profile.displayName[0].toUpperCase() : 'P';

        return Scaffold(
          backgroundColor: isDark ? LogosColors.examenBg : LogosColors.sand,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Prayer Altar',
                          style: LogosTypography.headline(color: ink).copyWith(fontSize: 26)),
                    ),
                    IconButton(
                      tooltip: 'Settings',
                      icon: AppIcon(LogosIcons.settings, color: ink, size: 24),
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => SettingsScreen(examenController: examenController),
                      )),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Profile & covenant
                _Card(
                  surface: surface,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: LogosColors.coral.withValues(alpha: 0.25),
                        child: Text(initial,
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ink)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(profile.displayName,
                                style: LogosTypography.headline(color: ink).copyWith(fontSize: 18)),
                            const SizedBox(height: 2),
                            Text(
                              signedDate != null
                                  ? 'Covenant signed ${formatLogosDate(signedDate)}'
                                  : 'Covenant not yet signed',
                              style: GoogleFonts.inter(fontSize: 13, color: ink.withValues(alpha: 0.65)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Progress
                Row(
                  children: [
                    Expanded(
                      child: _Metric(
                        icon: LogosIcons.localFireDepartment,
                        iconColor: LogosColors.coral,
                        value: '$streak ${streak == 1 ? 'day' : 'days'}',
                        label: 'Current streak',
                        surface: surface,
                        ink: ink,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Metric(
                        icon: LogosIcons.eco,
                        iconColor: const Color(0xFF10B981),
                        value: '${state.rootsPlanted} ${state.rootsPlanted == 1 ? 'verse' : 'verses'}',
                        label: 'Planted by heart',
                        surface: surface,
                        ink: ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                _GraceCard(
                  state: state,
                  surface: surface,
                  ink: ink,
                  onUse: () => _useGraceToken(context, state),
                ),
                const SizedBox(height: 24),

                // Tear Sheets
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tear Sheets', style: LogosTypography.label(color: ink)),
                    if (state.savedTearSheets.isNotEmpty)
                      Text('${state.savedTearSheets.length} laid down',
                          style: GoogleFonts.inter(fontSize: 13, color: ink.withValues(alpha: 0.55))),
                  ],
                ),
                const SizedBox(height: 10),
                if (state.savedTearSheets.isEmpty)
                  _Card(
                    surface: surface,
                    child: Column(
                      children: [
                        AppIcon(LogosIcons.quill, size: 34, color: LogosColors.coral.withValues(alpha: 0.6)),
                        const SizedBox(height: 10),
                        Text('No Tear Sheets yet', style: LogosTypography.label(color: ink)),
                        const SizedBox(height: 4),
                        Text(
                          'On Day 4 (The Exchange) you lay a burden down at the cross. Each one is kept here as a Tear Sheet.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 13, height: 1.4, color: ink.withValues(alpha: 0.65)),
                        ),
                      ],
                    ),
                  )
                else
                  ...state.savedTearSheets.reversed.map((sheet) => _TearSheetCard(sheet: sheet, surface: surface, ink: ink)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final Color surface;
  final Color? border;
  const _Card({required this.child, required this.surface, this.border});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border ?? LogosColors.taupe),
      ),
      child: child,
    );
  }
}

class _Metric extends StatelessWidget {
  final LogosIconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final Color surface;
  final Color ink;

  const _Metric({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.surface,
    required this.ink,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: _Card(
        surface: surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIcon(icon, color: iconColor, size: 24),
            const SizedBox(height: 10),
            Text(value, style: LogosTypography.headline(color: ink).copyWith(fontSize: 19)),
            Text(label, style: GoogleFonts.inter(fontSize: 13, color: ink.withValues(alpha: 0.6))),
          ],
        ),
      ),
    );
  }
}

/// Grace explains itself in each state: can rescue a streak now, is standing
/// by, or is used up (with how to earn one back).
class _GraceCard extends StatelessWidget {
  final JourneyState state;
  final Color surface;
  final Color ink;
  final VoidCallback onUse;

  const _GraceCard({required this.state, required this.surface, required this.ink, required this.onUse});

  @override
  Widget build(BuildContext context) {
    final tokens = state.graceTokensBalance;
    final canRescue = tokens > 0 && state.isStreakRecoverable();

    final String title;
    final String body;
    if (canRescue) {
      title = 'You missed yesterday';
      body = 'Use a grace token to keep your ${state.currentStreak}-day streak.';
    } else if (tokens > 0) {
      title = '$tokens grace ${tokens == 1 ? 'token' : 'tokens'} standing by';
      body = 'If you miss a day, one can keep your streak going.';
    } else {
      title = 'No grace tokens right now';
      body = 'Finish a full week’s rhythm to earn one back.';
    }

    return _Card(
      surface: surface,
      border: canRescue ? Colors.amber.shade400 : null,
      child: Row(
        children: [
          AppIcon(LogosIcons.shield,
              color: tokens > 0 ? Colors.amber.shade700 : ink.withValues(alpha: 0.35), size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: LogosTypography.label(color: ink)),
                const SizedBox(height: 2),
                Text(body, style: GoogleFonts.inter(fontSize: 13, height: 1.35, color: ink.withValues(alpha: 0.65))),
              ],
            ),
          ),
          if (canRescue) TextButton(onPressed: onUse, child: const Text('Use')),
        ],
      ),
    );
  }
}

class _TearSheetCard extends StatelessWidget {
  final TearSheetData sheet;
  final Color surface;
  final Color ink;
  const _TearSheetCard({required this.sheet, required this.surface, required this.ink});

  @override
  Widget build(BuildContext context) {
    final dateStr = formatLogosDate(sheet.completedAt);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _Card(
        surface: surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('TEAR SHEET · $dateStr',
                      style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: LogosColors.coral)),
                ),
                IconButton(
                  tooltip: 'Share Tear Sheet',
                  icon: const AppIcon(LogosIcons.share, size: 18, color: LogosColors.coral),
                  onPressed: () => SharePlus.instance.share(ShareParams(
                    text: 'THE EXCHANGE · ${sheet.reference}\n“${sheet.verseText}”\n\nA burden was laid down at the cross on $dateStr.\n— LOGOS IN ME',
                  )),
                ),
              ],
            ),
            Text('“${sheet.verseText}”', style: LogosTypography.scriptureBody(color: ink).copyWith(fontSize: 15)),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(sheet.reference, style: GoogleFonts.inter(fontSize: 13, color: ink.withValues(alpha: 0.7))),
            ),
          ],
        ),
      ),
    );
  }
}
