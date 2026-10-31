import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/services/supabase_service.dart';
import '../models/community_prayer.dart';

class CommunityRepository {
  static final CommunityRepository _instance = CommunityRepository._internal();
  factory CommunityRepository() => _instance;
  CommunityRepository._internal();

  final Map<String, List<CommunityPrayer>> _cache = {
    'the_well': [
      CommunityPrayer(
        id: 'well-seed-1',
        authorName: 'Genesis A.',
        room: 'the_well',
        title: 'Ministry Burnout & Exhaustion',
        content: 'Navigating severe burnout in ministry and loneliness. Struggling to pray.',
        pastorName: 'Pastor Thomas M.',
        pastorResponse:
            'Beloved Genesis, I carried your name to the altar this morning. Remember: your labor is not what justifies you; your abiding in Christ is your life. Rest your soul today.',
        prayedCount: 14,
        isAnswered: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 18)),
      ),
      CommunityPrayer(
        id: 'well-seed-2',
        authorName: 'Sister Miriam',
        room: 'the_well',
        title: 'Waiting in Chronic Illness',
        content: 'Facing another month of unknown diagnostic tests. Needing peace to stay grounded in Colossians 3.',
        pastorName: 'Pastor Ruth C.',
        pastorResponse:
            'Miriam, your life is hidden with Christ in God. Disease touches the outer frame, but your eternal temple is untouched. We intercede for peace that transcends understanding.',
        prayedCount: 22,
        isAnswered: true,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ],
    'prayer_circles': [
      CommunityPrayer(
        id: 'circle-seed-1',
        authorName: 'Sarah K.',
        room: 'prayer_circles',
        title: 'Praying with you',
        content: 'Lifting everyone walking through the quiet seasons today. His grace is abundant.',
        prayedCount: 38,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
      CommunityPrayer(
        id: 'circle-seed-2',
        authorName: 'David M.',
        room: 'prayer_circles',
        title: 'The peace of Christ guard you',
        content: 'Standing in agreement for reconciliation and emotional healing in families.',
        prayedCount: 19,
        createdAt: DateTime.now().subtract(const Duration(hours: 14)),
      ),
    ],
    'valley': [
      CommunityPrayer(
        id: 'valley-seed-1',
        authorName: 'Pilgrim in Austin',
        room: 'valley',
        title: 'The Lord is near to the brokenhearted',
        content: 'Lost my father three weeks ago. Sitting in Psalm 34 today. Just knowing I don’t have to perform faith right now is carrying me.',
        prayedCount: 47,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      CommunityPrayer(
        id: 'valley-seed-2',
        authorName: 'Brother in Nairobi',
        room: 'valley',
        title: 'Even though I walk through the valley',
        content: 'I thought weeping was a sign of weak faith. The Psalms taught me that lament is worship.',
        prayedCount: 61,
        createdAt: DateTime.now().subtract(const Duration(hours: 22)),
      ),
    ],
  };

  final Map<String, StreamController<List<CommunityPrayer>>> _controllers = {};

  Stream<List<CommunityPrayer>> watchPrayers({required String room}) {
    if (!_controllers.containsKey(room)) {
      _controllers[room] = StreamController<List<CommunityPrayer>>.broadcast();
    }
    // Emit initial cached list
    fetchPrayers(room: room).then((list) {
      if (!_controllers[room]!.isClosed) {
        _controllers[room]!.add(list);
      }
    });

    // If Supabase is connected, subscribe to live changes
    _setupSupabaseRealtime(room);

    return _controllers[room]!.stream;
  }

  void _setupSupabaseRealtime(String room) {
    final client = SupabaseService.instance.client;
    if (client == null) return;

    try {
      client
          .from('community_prayers')
          .stream(primaryKey: ['id'])
          .eq('room', room)
          .order('created_at', ascending: false)
          .listen(
            (rows) {
              final remoteList = rows.map((r) => CommunityPrayer.fromJson(r)).toList();
              if (remoteList.isNotEmpty) {
                _cache[room] = remoteList;
                if (_controllers.containsKey(room) && !_controllers[room]!.isClosed) {
                  _controllers[room]!.add(remoteList);
                }
              }
            },
            onError: (err) {
              debugPrint('[CommunityRepository] Realtime subscription notice: $err');
            },
          );
    } catch (e) {
      debugPrint('[CommunityRepository] Realtime setup warning: $e');
    }
  }

  Future<List<CommunityPrayer>> fetchPrayers({required String room}) async {
    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        final res = await client
            .from('community_prayers')
            .select()
            .eq('room', room)
            .order('created_at', ascending: false)
            .limit(30);

        final remotePrayers = (res as List)
            .map((r) => CommunityPrayer.fromJson(r as Map<String, dynamic>))
            .toList();

        if (remotePrayers.isNotEmpty) {
          _cache[room] = remotePrayers;
          return remotePrayers;
        }
      } catch (e) {
        debugPrint('[CommunityRepository] Remote fetch notice (using cache): $e');
      }
    }
    return _cache[room] ?? [];
  }

  Future<CommunityPrayer> submitPrayer({
    required String room,
    required String title,
    required String content,
    String? authorName,
    String? voiceNoteUrl,
  }) async {
    final newPrayer = CommunityPrayer(
      id: 'prayer-${DateTime.now().millisecondsSinceEpoch}',
      userId: SupabaseService.instance.currentUserId,
      authorName: authorName ?? 'Beloved Pilgrim',
      room: room,
      title: title,
      content: content,
      voiceNoteUrl: voiceNoteUrl,
      pastorName: room == 'the_well' ? 'Assigned Pastoral Shepherd' : null,
      pastorResponse: room == 'the_well'
          ? 'Your petition is received into our Sanctuary watch. An ordained pastor is interceding over your words and preparing a personalized response.'
          : null,
      prayedCount: 1,
      isAnswered: false,
      createdAt: DateTime.now(),
    );

    // Optimistically prepend to cache
    _cache.putIfAbsent(room, () => []);
    _cache[room]!.insert(0, newPrayer);

    if (_controllers.containsKey(room) && !_controllers[room]!.isClosed) {
      _controllers[room]!.add(_cache[room]!);
    }

    // Push to Supabase if configured
    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('community_prayers').insert(newPrayer.toJson());
        debugPrint('[CommunityRepository] Prayer synced to Supabase: ${newPrayer.id}');
      } catch (e) {
        debugPrint('[CommunityRepository] Sync warning (persisted locally): $e');
      }
    }

    return newPrayer;
  }

  Future<void> prayFor({required String room, required String prayerId}) async {
    final list = _cache[room];
    if (list != null) {
      final index = list.indexWhere((p) => p.id == prayerId);
      if (index != -1) {
        final existing = list[index];
        list[index] = existing.copyWith(prayedCount: existing.prayedCount + 1);
        if (_controllers.containsKey(room) && !_controllers[room]!.isClosed) {
          _controllers[room]!.add(list);
        }
      }
    }
  }
}
