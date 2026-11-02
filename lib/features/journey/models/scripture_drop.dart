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

  factory ContextCard.fromJson(Map<String, dynamic> j) => ContextCard(
        title: j['title'] as String,
        subtitle: j['subtitle'] as String,
        content: j['content'] as String,
      );

  @override
  List<Object?> get props => [title, subtitle, content];
}

/// One week of content: a single verse walked through over 4 days.
class ScriptureDrop extends Equatable {
  final String id;
  final int weekNumber;
  final String reference;
  final String verseText;
  final String translation;
  final String videoUrl;

  /// Short lines shown as the Day 1 cinematic title sequence
  /// (and as a fallback when the video can't be streamed).
  final List<String> encounterLines;
  final List<ContextCard> contextCards;

  /// Machine key, e.g. `sanctuary_dawn` (matches the backend column).
  final String ambientPreset;
  final String ambientLabel;

  /// Multi-translation verse texts (e.g., ESV, KJV, NASB, NIV).
  final Map<String, String>? translations;

  const ScriptureDrop({
    required this.id,
    required this.weekNumber,
    required this.reference,
    required this.verseText,
    required this.translation,
    required this.videoUrl,
    required this.encounterLines,
    required this.contextCards,
    required this.ambientPreset,
    required this.ambientLabel,
    this.translations,
  });

  /// Maps a `scripture_drops` row from Supabase (Phase 1).
  factory ScriptureDrop.fromRow(Map<String, dynamic> r) => ScriptureDrop(
        id: r['id'] as String,
        weekNumber: r['week_number'] as int,
        reference: r['target_reference'] as String,
        verseText: r['verse_text'] as String,
        translation: r['translation'] as String? ?? 'ESV',
        videoUrl: r['day_1_video_url'] as String? ?? '',
        encounterLines:
            (r['day_1_encounter_lines'] as List?)?.cast<String>() ?? const [],
        contextCards: ((r['day_2_context_cards'] as List?) ?? const [])
            .map((c) => ContextCard.fromJson(c as Map<String, dynamic>))
            .toList(),
        ambientPreset: r['day_3_ambient_preset'] as String? ?? 'sanctuary_dawn',
        ambientLabel: r['day_3_ambient_label'] as String? ?? 'Sanctuary Dawn',
        translations: (r['translations'] as Map?)?.cast<String, String>(),
      );

  /// Returns a new [ScriptureDrop] with the verse text switched to [targetTranslation],
  /// preserving all context cards, audio presets, and week metadata.
  ScriptureDrop withTranslation(String targetTranslation) {
    if (translations == null || !translations!.containsKey(targetTranslation)) {
      return this;
    }
    return copyWith(
      translation: targetTranslation,
      verseText: translations![targetTranslation]!,
    );
  }

  ScriptureDrop copyWith({
    String? id,
    int? weekNumber,
    String? reference,
    String? verseText,
    String? translation,
    String? videoUrl,
    List<String>? encounterLines,
    List<ContextCard>? contextCards,
    String? ambientPreset,
    String? ambientLabel,
    Map<String, String>? translations,
  }) {
    return ScriptureDrop(
      id: id ?? this.id,
      weekNumber: weekNumber ?? this.weekNumber,
      reference: reference ?? this.reference,
      verseText: verseText ?? this.verseText,
      translation: translation ?? this.translation,
      videoUrl: videoUrl ?? this.videoUrl,
      encounterLines: encounterLines ?? this.encounterLines,
      contextCards: contextCards ?? this.contextCards,
      ambientPreset: ambientPreset ?? this.ambientPreset,
      ambientLabel: ambientLabel ?? this.ambientLabel,
      translations: translations ?? this.translations,
    );
  }

  @override
  List<Object?> get props => [id, weekNumber, reference, verseText, translation];
}

