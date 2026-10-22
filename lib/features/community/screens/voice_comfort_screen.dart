import 'package:flutter/material.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/theme/logos_theme.dart';
import '../../../core/theme/logos_typography.dart';

class VoiceComfortScreen extends StatefulWidget {
  const VoiceComfortScreen({super.key});

  @override
  State<VoiceComfortScreen> createState() => _VoiceComfortScreenState();
}

class _VoiceComfortScreenState extends State<VoiceComfortScreen> {
  String _selectedSeason = 'All';
  int? _playingIndex;

  final List<String> _seasons = ['All', 'Anxiety', 'Grief', 'Gratitude', 'Sleeplessness'];

  final List<Map<String, dynamic>> _recordings = [
    {
      'reference': 'John 15:5',
      'verse': 'I am the vine; you are the branches. Whoever abides in me and I in him...',
      'reader': 'Beloved Sister in Lagos',
      'season': 'Anxiety',
      'duration': '0:35',
    },
    {
      'reference': 'Philippians 4:6-7',
      'verse': 'Do not be anxious about anything, but in everything by prayer and supplication...',
      'reader': 'Pilgrim in Edinburgh',
      'season': 'Sleeplessness',
      'duration': '0:48',
    },
    {
      'reference': 'Psalm 23:1-3',
      'verse': 'The Lord is my shepherd; I shall not want. He makes me lie down in green pastures...',
      'reader': 'Anonymous Brother in Seoul',
      'season': 'Grief',
      'duration': '0:52',
    },
    {
      'reference': 'Romans 8:38-39',
      'verse': 'For I am sure that neither death nor life, nor angels nor rulers... will be able to separate us from the love of God.',
      'reader': 'Sister in Atlanta',
      'season': 'Gratitude',
      'duration': '0:40',
    },
  ];

  void _togglePlay(int index) {
    AudioService().selectionTick();
    setState(() {
      _playingIndex = (_playingIndex == index) ? null : index;
    });
  }

  void _showContributeDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Contribute Your Voice', style: LogosTypography.headline(color: LogosColors.ink)),
            const SizedBox(height: 8),
            Text(
              'Record your recitation of John 15:5. After pastoral review, your voice will comfort brothers and sisters across the globe who are struggling to sleep or breathe through anxiety.',
              style: LogosTypography.body(color: LogosColors.ink.withValues(alpha: 0.8)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: LogosColors.voiceComfort,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.mic, color: Colors.white),
              label: const Text('Record Comfort Recitation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.pop(ctx);
                AudioService().playAmenChime();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Recitation submitted for gentle pastoral moderation.')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? LogosColors.examenInk : LogosColors.ink;
    final surface = isDark ? LogosColors.examenSurface : LogosColors.surface;

    final filtered = _selectedSeason == 'All'
        ? _recordings
        : _recordings.where((r) => r['season'] == _selectedSeason).toList();

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
            const Text('Voice Comfort', style: TextStyle(color: LogosColors.voiceComfort, fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Scripture Spoken By Others', style: LogosTypography.caption(color: ink.withValues(alpha: 0.6))),
          ],
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: LogosColors.voiceComfort,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.mic),
        label: const Text('Contribute Voice'),
        onPressed: _showContributeDialog,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Season filter chips
            SizedBox(
              height: 44,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _seasons.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final s = _seasons[i];
                  final isSelected = s == _selectedSeason;
                  return ChoiceChip(
                    label: Text(s, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : ink)),
                    selected: isSelected,
                    selectedColor: LogosColors.voiceComfort,
                    backgroundColor: surface,
                    side: BorderSide(color: isSelected ? LogosColors.voiceComfort : LogosColors.taupe),
                    onSelected: (val) {
                      if (val) setState(() => _selectedSeason = s);
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: filtered.length,
                itemBuilder: (context, idx) {
                  final rec = filtered[idx];
                  final isPlaying = _playingIndex == idx;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isPlaying ? LogosColors.voiceComfort : LogosColors.taupe,
                        width: isPlaying ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(rec['reference'] as String, style: LogosTypography.label(color: LogosColors.coral)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: LogosColors.voiceComfort.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                rec['season'] as String,
                                style: const TextStyle(
                                  color: LogosColors.voiceComfort,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '"${rec['verse']}"',
                          style: LogosTypography.scriptureBody(color: ink).copyWith(fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                color: LogosColors.voiceComfort,
                                size: 36,
                              ),
                              onPressed: () => _togglePlay(idx),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    rec['reader'] as String,
                                    style: LogosTypography.label(color: ink).copyWith(fontSize: 12),
                                  ),
                                  Text(
                                    isPlaying ? 'Playing recitation · ${rec['duration']}' : rec['duration'] as String,
                                    style: LogosTypography.caption(color: ink.withValues(alpha: 0.5)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
