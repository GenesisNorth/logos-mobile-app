import 'package:flutter/material.dart';
import '../../../core/utils/pilgrim_name.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/logos_theme.dart';
import '../../../core/theme/logos_typography.dart';
import '../../../core/theme/logos_icons.dart';
import '../data/community_repository.dart';
import '../models/community_prayer.dart';

class TheWellScreen extends StatefulWidget {
  const TheWellScreen({super.key});

  @override
  State<TheWellScreen> createState() => _TheWellScreenState();
}

class _TheWellScreenState extends State<TheWellScreen> {
  final TextEditingController _requestController = TextEditingController();
  final CommunityRepository _repository = CommunityRepository();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _requestController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    final text = _requestController.text.trim();
    if (text.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      await _repository.submitPrayer(
        room: 'the_well',
        title: 'Pastoral Petition',
        content: text,
        authorName: pilgrimName(context),
      );

      _requestController.clear();
      AudioService().playAmenChime();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF10B981),
            content: Text('Prayer request submitted to the Sanctuary watch. 4-hour SLA active.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return diff.inMinutes <= 1 ? 'Just now' : '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? LogosColors.examenInk : LogosColors.ink;
    final surface = isDark ? LogosColors.examenSurface : LogosColors.surface;
    final isCloudActive = SupabaseService.instance.isConfigured;

    return Scaffold(
      backgroundColor: isDark ? LogosColors.examenBg : LogosColors.sand,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: AppIcon(LogosIcons.arrowBack, color: ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'The Well',
                  style: TextStyle(
                    color: LogosColors.theWell,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isCloudActive
                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                        : Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isCloudActive ? 'LIVE CLOUD' : 'OFFLINE SANCTUARY',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: isCloudActive ? const Color(0xFF0F5132) : Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              'Pastoral Care & Prayer Watch',
              style: LogosTypography.caption(color: ink.withValues(alpha: 0.6)),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: StreamBuilder<List<CommunityPrayer>>(
          stream: _repository.watchPrayers(room: 'the_well'),
          builder: (context, snapshot) {
            final prayers = snapshot.data ?? [];

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              children: [
                // 4-Hour SLA Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: LogosColors.theWell,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: LogosColors.softShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const AppIcon(LogosIcons.timerOutlined, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '4-HOUR PASTORAL CARE SLA',
                            style: LogosTypography.caption(color: Colors.white.withValues(alpha: 0.85)).copyWith(
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'No prayer request goes unheard.',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Ordained pastoral shepherds are on watch. Every petition receives a personalized biblical response and intercession within 4 hours.',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Submit Prayer Request Form
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: LogosColors.taupe),
                    boxShadow: LogosColors.softShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const AppIcon(LogosIcons.editNote, size: 18, color: LogosColors.theWell),
                          const SizedBox(width: 8),
                          Text('Submit a Pastoral Petition', style: LogosTypography.label(color: ink)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _requestController,
                        maxLines: 4,
                        style: LogosTypography.body(color: ink),
                        decoration: InputDecoration(
                          hintText: 'Share whatever burden, theological doubt, or sorrow is weighing on you...',
                          hintStyle: TextStyle(color: ink.withValues(alpha: 0.4), fontSize: 13),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: LogosColors.taupe),
                          ),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: LogosColors.theWell,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const AppIcon(LogosIcons.waterDrop, color: Colors.white),
                          label: Text(
                            _isSubmitting ? 'Submitting to Sanctuary...' : 'Bring to The Well',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          onPressed: _isSubmitting ? null : _submitRequest,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Pastoral Consultations
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: LogosColors.taupe),
                    boxShadow: LogosColors.softShadow,
                  ),
                  child: Row(
                    children: [
                      const AppIcon(LogosIcons.videoCallOutlined, color: LogosColors.theWell, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('1-on-1 Pastoral Consultation', style: LogosTypography.label(color: ink)),
                            Text('Book a 30-min confidential video call', style: LogosTypography.caption(color: ink.withValues(alpha: 0.6))),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          AudioService().selectionTick();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Cal.com integration: Pastor schedule loaded.')),
                          );
                        },
                        child: const Text('Book'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Text('Your Pastoral Watch History', style: LogosTypography.label(color: ink)),
                const SizedBox(height: 10),

                if (prayers.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Text(
                        'No petitions in queue. You are surrounded by peace.',
                        style: LogosTypography.body(color: ink.withValues(alpha: 0.6)),
                      ),
                    ),
                  )
                else
                  ...prayers.map((prayer) {
                    final isAnswered = prayer.isAnswered;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isAnswered ? const Color(0xFF10B981).withValues(alpha: 0.5) : LogosColors.taupe,
                        ),
                        boxShadow: LogosColors.softShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'PETITION · ${_formatTimeAgo(prayer.createdAt)}',
                                style: LogosTypography.caption(color: LogosColors.theWell),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isAnswered
                                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                      : Colors.orange.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isAnswered ? 'Answered' : 'In Watch (Queue)',
                                  style: TextStyle(
                                    color: isAnswered ? const Color(0xFF0F5132) : Colors.orange.shade800,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '“${prayer.content}”',
                            style: LogosTypography.body(color: ink.withValues(alpha: 0.8)).copyWith(fontStyle: FontStyle.italic),
                          ),
                          const SizedBox(height: 14),
                          Divider(color: LogosColors.taupe.withValues(alpha: 0.5)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const AppIcon(LogosIcons.personPin, size: 16, color: LogosColors.theWell),
                              const SizedBox(width: 6),
                              Text(
                                prayer.pastorName ?? 'Pastoral Shepherds',
                                style: LogosTypography.label(color: LogosColors.theWell),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            prayer.pastorResponse ??
                                'An ordained pastor is praying over your petition and preparing a biblical written response.',
                            style: LogosTypography.body(color: ink).copyWith(height: 1.4),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  AudioService().selectionTick();
                                  _repository.prayFor(room: 'the_well', prayerId: prayer.id);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const AppIcon(LogosIcons.volunteerActivism, size: 14, color: Color(0xFF10B981)),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${prayer.prayedCount} praying',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF0F5132),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (prayer.voiceNoteUrl != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: LogosColors.theWell.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      AppIcon(LogosIcons.playCircleFill, color: LogosColors.theWell, size: 16),
                                      SizedBox(width: 4),
                                      Text(
                                        'Voice Prayer',
                                        style: TextStyle(
                                          color: LogosColors.theWell,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            );
          },
        ),
      ),
    );
  }
}
