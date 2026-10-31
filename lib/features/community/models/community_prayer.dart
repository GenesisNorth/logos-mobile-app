import 'package:equatable/equatable.dart';

class CommunityPrayer extends Equatable {
  final String id;
  final String? userId;
  final String authorName;
  final String room; // 'the_well', 'prayer_circles', 'valley'
  final String title;
  final String content;
  final String? voiceNoteUrl;
  final String? pastorName;
  final String? pastorResponse;
  final int prayedCount;
  final bool isAnswered;
  final DateTime createdAt;

  const CommunityPrayer({
    required this.id,
    this.userId,
    required this.authorName,
    required this.room,
    required this.title,
    required this.content,
    this.voiceNoteUrl,
    this.pastorName,
    this.pastorResponse,
    this.prayedCount = 0,
    this.isAnswered = false,
    required this.createdAt,
  });

  factory CommunityPrayer.fromJson(Map<String, dynamic> json) {
    return CommunityPrayer(
      id: json['id']?.toString() ?? '',
      userId: json['user_id'] as String?,
      authorName: json['author_name'] as String? ?? 'Pilgrim',
      room: json['room'] as String? ?? 'the_well',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      voiceNoteUrl: json['voice_note_url'] as String?,
      pastorName: json['pastor_name'] as String?,
      pastorResponse: json['pastor_response'] as String?,
      prayedCount: (json['prayed_count'] as num?)?.toInt() ?? 0,
      isAnswered: json['is_answered'] as bool? ?? (json['pastor_response'] != null),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (userId != null) 'user_id': userId,
      'author_name': authorName,
      'room': room,
      'title': title,
      'content': content,
      if (voiceNoteUrl != null) 'voice_note_url': voiceNoteUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  CommunityPrayer copyWith({
    String? id,
    String? userId,
    String? authorName,
    String? room,
    String? title,
    String? content,
    String? voiceNoteUrl,
    String? pastorName,
    String? pastorResponse,
    int? prayedCount,
    bool? isAnswered,
    DateTime? createdAt,
  }) {
    return CommunityPrayer(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      authorName: authorName ?? this.authorName,
      room: room ?? this.room,
      title: title ?? this.title,
      content: content ?? this.content,
      voiceNoteUrl: voiceNoteUrl ?? this.voiceNoteUrl,
      pastorName: pastorName ?? this.pastorName,
      pastorResponse: pastorResponse ?? this.pastorResponse,
      prayedCount: prayedCount ?? this.prayedCount,
      isAnswered: isAnswered ?? this.isAnswered,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        authorName,
        room,
        title,
        content,
        voiceNoteUrl,
        pastorName,
        pastorResponse,
        prayedCount,
        isAnswered,
        createdAt,
      ];
}
