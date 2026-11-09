import '../models/scripture_drop.dart';
import 'open_translation_texts.dart';

/// Bundled weekly content for Phase 0 (offline). Mirrors `seed.sql`.
/// In Phase 1 this is replaced by a Supabase-backed source with local cache.
class ContentRepository {
  const ContentRepository();

  List<ScriptureDrop> get drops => _drops;

  ScriptureDrop dropForWeekIndex(int index) => _drops[index % _drops.length];

  static final _drops = <ScriptureDrop>[
    ScriptureDrop(
      id: '00000000-0000-0000-0000-000000000001',
      weekNumber: 1,
      reference: 'John 15:5',
      verseText:
          'I am the vine; you are the branches. Whoever abides in me and I in him, he it is that bears much fruit, for apart from me you can do nothing.',
      translation: 'ESV',
      videoUrl: 'https://assets.logosinme.com/videos/week1_encounter_hd.mp4',
      encounterLines: const [
        'The night before the cross,',
        'Jesus walked with His friends past the vineyards.',
        'He did not hand them a task.',
        'He offered them a place to stay.',
        '“Abide in me.”',
      ],
      contextCards: const [
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
      ambientLabel: 'Sanctuary Dawn',
      translations: {
        ...openTranslationTexts['John 15:5']!,
        'ESV':
            'I am the vine; you are the branches. Whoever abides in me and I in him, he it is that bears much fruit, for apart from me you can do nothing.',
        'NASB':
            'I am the vine, you are the branches; he who abides in Me and I in him, he bears much fruit, for apart from Me you can do nothing.',
        'NIV':
            'I am the vine; you are the branches. If you remain in me and I in you, you will bear much fruit; apart from me you can do nothing.',
      },
    ),
    ScriptureDrop(
      id: '00000000-0000-0000-0000-000000000002',
      weekNumber: 2,
      reference: 'Philippians 4:6-7',
      verseText:
          'Do not be anxious about anything, but in everything by prayer and supplication with thanksgiving let your requests be made known to God. And the peace of God, which surpasses all understanding, will guard your hearts and your minds in Christ Jesus.',
      translation: 'ESV',
      videoUrl: 'https://assets.logosinme.com/videos/week2_encounter_hd.mp4',
      encounterLines: const [
        'Paul wrote these words in chains.',
        'Not from comfort, but from a Roman prison.',
        'And still he spoke of peace',
        'standing guard over the heart.',
      ],
      contextCards: const [
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
      ambientLabel: 'Sanctuary Dune',
      translations: {
        ...openTranslationTexts['Philippians 4:6-7']!,
        'ESV':
            'Do not be anxious about anything, but in everything by prayer and supplication with thanksgiving let your requests be made known to God. And the peace of God, which surpasses all understanding, will guard your hearts and your minds in Christ Jesus.',
        'NASB':
            'Be anxious for nothing, but in everything by prayer and supplication with thanksgiving let your requests be made known to God. And the peace of God, which surpasses all comprehension, will guard your hearts and your minds in Christ Jesus.',
        'NIV':
            'Do not be anxious about anything, but in every situation, by prayer and petition, with thanksgiving, present your requests to God. And the peace of God, which transcends all understanding, will guard your hearts and your minds in Christ Jesus.',
      },
    ),
    ScriptureDrop(
      id: '00000000-0000-0000-0000-000000000003',
      weekNumber: 3,
      reference: 'Romans 8:1-2',
      verseText:
          'There is therefore now no condemnation for those who are in Christ Jesus. For the law of the Spirit of life has set you free in Christ Jesus from the law of sin and death.',
      translation: 'ESV',
      videoUrl: 'https://assets.logosinme.com/videos/week3_encounter_hd.mp4',
      encounterLines: const [
        'The gavel has fallen in the courts of eternity.',
        'Not by your striving, but by His covenant blood.',
        'The verdict is written in indelible grace:',
        'No condemnation. None.',
        '“You are free in Christ Jesus.”',
      ],
      contextCards: const [
        ContextCard(
          title: 'Katakrima: The Annulled Verdict',
          subtitle: 'Greek Judicial Term',
          content:
              'In Roman law, "katakrima" denoted the penal sentence and subsequent execution. Paul proclaims that Christ took the full penal sentence into Himself; no judicial punishment remains for you.',
        ),
        ContextCard(
          title: 'The Law of the Spirit of Life',
          subtitle: 'Dynamic Spiritual Power',
          content:
              'Just as aerodynamics overcomes gravity without destroying it, the law of the Spirit of life effortlessly lifts the believer above the pull of sin and shame.',
        ),
        ContextCard(
          title: 'In Christ Jesus',
          subtitle: 'The Sphere of Inviolable Refuge',
          content:
              'Paul uses "in Christ" over 160 times. To be "in Christ" means your past is subsumed into His death, and your future is sealed in His resurrection.',
        ),
      ],
      ambientPreset: 'sanctuary_dawn',
      ambientLabel: 'Sanctuary Deep',
      translations: {
        ...openTranslationTexts['Romans 8:1-2']!,
        'ESV':
            'There is therefore now no condemnation for those who are in Christ Jesus. For the law of the Spirit of life has set you free in Christ Jesus from the law of sin and death.',
        'NASB':
            'Therefore there is now no condemnation for those who are in Christ Jesus. For the law of the Spirit of life in Christ Jesus has set you free from the law of sin and of death.',
        'NIV':
            'Therefore, there is now no condemnation for those who are in Christ Jesus, because through Christ Jesus the law of the Spirit who gives life has set you free from the law of sin and death.',
      },
    ),
    ScriptureDrop(
      id: '00000000-0000-0000-0000-000000000004',
      weekNumber: 4,
      reference: 'Psalm 23:1-3',
      verseText:
          'The LORD is my shepherd; I shall not want. He makes me lie down in green pastures. He leads me beside still waters. He restores my soul. He leads me in paths of righteousness for his name’s sake.',
      translation: 'ESV',
      videoUrl: 'https://assets.logosinme.com/videos/week4_encounter_hd.mp4',
      encounterLines: const [
        'David was a shepherd in the Judean wilderness.',
        'He knew sheep cannot lie down while anxious or afraid.',
        'Your Shepherd has prepared quiet waters.',
        'Breathe deeply. In Him, you lack nothing.',
        '“He restores my soul.”',
      ],
      contextCards: const [
        ContextCard(
          title: 'Yahweh Rohi: The Lord My Shepherd',
          subtitle: 'Hebrew Covenant Name',
          content:
              'Ancient shepherds lived in direct proximity to their flock, sleeping across the threshold of the pen. God does not guide you from a distance; He is your threshold protector.',
        ),
        ContextCard(
          title: 'Mei Menuchot: Still Waters',
          subtitle: 'Hebrew Poetic Depth',
          content:
              'Sheep fear rushing torrents because their heavy wool can pull them under. "Mei Menuchot" literally means "waters of deep, quiet rest"—streams made tranquil so you can drink in peace.',
        ),
        ContextCard(
          title: 'Nafshi Yeshovev: Soul Restoration',
          subtitle: 'Return to Vitality',
          content:
              'In Hebrew, "yeshovev" implies turning around or bringing home what was exhausted or lost. God actively rehabilitates your inner life.',
        ),
      ],
      ambientPreset: 'sanctuary_dune',
      ambientLabel: 'Quiet Waters',
      translations: {
        ...openTranslationTexts['Psalm 23:1-3']!,
        'ESV':
            'The LORD is my shepherd; I shall not want. He makes me lie down in green pastures. He leads me beside still waters. He restores my soul. He leads me in paths of righteousness for his name’s sake.',
        'NASB':
            'The LORD is my shepherd, I shall not want. He makes me lie down in green pastures; He leads me beside quiet waters. He restores my soul; He guides me in the paths of righteousness For His name\'s sake.',
        'NIV':
            'The LORD is my shepherd, I lack nothing. He makes me lie down in green pastures, he leads me beside quiet waters, he refreshes my soul. He guides me along the right paths for his name’s sake.',
      },
    ),
    ScriptureDrop(
      id: '00000000-0000-0000-0000-000000000005',
      weekNumber: 5,
      reference: 'Colossians 3:1-3',
      verseText:
          'If then you have been raised with Christ, seek the things that are above, where Christ is, seated at the right hand of God. Set your minds on things that are above, not on things that are on earth. For you have died, and your life is hidden with Christ in God.',
      translation: 'ESV',
      videoUrl: 'https://assets.logosinme.com/videos/week5_encounter_hd.mp4',
      encounterLines: const [
        'Your earthly anxieties do not hold your true identity.',
        'You have been co-raised into heavenly places.',
        'Your life is not exposed, fragile, or abandoned.',
        'It is safely hidden inside the Father’s heart.',
        '“Set your minds on things above.”',
      ],
      contextCards: const [
        ContextCard(
          title: 'Synēgerthēte: Co-Resurrected',
          subtitle: 'Greek Spiritual Union',
          content:
              'Paul uses a compound verb meaning "raised together with". The believer’s new life is not an aspiration; it is an accomplished metaphysical union with the risen Lord.',
        ),
        ContextCard(
          title: 'Kekryptai: Hidden & Inviolable',
          subtitle: 'Perfect Tense Security',
          content:
              'In the ancient world, valuables were hidden in secret earthen vaults for preservation. Your life is permanently sheltered inside the Father, untouchable by accusations.',
        ),
        ContextCard(
          title: 'Phroneō: Set Your Affection',
          subtitle: 'The Discipline of Contemplation',
          content:
              'To "set the mind" is not passive positive thinking, but an active calibration of heart, values, and gaze toward eternal reality.',
        ),
      ],
      ambientPreset: 'sanctuary_dawn',
      ambientLabel: 'Heavenly Places',
      translations: {
        ...openTranslationTexts['Colossians 3:1-3']!,
        'ESV':
            'If then you have been raised with Christ, seek the things that are above, where Christ is, seated at the right hand of God. Set your minds on things that are above, not on things that are on earth. For you have died, and your life is hidden with Christ in God.',
        'NASB':
            'Therefore if you have been raised up with Christ, keep seeking the things above, where Christ is, seated at the right hand of God. Set your mind on the things above, not on the things that are on earth. For you have died and your life is hidden with Christ in God.',
        'NIV':
            'Since, then, you have been raised with Christ, set your hearts on things above, where Christ is, seated at the right hand of God. Set your minds on things above, not on earthly things. For you died, and your life is now hidden with Christ in God.',
      },
    ),
  ];
}

