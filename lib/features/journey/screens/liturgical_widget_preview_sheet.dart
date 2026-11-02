import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/widget_service.dart';
import '../../../core/theme/logos_icons.dart';
import '../../../core/theme/logos_theme.dart';
import '../../../core/theme/logos_typography.dart';
import '../bloc/journey_bloc.dart';
import '../bloc/journey_state.dart';

/// Modal bottom sheet allowing pilgrims to preview and sync iOS Home Screen Widgets & Dynamic Island.
class LiturgicalWidgetPreviewSheet extends StatefulWidget {
  final LiturgicalWidgetService widgetService;

  const LiturgicalWidgetPreviewSheet({
    super.key,
    required this.widgetService,
  });

  static Future<void> show(BuildContext context, {LiturgicalWidgetService? widgetService}) {
    AudioService().selectionTick();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LiturgicalWidgetPreviewSheet(
        widgetService: widgetService ?? LiturgicalWidgetService(),
      ),
    );
  }

  @override
  State<LiturgicalWidgetPreviewSheet> createState() => _LiturgicalWidgetPreviewSheetState();
}

class _LiturgicalWidgetPreviewSheetState extends State<LiturgicalWidgetPreviewSheet> {
  bool _isSynced = false;
  bool _isIslandExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? LogosColors.examenSurface : Colors.white;
    final ink = isDark ? LogosColors.examenInk : LogosColors.ink;

    return BlocBuilder<JourneyBloc, JourneyState>(
      builder: (context, state) {
        final data = widget.widgetService.computeSnapshot(state: state);

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          padding: EdgeInsets.fromLTRB(24, 18, 24, MediaQuery.of(context).viewInsets.bottom + 34),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: LogosColors.coral.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const AppIcon(LogosIcons.timerOutlined, color: LogosColors.coral, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Liturgical iOS Widgets',
                                style: LogosTypography.headline(color: ink).copyWith(fontSize: 16),
                              ),
                              Text(
                                'Home Screen, Lock Screen & Dynamic Island',
                                style: LogosTypography.caption(color: ink.withValues(alpha: 0.6)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isSynced)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Synced ✓',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F5132),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),

              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    // 1. Dynamic Island Live Activity Preview
                    Text('Dynamic Island (Tap to Expand)', style: LogosTypography.label(color: ink)),
                    const SizedBox(height: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () {
                        AudioService().selectionTick();
                        setState(() => _isIslandExpanded = !_isIslandExpanded);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(_isIslandExpanded ? 24 : 32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: LogosColors.coral.withValues(alpha: 0.3),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const AppIcon(LogosIcons.cross, size: 12, color: Colors.white),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  data.nextHourName,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${data.streakCount}🔥 in ${data.countdownText}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: LogosColors.purpleAccent,
                                  ),
                                ),
                              ],
                            ),
                            if (_isIslandExpanded) ...[
                              const SizedBox(height: 10),
                              Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data.scriptureReference,
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white.withValues(alpha: 0.9),
                                          ),
                                        ),
                                        Text(
                                          '"${data.scriptureSnippet}"',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontStyle: FontStyle.italic,
                                            color: Colors.white.withValues(alpha: 0.7),
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: LogosColors.purpleDeep,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Day ${data.currentStep}/4',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // 2. Medium Widget Preview (4x2)
                    Text('Medium Home Screen Widget (4x2)', style: LogosTypography.label(color: ink)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LogosColors.whitePurpleBlend,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: LogosColors.taupe),
                        boxShadow: LogosColors.softShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: LogosColors.coral.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'LOGOS LITURGY',
                                  style: GoogleFonts.inter(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: LogosColors.coral,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${data.nextHourName} · ${data.nextHourTime}',
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: ink),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '"${data.scriptureSnippet}"',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              fontStyle: FontStyle.italic,
                              color: ink,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                data.scriptureReference,
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: LogosColors.coral),
                              ),
                              const Spacer(),
                              Text(
                                '${data.streakCount} Day Streak 🔥 · ${data.graceTokens} Grace',
                                style: GoogleFonts.inter(fontSize: 10.5, color: ink.withValues(alpha: 0.6)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // 3. Small Widget Preview (2x2)
                    Text('Small Home Screen Widget (2x2)', style: LogosTypography.label(color: ink)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 145,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: LogosColors.whitePurpleBlend,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: LogosColors.taupe),
                              boxShadow: LogosColors.softShadow,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const AppIcon(LogosIcons.cross, size: 16, color: LogosColors.coral),
                                    Text(
                                      '${data.streakCount}🔥',
                                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: ink),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data.nextHourName,
                                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: ink),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'in ${data.countdownText}',
                                      style: GoogleFonts.inter(fontSize: 10.5, color: LogosColors.coral, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                                Text(
                                  data.scriptureReference,
                                  style: GoogleFonts.inter(fontSize: 10, color: ink.withValues(alpha: 0.6), fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Lock screen rectangular preview
                        Expanded(
                          child: Container(
                            height: 145,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const AppIcon(LogosIcons.notificationsActive, size: 14, color: Colors.white),
                                    const SizedBox(width: 6),
                                    Text(
                                      'LOCK SCREEN',
                                      style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white70),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data.nextHourName,
                                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                                    ),
                                    Text(
                                      '${data.nextHourTime} (${data.countdownText})',
                                      style: GoogleFonts.inter(fontSize: 10, color: Colors.white70),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${data.scriptureReference} · Day ${data.currentStep}',
                                  style: GoogleFonts.inter(fontSize: 9.5, color: Colors.white60),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Action button to push live snapshot to WidgetKit
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
                  icon: const AppIcon(LogosIcons.syncAltRounded, size: 18),
                  label: Text(
                    'Sync Current State to iOS Widget',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () async {
                    AudioService().selectionTick();
                    await widget.widgetService.syncWidgetData(state: state);
                    setState(() => _isSynced = true);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
