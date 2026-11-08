import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:logos_mobile_app/features/community/data/voice_note_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory tmp;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    tmp = Directory.systemTemp.createTempSync('voice_notes_test');
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  LocalVoiceNote note(String id, DateTime createdAt) {
    final f = File('${tmp.path}/$id.m4a')..writeAsBytesSync([0, 1, 2]);
    return LocalVoiceNote(
      id: id,
      path: f.path,
      phrase: 'Amen',
      authorName: 'Pilgrim',
      durationSeconds: 5,
      createdAt: createdAt,
    );
  }

  test('keeps fresh notes newest-first and purges expired recordings from disk', () async {
    final store = VoiceNoteStore();
    final now = DateTime(2026, 11, 8, 12);
    final old = note('old', now.subtract(const Duration(days: 8)));
    final fresh = note('fresh', now.subtract(const Duration(days: 1)));
    final newest = note('newest', now.subtract(const Duration(hours: 1)));

    await store.add(old);
    await store.add(fresh);
    await store.add(newest);

    final loaded = await store.load(now: now);
    expect(loaded.map((n) => n.id), ['newest', 'fresh']);
    expect(File(old.path).existsSync(), isFalse, reason: '7-day ephemerality deletes the audio');
    expect(File(fresh.path).existsSync(), isTrue);
  });

  test('drops entries whose recording file is missing', () async {
    final store = VoiceNoteStore();
    final now = DateTime(2026, 11, 8, 12);
    final gone = note('gone', now);
    File(gone.path).deleteSync();
    await store.add(gone);

    expect(await store.load(now: now), isEmpty);
  });
}
