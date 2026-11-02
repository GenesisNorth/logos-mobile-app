import 'scripture_drop.dart';

/// Represents a seasonal offline pack bundling multiple weeks of Scripture Drops,
/// Greek/Hebrew exegesis lexicons, encounter narratives, and ambient audio stems.
class ScripturePack {
  final String id;
  final String title;
  final String subtitle;
  final String season;
  final int weekStart;
  final int weekEnd;
  final int dropsCount;
  final double sizeMb;
  final bool isBuiltIn;
  final List<ScriptureDrop> drops;
  final bool isDownloaded;
  final double downloadProgress;

  const ScripturePack({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.season,
    required this.weekStart,
    required this.weekEnd,
    required this.dropsCount,
    required this.sizeMb,
    this.isBuiltIn = false,
    required this.drops,
    this.isDownloaded = false,
    this.downloadProgress = 0.0,
  });

  ScripturePack copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? season,
    int? weekStart,
    int? weekEnd,
    int? dropsCount,
    double? sizeMb,
    bool? isBuiltIn,
    List<ScriptureDrop>? drops,
    bool? isDownloaded,
    double? downloadProgress,
  }) {
    return ScripturePack(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      season: season ?? this.season,
      weekStart: weekStart ?? this.weekStart,
      weekEnd: weekEnd ?? this.weekEnd,
      dropsCount: dropsCount ?? this.dropsCount,
      sizeMb: sizeMb ?? this.sizeMb,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      drops: drops ?? this.drops,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      downloadProgress: downloadProgress ?? this.downloadProgress,
    );
  }
}
