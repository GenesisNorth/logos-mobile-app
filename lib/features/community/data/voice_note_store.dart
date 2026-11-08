import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// A voice prayer recorded on this device.
class LocalVoiceNote {
  final String id;
  final String path;
  final String phrase;
  final String authorName;
  final int durationSeconds;
  final DateTime createdAt;

  const LocalVoiceNote({
    required this.id,
    required this.path,
    required this.phrase,
    required this.authorName,
    required this.durationSeconds,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        'phrase': phrase,
        'authorName': authorName,
        'durationSeconds': durationSeconds,
        'createdAt': createdAt.toIso8601String(),
      };

  factory LocalVoiceNote.fromJson(Map<String, dynamic> j) => LocalVoiceNote(
        id: j['id'] as String,
        path: j['path'] as String,
        phrase: j['phrase'] as String,
        authorName: j['authorName'] as String? ?? 'You',
        durationSeconds: j['durationSeconds'] as int? ?? 0,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}

/// Persists the pilgrim's own voice prayers on-device and enforces the
/// 7-day ephemerality promise by deleting expired recordings.
class VoiceNoteStore {
  static const _key = 'logos_prayer_voice_notes';
  static const lifetime = Duration(days: 7);

  /// Loads notes newest-first, purging expired or missing recordings.
  Future<List<LocalVoiceNote>> load({DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];

    final current = now ?? DateTime.now();
    final kept = <LocalVoiceNote>[];
    var changed = false;
    try {
      for (final e in jsonDecode(raw) as List) {
        final note = LocalVoiceNote.fromJson(e as Map<String, dynamic>);
        final file = File(note.path);
        final expired = current.difference(note.createdAt) >= lifetime;
        if (expired || !file.existsSync()) {
          changed = true;
          if (file.existsSync()) await file.delete();
          continue;
        }
        kept.add(note);
      }
    } catch (e) {
      debugPrint('[VoiceNoteStore] corrupt store reset: $e');
      changed = true;
    }
    if (changed) await _save(prefs, kept);
    kept.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return kept;
  }

  Future<void> add(LocalVoiceNote note) async {
    final prefs = await SharedPreferences.getInstance();
    final notes = await load();
    await _save(prefs, [note, ...notes]);
  }

  /// A fresh file path for the next recording.
  Future<String> newRecordingPath() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/prayer_notes');
    if (!dir.existsSync()) await dir.create(recursive: true);
    return '${dir.path}/${const Uuid().v4()}.m4a';
  }

  Future<void> _save(SharedPreferences prefs, List<LocalVoiceNote> notes) =>
      prefs.setString(_key, jsonEncode(notes.map((n) => n.toJson()).toList()));
}
