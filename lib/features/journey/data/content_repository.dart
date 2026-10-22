import '../models/scripture_drop.dart';

/// Bundled weekly content for Phase 0 (offline). Mirrors `seed.sql`.
/// In Phase 1 this is replaced by a Supabase-backed source with local cache.
class ContentRepository {
  const ContentRepository();

  List<ScriptureDrop> get drops => _drops;

  ScriptureDrop dropForWeekIndex(int index) => _drops[index % _drops.length];

  static const _drops = <ScriptureDrop>[
    ScriptureDrop(
      id: '00000000-0000-0000-0000-000000000001',
      weekNumber: 1,
      reference: 'John 15:5',
      verseText:
          'I am the vine; you are the branches. Whoever abides in me and I in him, he it is that bears much fruit, for apart from me you can do nothing.',
      translation: 'ESV',
      videoUrl: 'https://assets.logosinme.com/videos/week1_encounter_hd.mp4',
      encounterLines: [
        'The night before the cross,',
        'Jesus walked with His friends past the vineyards.',
        'He did not hand them a task.',
        'He offered them a place to stay.',
        '“Abide in me.”',
      ],
      contextCards: [
        ContextCard(
          title: 'The True Vine',
          subtitle: 'Ancient Near East Metaphor',
          content:
              'In the Old Testament (Isaiah 5, Psalm 80), Israel was depicted as God\'s vineyard that repeatedly yielded bitter fruit. Jesus declares: "I am the true vine"—the ultimate source of life.',
        ),
        ContextCard(
          title: 'Abiding (Menō)',
          subtitle: 'Greek Theological Depth',
          content:
              'The Greek verb "menō" signifies to remain, dwell, and remain steadfastly rooted. It denotes not sporadic visits, but permanent communion.',
        ),
        ContextCard(
          title: 'The Fruit-Bearing Life',
          subtitle: 'Purpose of the Branches',
          content:
              'A branch does not struggle to produce fruit by human will; fruit is the effortless byproduct of uninterrupted connection to the sap of the vine.',
        ),
      ],
      ambientPreset: 'sanctuary_dawn',
      ambientLabel: 'Sanctuary Dawn · 432 Hz',
    ),
    ScriptureDrop(
      id: '00000000-0000-0000-0000-000000000002',
      weekNumber: 2,
      reference: 'Philippians 4:6-7',
      verseText:
          'Do not be anxious about anything, but in everything by prayer and supplication with thanksgiving let your requests be made known to God. And the peace of God, which surpasses all understanding, will guard your hearts and your minds in Christ Jesus.',
      translation: 'ESV',
      videoUrl: 'https://assets.logosinme.com/videos/week2_encounter_hd.mp4',
      encounterLines: [
        'Paul wrote these words in chains.',
        'Not from comfort, but from a Roman prison.',
        'And still he spoke of peace',
        'standing guard over the heart.',
      ],
      contextCards: [
        ContextCard(
          title: 'The Roman Garrison',
          subtitle: 'Historical Context in Philippi',
          content:
              'Philippi was a Roman military colony. When Paul writes "will guard your hearts", he uses the military term "phroureō"—depicting God\'s supernatural peace standing sentry over their emotional borders.',
        ),
        ContextCard(
          title: 'Supplication with Thanksgiving',
          subtitle: 'The Liturgy of Release',
          content:
              'True supplication does not demand; it gives thanks before seeing the answer, resting in the Father\'s unchanging goodness.',
        ),
      ],
      ambientPreset: 'sanctuary_dune',
      ambientLabel: 'Sanctuary Dune · 432 Hz',
    ),
  ];
}
