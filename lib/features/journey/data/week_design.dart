// Weekly content from the Organic redesign (titles, root words, encounter
// lines, stillness quotes). Generated from the design prototype data.

class RootReading {
  final String original;
  final String transliteration;
  final String title;
  final String subtitle;
  final String body;
  const RootReading(this.original, this.transliteration, this.title, this.subtitle, this.body);
}

class WeekDesign {
  final int number;
  final String title;
  final String rest;
  final String still;
  final String rootsSummary;
  final String nextLine;
  final List<String> keyStems;
  final List<String> encounterLines;
  final List<RootReading> roots;
  const WeekDesign({required this.number, required this.title, required this.rest, required this.still, required this.rootsSummary, required this.nextLine, required this.keyStems, required this.encounterLines, required this.roots});

  /// Short root word shown on the week list and recap (e.g. menō).
  String get rootWord => roots.isEmpty ? '' : roots.length > 1 ? roots[1].transliteration.split(' · ').first : roots.first.transliteration.split(' · ').first;
}

const weekDesigns = <WeekDesign>[
  WeekDesign(
    number: 1,
    title: 'The Vine',
    rest: 'Rest in the vine.',
    still: '“Abide in me, and I in you.”',
    rootsSummary: 'Three short readings on menō — to remain, to dwell.',
    nextLine: 'Philippians 4:6–7 is ready when you are — the peace that stands guard.',
    keyStems: ['abide', 'abides', 'abideth', 'abiding', 'remain', 'remains', 'remaining', 'remaineth'],
    encounterLines: ['The night before the cross,', 'Jesus walked with His friends past the vineyards.', 'He did not hand them a task.', 'He offered them a place to stay.', '“Abide in me.”'],
    roots: [
      RootReading('ἄμπελος', 'ampelos · vine', 'The True Vine', 'Ancient Near East Metaphor',
          'In the Old Testament (Isaiah 5, Psalm 80), Israel was depicted as God’s vineyard that repeatedly yielded bitter fruit. Jesus declares: “I am the true vine” — the ultimate source of life.'),
      RootReading('μένω', 'meno · to remain', 'Abiding', 'Greek Theological Depth',
          'The Greek verb “menō” signifies to remain, dwell, and remain steadfastly rooted. It denotes not sporadic visits, but permanent communion.'),
      RootReading('καρπός', 'karpos · fruit', 'The Fruit-Bearing Life', 'Purpose of the Branches',
          'A branch does not struggle to produce fruit by human will; fruit is the effortless byproduct of uninterrupted connection to the sap of the vine.'),
    ],
  ),
  WeekDesign(
    number: 2,
    title: 'Guarding Peace',
    rest: 'Peace stands guard.',
    still: '“The peace of God will guard your heart.”',
    rootsSummary: 'Two short readings on phroureō — peace that stands guard.',
    nextLine: 'Romans 8:1–2 is ready when you are — no condemnation. None.',
    keyStems: ['guard', 'keep', 'preserve', 'preserue', 'guarded'],
    encounterLines: ['Paul wrote these words in chains.', 'Not from comfort, but from a Roman prison.', 'And still he spoke of peace', 'standing guard over the heart.'],
    roots: [
      RootReading('φρουρέω', 'phroureo · to stand guard', 'The Roman Garrison', 'Historical Context in Philippi',
          'Philippi was a Roman military colony. When Paul writes “will guard your hearts”, he uses the military term “phroureō” — God’s peace standing sentry over your emotional borders.'),
      RootReading('εὐχαριστία', 'eucharistia · thanks', 'Supplication with Thanksgiving', 'The Liturgy of Release',
          'True supplication does not demand; it gives thanks before seeing the answer, resting in the Father’s unchanging goodness.'),
    ],
  ),
  WeekDesign(
    number: 3,
    title: 'No Condemnation',
    rest: 'No condemnation. None.',
    still: '“You are free in Christ Jesus.”',
    rootsSummary: 'Three short readings on katakrima — the annulled verdict.',
    nextLine: 'Psalm 23 is ready when you are — the Shepherd who restores.',
    keyStems: ['free', 'freed', 'delivered'],
    encounterLines: ['The gavel has fallen in the courts of eternity.', 'Not by your striving, but by His covenant blood.', 'The verdict is written in indelible grace:', 'No condemnation. None.', '“You are free in Christ Jesus.”'],
    roots: [
      RootReading('κατάκριμα', 'katakrima · verdict', 'The Annulled Verdict', 'Greek Judicial Term',
          'In Roman law, “katakrima” denoted the penal sentence and its execution. Paul proclaims that Christ took the full sentence into Himself; no judicial punishment remains for you.'),
      RootReading('πνεῦμα ζωῆς', 'pneuma zoes · Spirit of life', 'The Law of the Spirit of Life', 'Dynamic Spiritual Power',
          'Just as flight overcomes gravity without destroying it, the law of the Spirit of life lifts the believer above the pull of sin and shame.'),
      RootReading('ἐν Χριστῷ', 'en Christo · in Christ', 'In Christ Jesus', 'The Sphere of Refuge',
          'Paul uses “in Christ” over 160 times. To be in Christ means your past is subsumed into His death, and your future is sealed in His resurrection.'),
    ],
  ),
  WeekDesign(
    number: 4,
    title: 'The Good Shepherd',
    rest: 'He restores your soul.',
    still: '“He leads me beside still waters.”',
    rootsSummary: 'Three Hebrew readings — the Shepherd who stays close.',
    nextLine: 'Colossians 3:1–3 is ready when you are — hidden with Christ.',
    keyStems: ['restores', 'restoreth', 'refreshes', 'refresheth', 'converted', 'restore'],
    encounterLines: ['David was a shepherd in the Judean wilderness.', 'He knew sheep cannot lie down while anxious or afraid.', 'Your Shepherd has prepared quiet waters.', 'Breathe deeply. In Him, you lack nothing.', '“He restores my soul.”'],
    roots: [
      RootReading('יְהוָה רֹעִי', 'Yahweh Rohi · my shepherd', 'The Lord My Shepherd', 'Hebrew Covenant Name',
          'Ancient shepherds slept across the threshold of the pen. God does not guide you from a distance; He is your threshold protector.'),
      RootReading('מֵי מְנֻחוֹת', 'Mei Menuchot · still waters', 'Waters of Rest', 'Hebrew Poetic Depth',
          'Sheep fear rushing torrents because their heavy wool can pull them under. “Mei Menuchot” means waters of deep, quiet rest — streams made tranquil so you can drink in peace.'),
      RootReading('נַפְשִׁי יְשׁוֹבֵב', 'Nafshi Yeshovev · restores my soul', 'Soul Restoration', 'Return to Vitality',
          '“Yeshovev” implies turning around or bringing home what was exhausted or lost. God actively rehabilitates your inner life.'),
    ],
  ),
  WeekDesign(
    number: 5,
    title: 'Hidden in Christ',
    rest: 'Your life is hidden with Christ.',
    still: '“Set your minds on things above.”',
    rootsSummary: 'Three short readings on kekryptai — hidden and safe.',
    nextLine: 'Week 6 arrives with your next scripture pack.',
    keyStems: ['hidden', 'hid', 'secret'],
    encounterLines: ['Your earthly anxieties do not hold your true identity.', 'You have been co-raised into heavenly places.', 'Your life is not exposed, fragile, or abandoned.', 'It is safely hidden inside the Father’s heart.', '“Set your minds on things above.”'],
    roots: [
      RootReading('συνηγέρθητε', 'synegerthete · raised together', 'Co-Resurrected', 'Greek Spiritual Union',
          'Paul uses a compound verb meaning “raised together with”. Your new life is not an aspiration; it is an accomplished union with the risen Lord.'),
      RootReading('κέκρυπται', 'kekryptai · hidden', 'Hidden & Inviolable', 'Perfect Tense Security',
          'In the ancient world, valuables were hidden in earthen vaults for preservation. Your life is permanently sheltered inside the Father, untouchable by accusation.'),
      RootReading('φρονεῖτε', 'phroneite · set your mind', 'Set Your Affection', 'The Discipline of Contemplation',
          'To “set the mind” is not passive positive thinking, but an active calibration of heart, values, and gaze toward eternal reality.'),
    ],
  ),
];

WeekDesign weekDesignFor(int weekNumber) => weekDesigns[(weekNumber - 1).clamp(0, weekDesigns.length - 1)];
