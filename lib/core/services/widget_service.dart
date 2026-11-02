import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/journey/bloc/journey_state.dart';
import '../models/liturgical_widget_data.dart';

/// Coordinates data synchronization for iOS WidgetKit, Lock Screen, and Dynamic Island.
class LiturgicalWidgetService {
  static const String prefKeyWidgetPayload = 'logos_widget_payload_json';
  static const String prefKeyNextHourName = 'logos_widget_next_hour_name';
  static const String prefKeyNextHourTime = 'logos_widget_next_hour_time';
  static const String prefKeyScriptureRef = 'logos_widget_scripture_ref';
  static const String prefKeyStreak = 'logos_widget_streak';

  final SharedPreferences? prefs;

  LiturgicalWidgetService({this.prefs});

  Future<SharedPreferences> _getPrefs() async => prefs ?? await SharedPreferences.getInstance();

  /// Computes the active widget snapshot for a given JourneyState and clock time.
  LiturgicalWidgetData computeSnapshot({
    required JourneyState state,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final hourInfo = _resolveNextLiturgicalHour(current);

    final drop = state.activeDrop;
    String snippet = drop.verseText;
    if (snippet.contains('.')) {
      snippet = '${snippet.split('.').first.trim()}.';
    }

    final isUnlocked = state.isDayUnlocked(state.activeDay, now: current);

    return LiturgicalWidgetData(
      nextHourName: hourInfo.name,
      nextHourTime: hourInfo.formattedTime,
      countdownText: hourInfo.countdown,
      scriptureReference: drop.reference,
      scriptureSnippet: snippet,
      streakCount: state.currentStreak,
      rootsPlanted: state.rootsPlanted,
      graceTokens: state.graceTokensBalance,
      currentStep: state.activeDay,
      isPaceLocked: !isUnlocked,
      updatedAt: current,
    );
  }

  /// Serializes the current state into local preferences for WidgetKit consumption.
  Future<LiturgicalWidgetData> syncWidgetData({
    required JourneyState state,
    DateTime? now,
  }) async {
    final snapshot = computeSnapshot(state: state, now: now);
    try {
      final prefs = await _getPrefs();
      await prefs.setString(prefKeyWidgetPayload, snapshot.toJson());
      await prefs.setString(prefKeyNextHourName, snapshot.nextHourName);
      await prefs.setString(prefKeyNextHourTime, snapshot.nextHourTime);
      await prefs.setString(prefKeyScriptureRef, snapshot.scriptureReference);
      await prefs.setInt(prefKeyStreak, snapshot.streakCount);

      debugPrint('[WidgetService] Synced widget snapshot: ${snapshot.nextHourName} in ${snapshot.countdownText}');
    } catch (e) {
      debugPrint('[WidgetService] Sync warning (graceful continue): $e');
    }
    return snapshot;
  }

  /// Computes the chronological next liturgical prayer bell and countdown.
  _LiturgicalHourInfo _resolveNextLiturgicalHour(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);

    final lauds = today.add(const Duration(hours: 7));
    final sext = today.add(const Duration(hours: 12));
    final vespers = today.add(const Duration(hours: 21));
    final midnight = today.add(const Duration(days: 1, minutes: 1)); // 12:01 AM next day

    DateTime target;
    String name;
    String formattedTime;

    if (now.isBefore(lauds)) {
      target = lauds;
      name = 'Morning Lauds';
      formattedTime = '7:00 AM';
    } else if (now.isBefore(sext)) {
      target = sext;
      name = 'Noonday Sext';
      formattedTime = '12:00 PM';
    } else if (now.isBefore(vespers)) {
      target = vespers;
      name = 'Evening Vespers';
      formattedTime = '9:00 PM';
    } else {
      target = midnight;
      name = 'Midnight Strike';
      formattedTime = '12:01 AM';
    }

    final diff = target.difference(now);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;

    String countdown;
    if (hours > 0) {
      countdown = '${hours}h ${minutes}m';
    } else {
      countdown = '${minutes}m';
    }

    return _LiturgicalHourInfo(
      name: name,
      formattedTime: formattedTime,
      countdown: countdown,
    );
  }
}

class _LiturgicalHourInfo {
  final String name;
  final String formattedTime;
  final String countdown;

  const _LiturgicalHourInfo({
    required this.name,
    required this.formattedTime,
    required this.countdown,
  });
}
