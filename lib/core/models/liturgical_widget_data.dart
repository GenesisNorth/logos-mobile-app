import 'dart:convert';

/// Data payload for iOS WidgetKit (Lock Screen, Home Screen Widgets & Dynamic Island).
class LiturgicalWidgetData {
  final String nextHourName;
  final String nextHourTime;
  final String countdownText;
  final String scriptureReference;
  final String scriptureSnippet;
  final int streakCount;
  final int rootsPlanted;
  final int graceTokens;
  final int currentStep;
  final bool isPaceLocked;
  final DateTime updatedAt;

  const LiturgicalWidgetData({
    required this.nextHourName,
    required this.nextHourTime,
    required this.countdownText,
    required this.scriptureReference,
    required this.scriptureSnippet,
    required this.streakCount,
    required this.rootsPlanted,
    required this.graceTokens,
    required this.currentStep,
    required this.isPaceLocked,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'nextHourName': nextHourName,
      'nextHourTime': nextHourTime,
      'countdownText': countdownText,
      'scriptureReference': scriptureReference,
      'scriptureSnippet': scriptureSnippet,
      'streakCount': streakCount,
      'rootsPlanted': rootsPlanted,
      'graceTokens': graceTokens,
      'currentStep': currentStep,
      'isPaceLocked': isPaceLocked,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory LiturgicalWidgetData.fromMap(Map<String, dynamic> map) {
    return LiturgicalWidgetData(
      nextHourName: map['nextHourName'] as String? ?? 'Morning Lauds',
      nextHourTime: map['nextHourTime'] as String? ?? '7:00 AM',
      countdownText: map['countdownText'] as String? ?? 'Dawn Awaken',
      scriptureReference: map['scriptureReference'] as String? ?? 'John 15:5',
      scriptureSnippet: map['scriptureSnippet'] as String? ?? 'I am the vine; you are the branches.',
      streakCount: map['streakCount'] as int? ?? 1,
      rootsPlanted: map['rootsPlanted'] as int? ?? 1,
      graceTokens: map['graceTokens'] as int? ?? 3,
      currentStep: map['currentStep'] as int? ?? 1,
      isPaceLocked: map['isPaceLocked'] as bool? ?? false,
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory LiturgicalWidgetData.fromJson(String source) =>
      LiturgicalWidgetData.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
