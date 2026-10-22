import 'package:equatable/equatable.dart';

class ContextCard extends Equatable {
  final String title;
  final String subtitle;
  final String content;

  const ContextCard({
    required this.title,
    required this.subtitle,
    required this.content,
  });

  @override
  List<Object?> get props => [title, subtitle, content];
}

class ScriptureDrop extends Equatable {
  final String id;
  final int weekNumber;
  final String reference;
  final String verseText;
  final String translation;
  final String videoUrl;
  final List<ContextCard> contextCards;
  final String ambientSoundPreset;

  const ScriptureDrop({
    required this.id,
    required this.weekNumber,
    required this.reference,
    required this.verseText,
    required this.translation,
    required this.videoUrl,
    required this.contextCards,
    required this.ambientSoundPreset,
  });

  static ScriptureDrop defaultWeek1() {
    return const ScriptureDrop(
      id: '00000000-0000-0000-0000-000000000001',
      weekNumber: 1,
      reference: 'John 15:5',
      verseText:
          'I am the vine; you are the branches. Whoever abides in me and I in him, he it is that bears much fruit, for apart from me you can do nothing.',
      translation: 'ESV',
      videoUrl: 'https://assets.logosinme.com/videos/week1_encounter_hd.mp4',
      contextCards: [
        ContextCard(
          title: 'The True Vine',
          subtitle: 'Ancient Near East Metaphor',
          content:
              'In the Old Testament (Isaiah 5, Psalm 80), Israel was depicted as God\'s vineyard that repeatedly yielded bitter fruit. Jesus declares: "I am the true vine"—the ultimate source of life.',
        ),
        ContextCard(
          title: 'Abiding (Meno)',
          subtitle: 'Greek Theological Depth',
          content:
              'The Greek verb "meno" signifies to remain, dwell, and remain steadfastly rooted. It denotes not sporadic visits, but permanent communion.',
        ),
        ContextCard(
          title: 'The Fruit-Bearing Life',
          subtitle: 'Purpose of the Branches',
          content:
              'A branch does not struggle to produce fruit by human will; fruit is the effortless byproduct of uninterrupted connection to the sap of the vine.',
        ),
      ],
      ambientSoundPreset: 'Sanctuary Dawn (432Hz)',
    );
  }

  @override
  List<Object?> get props => [
        id,
        weekNumber,
        reference,
        verseText,
        translation,
        videoUrl,
        contextCards,
        ambientSoundPreset,
      ];
}
