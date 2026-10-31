import 'package:flutter/foundation.dart';
import '../../../core/services/supabase_service.dart';
import 'progress_repository.dart';

/// Offline-first ProgressRepository that guarantees instant local responsiveness
/// while synchronizing seeker state, covenants, and sacred rhythm milestones
/// to Supabase Postgres in the background.
class SupabaseProgressRepository implements ProgressRepository {
  final LocalProgressRepository _local = LocalProgressRepository();
  final SupabaseService _supabase = SupabaseService.instance;

  @override
  Future<UserProfileData> loadProfile() async {
    // 1. Always load local cache first for instant startup
    var profile = await _local.loadProfile();

    final client = _supabase.client;
    final uid = _supabase.currentUserId;
    if (client == null || uid == null) return profile;

    // 2. Attempt cloud reconciliation in the background
    try {
      final profileRow = await client
          .from('profiles')
          .select()
          .eq('id', uid)
          .maybeSingle();

      final covenantRow = await client
          .from('covenants')
          .select()
          .eq('user_id', uid)
          .maybeSingle();

      if (profileRow != null) {
        profile = UserProfileData(
          username: profileRow['username'] as String? ?? profile.username,
          displayName: profileRow['display_name'] as String? ?? profile.displayName,
          birthMonth: profileRow['birth_month'] as int? ?? profile.birthMonth,
          birthDay: profileRow['birth_day'] as int? ?? profile.birthDay,
          covenantSignature: covenantRow?['signature_text'] as String? ?? profile.covenantSignature,
          covenantSignedAt: covenantRow?['signed_at'] != null
              ? DateTime.tryParse(covenantRow!['signed_at'] as String)
              : profile.covenantSignedAt,
        );
        // Update local cache with remote source of truth
        await _local.saveProfile(profile);
      }
    } catch (e) {
      debugPrint('[SupabaseProgressRepository] Profile cloud fetch fallback: $e');
    }

    return profile;
  }

  @override
  Future<void> saveProfile(UserProfileData profile) async {
    // 1. Save locally immediately
    await _local.saveProfile(profile);

    final client = _supabase.client;
    final uid = _supabase.currentUserId;
    if (client == null || uid == null) return;

    // 2. Sync to Supabase in background
    try {
      await client.from('profiles').upsert({
        'id': uid,
        'username': profile.username,
        'display_name': profile.displayName,
        'birth_month': profile.birthMonth,
        'birth_day': profile.birthDay,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (profile.hasSignedCovenant) {
        await client.from('covenants').upsert({
          'user_id': uid,
          'signature_text': profile.covenantSignature,
          'signed_at': profile.covenantSignedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('[SupabaseProgressRepository] Profile cloud sync warning: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> loadJourneyData() async {
    var data = await _local.loadJourneyData();

    final client = _supabase.client;
    final uid = _supabase.currentUserId;
    if (client == null || uid == null) return data;

    try {
      final row = await client
          .from('journey_progress')
          .select()
          .eq('user_id', uid)
          .maybeSingle();

      if (row != null) {
        final remoteData = <String, dynamic>{
          'weekIndex': row['week_index'] as int? ?? 0,
          'activeDay': row['active_day'] as int? ?? 1,
          'dayCompletion': row['day_completion'] as Map<String, dynamic>? ?? {},
          'dayCompletedAt': row['day_completed_at'] as Map<String, dynamic>? ?? {},
          'dayRecitationCount': row['day_recitation_count'] as Map<String, dynamic>? ?? {},
          'isExchangeCompleted': row['is_exchange_completed'] as bool? ?? false,
        };

        // If remote has progressed, adopt it
        data = remoteData;
        await _local.saveJourneyData(data);
      }
    } catch (e) {
      debugPrint('[SupabaseProgressRepository] Journey cloud fetch fallback: $e');
    }

    return data;
  }

  @override
  Future<void> saveJourneyData(Map<String, dynamic> data) async {
    await _local.saveJourneyData(data);

    final client = _supabase.client;
    final uid = _supabase.currentUserId;
    if (client == null || uid == null) return;

    try {
      await client.from('journey_progress').upsert({
        'user_id': uid,
        'week_index': data['weekIndex'] ?? 0,
        'active_day': data['activeDay'] ?? 1,
        'day_completion': data['dayCompletion'] ?? {},
        'day_completed_at': data['dayCompletedAt'] ?? {},
        'day_recitation_count': data['dayRecitationCount'] ?? {},
        'is_exchange_completed': data['isExchangeCompleted'] ?? false,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[SupabaseProgressRepository] Journey cloud sync warning: $e');
    }
  }

  @override
  Future<List<TearSheetData>> loadTearSheets() async {
    final localSheets = await _local.loadTearSheets();

    final client = _supabase.client;
    final uid = _supabase.currentUserId;
    if (client == null || uid == null) return localSheets;

    try {
      final rows = await client
          .from('tear_sheets')
          .select()
          .eq('user_id', uid)
          .order('completed_at', ascending: false);

      if (rows.isNotEmpty) {
        final cloudSheets = rows.map((r) => TearSheetData(
              id: r['id'] as String,
              dropId: r['drop_id'] as String,
              verseText: r['verse_text'] as String,
              reference: r['reference'] as String,
              burdenHash: r['burden_hash'] as String,
              tearSheetImagePath: r['tear_sheet_image_path'] as String?,
              completedAt: DateTime.parse(r['completed_at'] as String),
            )).toList();

        return cloudSheets;
      }
    } catch (e) {
      debugPrint('[SupabaseProgressRepository] Tear sheets cloud fetch fallback: $e');
    }

    return localSheets;
  }

  @override
  Future<void> saveTearSheet(TearSheetData sheet) async {
    await _local.saveTearSheet(sheet);

    final client = _supabase.client;
    final uid = _supabase.currentUserId;
    if (client == null || uid == null) return;

    try {
      await client.from('tear_sheets').upsert({
        'id': sheet.id,
        'user_id': uid,
        'drop_id': sheet.dropId,
        'verse_text': sheet.verseText,
        'reference': sheet.reference,
        'burden_hash': sheet.burdenHash,
        'tear_sheet_image_path': sheet.tearSheetImagePath,
        'completed_at': sheet.completedAt.toIso8601String(),
      });
    } catch (e) {
      debugPrint('[SupabaseProgressRepository] Tear sheet cloud sync warning: $e');
    }
  }
}
