import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:logos_mobile_app/core/services/supabase_service.dart';
import 'package:logos_mobile_app/core/services/notification_service.dart';
import 'package:logos_mobile_app/features/journey/data/progress_repository.dart';
import 'package:logos_mobile_app/features/journey/data/supabase_progress_repository.dart';
import 'package:logos_mobile_app/features/community/data/community_repository.dart';
import 'package:logos_mobile_app/features/community/models/community_prayer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SupabaseService & Cloud Backend Contract Tests', () {
    test('SupabaseService initializes gracefully in offline/unconfigured cloister mode', () async {
      final service = SupabaseService.instance;
      await service.initialize();

      expect(service.isConfigured, isFalse);
      expect(service.isInitialized, isFalse);
      expect(service.client, isNull);
      expect(service.currentUserId, isNull);
      expect(service.isAnonymous, isTrue);

      // Account linking fails gracefully when offline without throwing
      final linked = await service.linkWithEmail(email: 'pilgrim@logos.app', password: 'SecretPassword123');
      expect(linked, isFalse);

      // Push token registration fails gracefully without throwing
      final pushRegistered = await service.registerPushToken(token: 'a1b2c3d4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f90');
      expect(pushRegistered, isFalse);
    });
  });

  group('ProgressRepository Dual-Layer (Local + Supabase) End-to-End Tests', () {
    test('Local & SupabaseProgressRepository store and recover UserProfile with Covenant Signature', () async {
      final repo = SupabaseProgressRepository();

      final initialProfile = await repo.loadProfile();
      expect(initialProfile.username, equals('pilgrim'));
      expect(initialProfile.hasSignedCovenant, isFalse);

      final now = DateTime(2026, 11, 3, 10, 30);
      const testSig = '3f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7';
      final updatedProfile = UserProfileData(
        username: 'solitary_pilgrim',
        displayName: 'Brother Francis',
        covenantSignature: testSig,
        covenantSignedAt: now,
        birthMonth: 4,
        birthDay: 16,
      );

      await repo.saveProfile(updatedProfile);

      final recovered = await repo.loadProfile();
      expect(recovered.username, equals('solitary_pilgrim'));
      expect(recovered.displayName, equals('Brother Francis'));
      expect(recovered.hasSignedCovenant, isTrue);
      expect(recovered.covenantSignature, equals(testSig));
      expect(recovered.covenantSignedAt, isNotNull);
      expect(recovered.birthMonth, equals(4));
      expect(recovered.birthDay, equals(16));
    });

    test('Local & SupabaseProgressRepository store and recover Journey Progress with Translation', () async {
      final repo = SupabaseProgressRepository();

      final journeyPayload = {
        'weekIndex': 2,
        'activeDay': 3,
        'preferredTranslation': 'KJV',
        'currentStreak': 7,
        'rootsPlanted': 14,
        'graceTokensBalance': 2,
        'isExchangeCompleted': true,
        'dayCompletion': {'1': true, '2': true, '3': false, '4': false},
        'dayCompletedAt': {
          '1': '2026-11-01T08:00:00.000Z',
          '2': '2026-11-02T08:00:00.000Z',
        },
        'recitationCounts': {'1': 5, '2': 3, '3': 0, '4': 0},
      };

      await repo.saveJourneyData(journeyPayload);

      final recovered = await repo.loadJourneyData();
      expect(recovered['weekIndex'], equals(2));
      expect(recovered['activeDay'], equals(3));
      expect(recovered['preferredTranslation'], equals('KJV'));
      expect(recovered['currentStreak'], equals(7));
      expect(recovered['rootsPlanted'], equals(14));
      expect(recovered['graceTokensBalance'], equals(2));
      expect(recovered['isExchangeCompleted'], isTrue);
      expect(recovered['dayCompletion']['1'], isTrue);
      expect(recovered['dayCompletion']['2'], isTrue);
      expect(recovered['dayCompletion']['3'], isFalse);
    });

    test('Local & SupabaseProgressRepository store and recover Dissolved Tear Sheets', () async {
      final repo = SupabaseProgressRepository();

      final sheet1 = TearSheetData(
        id: const Uuid().v4(),
        dropId: '00000000-0000-0000-0000-000000000001',
        verseText: 'I am the vine; you are the branches.',
        reference: 'John 15:5',
        burdenHash: 'hash_anxiety_over_work',
        tearSheetImagePath: '/data/user/0/tear_sheet_1.png',
        completedAt: DateTime(2026, 10, 25, 21, 0),
      );

      final sheet2 = TearSheetData(
        id: const Uuid().v4(),
        dropId: '00000000-0000-0000-0000-000000000002',
        verseText: 'Do not be anxious about anything.',
        reference: 'Philippians 4:6-7',
        burdenHash: 'hash_fear_of_illness',
        tearSheetImagePath: null,
        completedAt: DateTime(2026, 11, 1, 21, 30),
      );

      await repo.saveTearSheet(sheet1);
      await repo.saveTearSheet(sheet2);

      final recovered = await repo.loadTearSheets();
      expect(recovered.length, equals(2));
      expect(recovered.any((s) => s.reference == 'John 15:5'), isTrue);
      expect(recovered.any((s) => s.reference == 'Philippians 4:6-7'), isTrue);
      expect(recovered.firstWhere((s) => s.reference == 'John 15:5').tearSheetImagePath, equals('/data/user/0/tear_sheet_1.png'));
    });
  });

  group('CommunityRepository Realtime & Multi-Room End-to-End Tests', () {
    test('fetches prayers segregated by cloister rooms (The Well, Circles, Valley)', () async {
      final repo = CommunityRepository();

      final wellPrayers = await repo.fetchPrayers(room: 'the_well');
      final circlePrayers = await repo.fetchPrayers(room: 'prayer_circles');
      final valleyPrayers = await repo.fetchPrayers(room: 'valley');

      // The Well holds only the pilgrim's own private petitions — never seeded.
      expect(wellPrayers.every((p) => p.room == 'the_well'), isTrue);
      expect(wellPrayers.where((p) => p.id.startsWith('well-seed')), isEmpty);

      expect(circlePrayers, isNotEmpty);
      expect(circlePrayers.every((p) => p.room == 'prayer_circles'), isTrue);

      expect(valleyPrayers, isNotEmpty);
      expect(valleyPrayers.every((p) => p.room == 'valley'), isTrue);
    });

    test('submits new prayer with valid UUID and receives update via stream watcher', () async {
      final repo = CommunityRepository();
      const testRoom = 'the_well';

      final stream = repo.watchPrayers(room: testRoom);
      final emittedLists = <List<CommunityPrayer>>[];
      final sub = stream.listen((list) => emittedLists.add(list));

      await Future<void>.delayed(const Duration(milliseconds: 50));

      final submitted = await repo.submitPrayer(
        room: testRoom,
        title: 'Grief and Longing for Revival',
        content: 'Carrying heavy burdens for our neighborhood families.',
        authorName: 'Sister Teresa',
      );

      // Verify UUID syntax conforms to Postgres UUID type
      expect(Uuid.isValidUUID(fromString: submitted.id), isTrue);
      expect(submitted.authorName, equals('Sister Teresa'));
      expect(submitted.room, equals(testRoom));
      expect(submitted.prayedCount, equals(1));

      await Future<void>.delayed(const Duration(milliseconds: 50));
      await sub.cancel();

      expect(emittedLists, isNotEmpty);
      expect(emittedLists.last.first.id, equals(submitted.id));
      expect(emittedLists.last.first.title, equals('Grief and Longing for Revival'));
    });

    test('prayFor increments intercession count and updates active stream', () async {
      final repo = CommunityRepository();
      const testRoom = 'prayer_circles';

      final list = await repo.fetchPrayers(room: testRoom);
      final target = list.first;
      final initialCount = target.prayedCount;

      await repo.prayFor(room: testRoom, prayerId: target.id);

      final updatedList = await repo.fetchPrayers(room: testRoom);
      final updated = updatedList.firstWhere((p) => p.id == target.id);
      expect(updated.prayedCount, equals(initialCount + 1));
    });

    test('CommunityPrayer serializes to/from JSON matching Postgres schema', () {
      final prayer = CommunityPrayer(
        id: '550e8400-e29b-41d4-a716-446655440000',
        userId: 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
        authorName: 'Pilgrim John',
        room: 'valley',
        title: 'Dark Night of the Soul',
        content: 'Waiting upon the Lord in silence.',
        voiceNoteUrl: 'https://storage.supabase.co/prayers/voice1.m4a',
        pastorName: 'Pastor Timothy',
        pastorResponse: 'The Lord is close to the brokenhearted.',
        prayedCount: 33,
        isAnswered: true,
        createdAt: DateTime(2026, 11, 2, 18, 0),
      );

      final json = prayer.toJson();
      expect(json['id'], equals('550e8400-e29b-41d4-a716-446655440000'));
      expect(json['user_id'], equals('f47ac10b-58cc-4372-a567-0e02b2c3d479'));
      expect(json['room'], equals('valley'));
      expect(json['pastor_name'], equals('Pastor Timothy'));
      expect(json['prayed_count'], equals(33));

      final deserialized = CommunityPrayer.fromJson(json);
      expect(deserialized, equals(prayer));
    });
  });

  group('APNS / FCM Notification Cloud Registration Tests', () {
    test('NotificationService registers valid 64-char hex token and syncs to SharedPreferences', () async {
      final notif = NotificationService.instance;
      final token = await notif.registerDevicePushToken(
        customToken: '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
        platform: 'ios',
      );

      expect(token.length, equals(64));
      expect(RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(token), isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('logos_apns_device_token'), equals(token));
    });
  });

  group('PostgreSQL Schema & Migration Syntax Validation', () {
    test('Phase 1 schema migration declares all 5 tables and enables RLS', () {
      final schemaFile = File('supabase/migrations/20261031_logos_schema.sql');
      expect(schemaFile.existsSync(), isTrue);
      final sql = schemaFile.readAsStringSync();

      // Verify core tables
      expect(sql.contains('CREATE TABLE IF NOT EXISTS public.profiles'), isTrue);
      expect(sql.contains('CREATE TABLE IF NOT EXISTS public.covenants'), isTrue);
      expect(sql.contains('CREATE TABLE IF NOT EXISTS public.journey_progress'), isTrue);
      expect(sql.contains('CREATE TABLE IF NOT EXISTS public.tear_sheets'), isTrue);
      expect(sql.contains('CREATE TABLE IF NOT EXISTS public.community_prayers'), isTrue);

      // Verify preferred_translation and pastoral fields
      expect(sql.contains('preferred_translation TEXT NOT NULL DEFAULT \'ESV\''), isTrue);
      expect(sql.contains('pastor_name TEXT'), isTrue);
      expect(sql.contains('prayed_count INT DEFAULT 0'), isTrue);

      // Verify Row Level Security on all tables
      expect(sql.contains('ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;'), isTrue);
      expect(sql.contains('ALTER TABLE public.covenants ENABLE ROW LEVEL SECURITY;'), isTrue);
      expect(sql.contains('ALTER TABLE public.journey_progress ENABLE ROW LEVEL SECURITY;'), isTrue);
      expect(sql.contains('ALTER TABLE public.tear_sheets ENABLE ROW LEVEL SECURITY;'), isTrue);
      expect(sql.contains('ALTER TABLE public.community_prayers ENABLE ROW LEVEL SECURITY;'), isTrue);
    });

    test('Phase 6 APNS migration declares device_push_tokens with unique constraints and RLS', () {
      final apnsFile = File('supabase/migrations/20261102_apns_push_tokens.sql');
      expect(apnsFile.existsSync(), isTrue);
      final sql = apnsFile.readAsStringSync();

      expect(sql.contains('CREATE TABLE IF NOT EXISTS public.device_push_tokens'), isTrue);
      expect(sql.contains('device_token TEXT NOT NULL UNIQUE'), isTrue);
      expect(sql.contains('ALTER TABLE public.device_push_tokens ENABLE ROW LEVEL SECURITY;'), isTrue);
      expect(sql.contains('CREATE POLICY "Users can register or upsert their push tokens"'), isTrue);
    });
  });
}
