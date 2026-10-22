import 'package:flutter/material.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/theme/logos_theme.dart';
import '../../../core/theme/logos_typography.dart';

class TheWellScreen extends StatefulWidget {
  const TheWellScreen({super.key});

  @override
  State<TheWellScreen> createState() => _TheWellScreenState();
}

class _TheWellScreenState extends State<TheWellScreen> {
  final TextEditingController _requestController = TextEditingController();

  final List<Map<String, dynamic>> _pastRequests = [
    {
      'date': 'Yesterday',
      'request': 'Navigating severe burnout in ministry and loneliness. Struggling to pray.',
      'status': 'Answered',
      'pastor': 'Pastor Thomas M.',
      'pastorResponse': 'Beloved Genesis, I carried your name to the altar this morning. Remember: your labor is not what justifies you; your abiding in Christ is your life. Rest your soul today.',
      'audioDuration': '1:24',
      'isPlaying': false,
    },
  ];

  @override
  void dispose() {
    _requestController.dispose();
    super.dispose();
  }

  void _submitRequest() {
    final text = _requestController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _pastRequests.insert(0, {
        'date': 'Just now',
        'request': text,
        'status': 'In Queue (Guaranteed reply in 3h 58m)',
        'pastor': 'Assigned to Pastoral Team',
        'pastorResponse': 'Your request has been received into the Sanctuary queue. An ordained pastor is praying over your words and preparing a personalized written and voice response.',
        'audioDuration': null,
        'isPlaying': false,
      });
      _requestController.clear();
    });

    AudioService().playAmenChime();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Prayer request submitted. 4-hour pastoral response timer active.')),
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
            const Text('The Well', style: TextStyle(color: LogosColors.theWell, fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Pastoral Care & Prayer Ticketing', style: LogosTypography.caption(color: ink.withValues(alpha: 0.6))),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            // 4-Hour SLA Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: LogosColors.theWell,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, color: Colors.white, size: 20),
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
                    'Ordained pastoral shepherds are on watch. Every petition receives a personalized biblical response and audio intercession within 4 hours.',
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
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: LogosColors.taupe),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Submit a Pastoral Petition', style: LogosTypography.label(color: ink)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _requestController,
                    maxLines: 4,
                    style: LogosTypography.body(color: ink),
                    decoration: InputDecoration(
                      hintText: 'Share whatever burden, theological doubt, or sorrow is weighing on you...',
                      hintStyle: TextStyle(color: ink.withValues(alpha: 0.4), fontSize: 13),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LogosColors.theWell,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.water_drop, color: Colors.white),
                      label: const Text('Bring to The Well', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: _submitRequest,
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
              ),
              child: Row(
                children: [
                  const Icon(Icons.video_call_outlined, color: LogosColors.theWell, size: 28),
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

            Text('Your Pastoral History', style: LogosTypography.label(color: ink)),
            const SizedBox(height: 10),

            ..._pastRequests.map((req) {
              final isAnswered = req['status'] == 'Answered';
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isAnswered ? const Color(0xFF10B981) : LogosColors.taupe),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('PETITION · ${req['date']}', style: LogosTypography.caption(color: LogosColors.theWell)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isAnswered ? const Color(0xFF10B981).withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            req['status'] as String,
                            style: TextStyle(
                              color: isAnswered ? Colors.green.shade900 : Colors.orange.shade800,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '"${req['request']}"',
                      style: LogosTypography.body(color: ink.withValues(alpha: 0.75)).copyWith(fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 14),
                    Divider(color: LogosColors.taupe.withValues(alpha: 0.5)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.person_pin, size: 16, color: LogosColors.theWell),
                        const SizedBox(width: 6),
                        Text(
                          req['pastor'] as String,
                          style: LogosTypography.label(color: LogosColors.theWell),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      req['pastorResponse'] as String,
                      style: LogosTypography.body(color: ink).copyWith(height: 1.4),
                    ),
                    if (req['audioDuration'] != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: LogosColors.theWell.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.play_circle_fill, color: LogosColors.theWell, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              'Voice Prayer from Pastor (${req['audioDuration']})',
                              style: const TextStyle(color: LogosColors.theWell, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
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
