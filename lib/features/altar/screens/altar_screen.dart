import 'package:flutter/material.dart';
import '../../../core/utils/date_format.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/logos_theme.dart';
import '../../../core/theme/logos_typography.dart';
import '../../../core/theme/logos_icons.dart';
import '../../examen/controllers/examen_controller.dart';
import '../../journey/bloc/journey_bloc.dart';
import '../../journey/bloc/journey_event.dart';
import '../../journey/bloc/journey_state.dart';
import '../../journey/data/progress_repository.dart';
import '../../journey/screens/scripture_packs_sheet.dart';
import '../../journey/screens/liturgical_widget_preview_sheet.dart';

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

  void _exportSpiritualJournal(BuildContext context, JourneyState state) {
    AudioService().selectionTick();
    final profile = state.profile;
    final buffer = StringBuffer();
    buffer.writeln('✝ LOGOS IN ME · PILGRIM RELIC JOURNAL');
    buffer.writeln('========================================');
    buffer.writeln('Pilgrim: ${profile.displayName} (@${profile.username})');
    buffer.writeln('Active Streak: ${state.activeStreak()} ${state.activeStreak() == 1 ? 'Day' : 'Days'}');
    buffer.writeln('Roots Planted: ${state.rootsPlanted} Verses');
    buffer.writeln('Grace Tokens Balance: ${state.graceTokensBalance}');
    if (profile.covenantSignature != null) {
      buffer.writeln('Covenant Signature: "${profile.covenantSignature}"');
      buffer.writeln('Covenant Signed At: ${profile.covenantSignedAt ?? DateTime.now()}');
    }
    buffer.writeln('Cloister UUID: ${SupabaseService.instance.currentUserId ?? "Offline Local Cloister"}');
    buffer.writeln('\n----------------------------------------');
    buffer.writeln('SACRED EXCHANGE TEAR SHEETS (${state.savedTearSheets.length} Dissolved):');
    buffer.writeln('----------------------------------------');
    if (state.savedTearSheets.isEmpty) {
      buffer.writeln('No tear sheets yet recorded.');
    } else {
      for (final sheet in state.savedTearSheets) {
        buffer.writeln('\n• ${sheet.reference} · Dissolved on ${sheet.completedAt.day}/${sheet.completedAt.month}/${sheet.completedAt.year}');
        buffer.writeln('  "${sheet.verseText}"');
        buffer.writeln('  Burden: A heavy burden was surrendered at the Cross.');
      }
    }
    buffer.writeln('\n========================================');
    buffer.writeln('Preserved in LOGOS IN ME · Soli Deo Gloria');

    SharePlus.instance.share(ShareParams(
      text: buffer.toString(),
      subject: 'LOGOS IN ME — Spiritual Relic Journal & Covenant',
    ));
  }

  void _showAccountSyncDialog(BuildContext context, JourneyState state) {
    AudioService().selectionTick();
    final emailController = TextEditingController(text: SupabaseService.instance.currentEmail ?? '');
    final passController = TextEditingController();
    final isCloudConfigured = SupabaseService.instance.isConfigured;
    final isAnon = SupabaseService.instance.isAnonymous;
    final userId = SupabaseService.instance.currentUserId ?? 'Local Pilgrim Session';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            final surface = isDark ? LogosColors.examenSurface : Colors.white;
            final ink = isDark ? LogosColors.examenInk : LogosColors.ink;

            return Container(
              padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 34),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                border: Border.all(color: LogosColors.taupe),
                boxShadow: LogosColors.softShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: ink.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: LogosColors.coral.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const AppIcon(LogosIcons.shieldRounded, color: LogosColors.coral, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cloud Account & Recovery',
                              style: LogosTypography.headline(color: ink).copyWith(fontSize: 17),
                            ),
                            Text(
                              'Protect streaks & tear sheets across devices',
                              style: LogosTypography.caption(color: ink.withValues(alpha: 0.6)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Status Plaque
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isCloudConfigured
                          ? const Color(0xFF10B981).withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isCloudConfigured
                            ? const Color(0xFF10B981).withValues(alpha: 0.3)
                            : Colors.orange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        AppIcon(
                          isCloudConfigured ? LogosIcons.verifiedRounded : LogosIcons.lockOutlineRounded,
                          color: isCloudConfigured ? const Color(0xFF10B981) : Colors.orange.shade800,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isCloudConfigured ? 'Supabase Cloud Sync Active' : 'Offline Cloister Mode Active',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isCloudConfigured ? const Color(0xFF0F5132) : Colors.orange.shade900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'UUID: ${userId.length > 20 ? "${userId.substring(0, 20)}..." : userId}',
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  color: isCloudConfigured ? const Color(0xFF0F5132) : Colors.orange.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text('Link Email to Anonymous Session:', style: LogosTypography.label(color: ink)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      hintText: 'pilgrim@logos.app',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password (Minimum 6 characters)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LogosColors.coral,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const AppIcon(LogosIcons.verifiedUser, size: 18),
                      label: Text(
                        isAnon ? 'Link Account & Preserve Streak' : 'Account Linked',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        final email = emailController.text.trim();
                        final pass = passController.text.trim();
                        if (email.isEmpty || pass.length < 6) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Please enter a valid email and 6+ character password.')),
                          );
                          return;
                        }
                        final ok = await SupabaseService.instance.linkWithEmail(email: email, password: pass);
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: ok ? const Color(0xFF10B981) : Colors.orange.shade800,
                              content: Text(ok
                                  ? 'Account successfully linked to $email! Streaks & grace preserved.'
                                  : 'Saved to local cloister profile. Cloud sync will push when online.'),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
        final dateStr = signedDate != null ? formatLogosDate(signedDate) : null;

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
                                  const AppIcon(LogosIcons.verifiedUser, size: 14, color: Colors.green),
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
                            Flexible(
                              child: Text(
                                dateStr != null ? 'Signed on $dateStr' : 'Covenant not yet signed',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: LogosTypography.caption(color: ink.withValues(alpha: 0.7)),
                              ),
                            ),
                            if (profile.covenantSignature != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                'SHA-256 Verified',
                                style: LogosTypography.caption(color: LogosColors.coral),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Quick Actions: Cloud Recovery & Relic Export
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ink,
                            side: const BorderSide(color: LogosColors.taupe),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const AppIcon(LogosIcons.shieldRounded, size: 16, color: LogosColors.coral),
                          label: Text(
                            'Cloud Recovery',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          onPressed: () => _showAccountSyncDialog(context, state),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ink,
                            side: const BorderSide(color: LogosColors.taupe),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const AppIcon(LogosIcons.share, size: 16, color: LogosColors.coral),
                          label: Text(
                            'Export Relics',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          onPressed: () => _exportSpiritualJournal(context, state),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Metrics Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          icon: LogosIcons.localFireDepartment,
                          iconColor: LogosColors.coral,
                          label: 'Daily Streak',
                          value: '${state.activeStreak()} ${state.activeStreak() == 1 ? 'Day' : 'Days'}',
                          surface: surface,
                          ink: ink,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricTile(
                          icon: LogosIcons.eco,
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
                        AppIcon(LogosIcons.shield, color: Colors.amber.shade700, size: 28),
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
                          AppIcon(LogosIcons.layersClear, size: 36, color: ink.withValues(alpha: 0.3)),
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
                        Expanded(
                          child: Row(
                            children: [
                              const AppIcon(LogosIcons.bedtimeOutlined, color: LogosColors.coral),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Examen Contemplation Mode', style: LogosTypography.label(color: ink)),
                                    Text('Active 8:00 PM – 5:00 AM', style: LogosTypography.caption(color: ink.withValues(alpha: 0.6))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: examenController.isExamenMode,
                          activeThumbColor: LogosColors.coral,
                          onChanged: (_) => examenController.toggleExamenPreview(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Liturgical Chimes & Midnight Bell Tile
                  StatefulBuilder(
                    builder: (ctx, setTileState) {
                      final isEnabled = NotificationService.instance.isEnabled;
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: LogosColors.taupe),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const AppIcon(LogosIcons.notificationsActive, color: LogosColors.coral),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Liturgical Chimes & Midnight Bell', style: LogosTypography.label(color: ink)),
                                        Text('Lauds (7am), Sext (12pm), Vespers (9pm), Midnight', style: LogosTypography.caption(color: ink.withValues(alpha: 0.6))),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: isEnabled,
                              activeTrackColor: LogosColors.coral,
                              onChanged: (val) async {
                                await NotificationService.instance.toggleNotifications(val);
                                setTileState(() {});
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Offline Scripture Packs Tile
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => ScripturePacksSheet.show(context),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: LogosColors.taupe),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: LogosColors.coral.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const AppIcon(LogosIcons.fileDownload, color: LogosColors.coral, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Offline Scripture Packs', style: LogosTypography.label(color: ink)),
                                Text(
                                  'Seasonal cloister downloads & 52-week curriculum',
                                  style: LogosTypography.caption(color: ink.withValues(alpha: 0.6)),
                                ),
                              ],
                            ),
                          ),
                          const AppIcon(LogosIcons.chevronRight, size: 18, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // APNS Push Dispatcher Status Plaque
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: LogosColors.taupe.withValues(alpha: 0.6)),
                    ),
                    child: Row(
                      children: [
                        AppIcon(
                          NotificationService.instance.isApnsSynced
                              ? LogosIcons.cloudDoneRounded
                              : LogosIcons.cloudQueueRounded,
                          size: 18,
                          color: NotificationService.instance.isApnsSynced
                              ? LogosColors.coral
                              : ink.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'APNS Push Notification Service',
                                style: LogosTypography.label(color: ink).copyWith(fontSize: 13),
                              ),
                              Text(
                                NotificationService.instance.deviceToken != null
                                    ? 'Token: ${NotificationService.instance.deviceToken!.substring(0, 16)}... • ${NotificationService.instance.isApnsSynced ? "Synced" : "Local"}'
                                    : 'Token awaiting permission grant',
                                style: LogosTypography.caption(color: ink.withValues(alpha: 0.6)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // iOS Home Widget & Dynamic Island Tile
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => LiturgicalWidgetPreviewSheet.show(context),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: LogosColors.taupe),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: LogosColors.coral.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const AppIcon(LogosIcons.timerOutlined, color: LogosColors.coral, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('iOS Home Widget & Dynamic Island', style: LogosTypography.label(color: ink)),
                                Text(
                                  'Glanceable Circadian hours & live activity sync',
                                  style: LogosTypography.caption(color: ink.withValues(alpha: 0.6)),
                                ),
                              ],
                            ),
                          ),
                          const AppIcon(LogosIcons.chevronRight, size: 18, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricTile({
    required LogosIconData icon,
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
          AppIcon(icon, color: iconColor, size: 24),
          const SizedBox(height: 10),
          Text(value, style: LogosTypography.headline(color: ink).copyWith(fontSize: 18)),
          Text(label, style: LogosTypography.caption(color: ink.withValues(alpha: 0.6))),
        ],
      ),
    );
  }

  Widget _buildTearSheetCard(TearSheetData sheet, Color surface, Color ink) {
    final d = sheet.completedAt;
    final dateStr = formatLogosDate(d);

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
                icon: const AppIcon(LogosIcons.share, size: 18, color: LogosColors.coral),
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
