import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/theme/logos_theme.dart';
import '../../../core/theme/logos_typography.dart';

class PrayerCirclesScreen extends StatefulWidget {
  const PrayerCirclesScreen({super.key});

  @override
  State<PrayerCirclesScreen> createState() => _PrayerCirclesScreenState();
}

class _PrayerCirclesScreenState extends State<PrayerCirclesScreen> {
  bool _isRecording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;
  String _selectedFixedPhrase = 'Praying with you';

  final List<String> _fixedPhrases = [
    'Praying with you',
    'Standing in agreement',
    'Lifting you before the Father',
    'The peace of Christ guard you',
    'Amen',
  ];

  final List<Map<String, dynamic>> _voiceNotes = [
    {
      'id': '1',
      'author': 'Sarah K.',
      'phrase': 'Praying with you',
      'duration': '0:42',
      'expiresIn': 'Expires in 4 days',
      'timeAgo': '2 days ago',
      'isPlaying': false,
    },
    {
      'id': '2',
      'author': 'David M.',
      'phrase': 'The peace of Christ guard you',
      'duration': '1:15',
      'expiresIn': 'Expires in 5 days',
      'timeAgo': '1 day ago',
      'isPlaying': false,
    },
    {
      'id': '3',
      'author': 'Hannah L.',
      'phrase': 'Standing in agreement',
      'duration': '0:28',
      'expiresIn': 'Expires in 6 days',
      'timeAgo': '12 hours ago',
      'isPlaying': false,
    },
  ];

  @override
  void dispose() {
    _recordTimer?.cancel();
    super.dispose();
  }

  void _toggleRecording() {
    if (_isRecording) {
      _recordTimer?.cancel();
      setState(() {
        _isRecording = false;
        _voiceNotes.insert(0, {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'author': 'Genesis A. (You)',
          'phrase': _selectedFixedPhrase,
          'duration': '0:${_recordSeconds.toString().padLeft(2, '0')}',
          'expiresIn': 'Expires in 7 days',
          'timeAgo': 'Just now',
          'isPlaying': false,
        });
        _recordSeconds = 0;
      });
      AudioService().playAmenChime();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prayer voice note shared (purges in 7 days)')),
      );
    } else {
      AudioService().selectionTick();
      setState(() {
        _isRecording = true;
        _recordSeconds = 0;
      });
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return;
        setState(() {
          _recordSeconds++;
          if (_recordSeconds >= 120) {
            _toggleRecording(); // Cap at 120 seconds max
          }
        });
      });
    }
  }

  void _togglePlay(int index) {
    AudioService().selectionTick();
    setState(() {
      for (int i = 0; i < _voiceNotes.length; i++) {
        _voiceNotes[i]['isPlaying'] = (i == index) ? !_voiceNotes[i]['isPlaying'] : false;
      }
    });
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
            const Text('Prayer Circles', style: TextStyle(color: LogosColors.prayerCircles, fontWeight: FontWeight.bold, fontSize: 16)),
            Text('7-Day Ephemeral Prayers', style: LogosTypography.caption(color: ink.withValues(alpha: 0.6))),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                children: [
                  // Circle Manifesto Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: LogosColors.prayerCircles,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.auto_delete_outlined, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              '7-DAY SACRED EPHEMERALITY',
                              style: LogosTypography.caption(color: Colors.white.withValues(alpha: 0.85)).copyWith(
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'The Jerusalem Circle',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Voice prayers are automatically purged after 7 days to keep hearts focused on present intercession, free from digital hoarding.',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Fixed Phrase Quick Selector
                  Text('Encouragement Stance', style: LogosTypography.label(color: ink)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _fixedPhrases.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final phrase = _fixedPhrases[i];
                        final isSelected = phrase == _selectedFixedPhrase;
                        return ChoiceChip(
                          label: Text(phrase, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : ink)),
                          selected: isSelected,
                          selectedColor: LogosColors.prayerCircles,
                          backgroundColor: surface,
                          side: BorderSide(color: isSelected ? LogosColors.prayerCircles : LogosColors.taupe),
                          onSelected: (val) {
                            if (val) setState(() => _selectedFixedPhrase = phrase);
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Circle Voice Prayers', style: LogosTypography.label(color: ink)),
                      Text('${_voiceNotes.length} active', style: LogosTypography.caption(color: ink.withValues(alpha: 0.5))),
                    ],
                  ),
                  const SizedBox(height: 12),

                  ...List.generate(_voiceNotes.length, (index) {
                    final note = _voiceNotes[index];
                    final isPlaying = note['isPlaying'] == true;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isPlaying ? LogosColors.prayerCircles : LogosColors.taupe,
                          width: isPlaying ? 1.5 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
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
                                    radius: 14,
                                    backgroundColor: LogosColors.prayerCircles.withValues(alpha: 0.2),
                                    child: Text(
                                      (note['author'] as String)[0],
                                      style: TextStyle(color: ink, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(note['author'] as String, style: LogosTypography.label(color: ink)),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  note['expiresIn'] as String,
                                  style: TextStyle(color: Colors.orange.shade800, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '"${note['phrase']}"',
                            style: LogosTypography.scriptureCitation(color: LogosColors.prayerCircles),
                          ),
                          const SizedBox(height: 12),

                          // Audio player bar
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: ink.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                    color: LogosColors.prayerCircles,
                                    size: 32,
                                  ),
                                  onPressed: () => _togglePlay(index),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Simulated waveform
                                      Row(
                                        children: List.generate(24, (barIndex) {
                                          final height = isPlaying
                                              ? (10 + (barIndex % 5) * 4).toDouble()
                                              : (6 + (barIndex % 3) * 3).toDouble();
                                          return Container(
                                            margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                            width: 3,
                                            height: height,
                                            decoration: BoxDecoration(
                                              color: isPlaying ? LogosColors.prayerCircles : ink.withValues(alpha: 0.25),
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                          );
                                        }),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(note['duration'] as String, style: LogosTypography.caption(color: ink.withValues(alpha: 0.6))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Bottom Audio Record Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: surface,
                border: Border(top: BorderSide(color: LogosColors.taupe.withValues(alpha: 0.5))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isRecording
                              ? 'Recording Prayer (${_recordSeconds}s / 120s max)'
                              : 'Speak a voice prayer to your circle',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _isRecording ? Colors.redAccent : ink,
                          ),
                        ),
                        Text(
                          'Phrase: $_selectedFixedPhrase',
                          style: LogosTypography.caption(color: ink.withValues(alpha: 0.6)),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _toggleRecording,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _isRecording ? Colors.redAccent : LogosColors.prayerCircles,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_isRecording ? Colors.redAccent : LogosColors.prayerCircles).withValues(alpha: 0.35),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isRecording ? Icons.stop : Icons.mic,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
