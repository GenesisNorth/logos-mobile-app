import 'package:flutter/material.dart';
import '../../../core/design/components.dart';
import '../../../core/design/organic.dart';
import '../../../core/services/verse_reader.dart';
import '../widgets/room_header.dart';

const _seasons = ['All', 'Anxiety', 'Grief', 'Gratitude', 'Sleeplessness'];

const _readings = [
  ('John 15:5', 'I am the vine; you are the branches. Whoever abides in me and I in him…', 'Beloved Sister in Lagos', 'Anxiety', '0:38'),
  ('Philippians 4:6–7', 'Do not be anxious about anything, but in everything by prayer and supplication…', 'Pilgrim in Edinburgh', 'Sleeplessness', '0:52'),
  ('Psalm 23:1–3', 'The Lord is my shepherd; I shall not want. He makes me lie down in green pastures…', 'Brother in Seoul', 'Grief', '0:44'),
  ('Colossians 3:1–3', 'Set your minds on things that are above, not on things that are on earth…', 'Sister in São Paulo', 'Gratitude', '0:41'),
];

/// Voice Comfort — Scripture read aloud by others.
/// (Behind the `room_voice_comfort` flag until recordings are uploaded via admin;
/// meanwhile the device voice reads the passage.)
class VoiceComfortScreen extends StatefulWidget {
  const VoiceComfortScreen({super.key});

  @override
  State<VoiceComfortScreen> createState() => _VoiceComfortScreenState();
}

class _VoiceComfortScreenState extends State<VoiceComfortScreen> {
  int _season = 0;

  @override
  void dispose() {
    VerseReader.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const atm = Atmosphere.sage;
    final list = _readings.where((r) => _season == 0 || r.$4 == _seasons[_season]).toList();
    return OScreen(
      atmosphere: atm,
      child: ListenableBuilder(
        listenable: VerseReader.instance,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.only(bottom: 30),
          children: [
            const RoomHeader(
              atmosphere: atm,
              kicker: 'Community',
              title: 'Voice Comfort',
              subtitle: 'Scripture read aloud by pilgrims around the world.',
              kickerColor: OC.s800,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 44,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                scrollDirection: Axis.horizontal,
                itemCount: _seasons.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => OPill(_seasons[i], selected: i == _season, onTap: () => setState(() => _season = i)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
              child: Column(
                children: [
                  for (final r in list) ...[
                    _ReadingCard(reading: r),
                    const SizedBox(height: 12),
                  ],
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Container(
                      color: OC.s700,
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Contribute your voice', style: OT.display(23, color: OC.s100)),
                          const SizedBox(height: 6),
                          Text('Read this week’s verse for someone who needs to hear it. Readings are reviewed before they’re shared.',
                              style: OT.small(color: OC.s100, alpha: 0.85)),
                        ],
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

class _ReadingCard extends StatelessWidget {
  final (String, String, String, String, String) reading;
  const _ReadingCard({required this.reading});

  @override
  Widget build(BuildContext context) {
    final reader = VerseReader.instance;
    final playing = reader.isReading(reading.$2);
    return OCard(
      radius: 28,
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OCircleButton(
            icon: playing ? OI.pause : OI.play,
            tooltip: playing ? 'Pause' : 'Play',
            background: OC.s700,
            foreground: OC.n100,
            size: 52,
            onTap: () => playing ? reader.stop() : reader.speak(reading.$2.replaceAll('…', '.'), reference: reading.$1),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${reading.$1} · ${reading.$5}'.toUpperCase(), style: OT.kicker(color: OC.s700, size: 11)),
                const SizedBox(height: 6),
                Text(reading.$2, style: OT.display(18, height: 1.25)),
                const SizedBox(height: 8),
                Text('Read by ${reading.$3}', style: OT.small(alpha: 0.65)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
