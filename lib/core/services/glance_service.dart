import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/journey/bloc/journey_state.dart';
import '../../features/journey/data/week_design.dart';

const _dayNames = {1: 'Encounter', 2: 'Roots', 3: 'Stillness', 4: 'Exchange'};

/// Everything the home-screen widgets, lock screen and Live Activity show
/// (design 2a/2b): the week's verse, the rhythm, and when the next step opens.
@immutable
class GlanceSnapshot {
  final String reference;
  final String phrase;
  final int weekNumber;

  /// 'done' | 'today' | 'locked' for days 1–4.
  final List<String> days;
  final int doneCount;
  final int streak;

  /// 'today' (a step is open) · 'resting' (next opens at [unlockAt]) · 'complete'.
  final String status;
  final String headline;
  final String subline;
  final int nextDay;
  final String nextName;
  final DateTime? unlockAt;

  const GlanceSnapshot({
    required this.reference,
    required this.phrase,
    required this.weekNumber,
    required this.days,
    required this.doneCount,
    required this.streak,
    required this.status,
    required this.headline,
    required this.subline,
    required this.nextDay,
    required this.nextName,
    required this.unlockAt,
  });

  factory GlanceSnapshot.from(JourneyState s, {DateTime? now}) {
    final t = now ?? DateTime.now();
    final drop = s.activeDrop;
    final design = weekDesignFor(drop.weekNumber);
    final next = s.todayDay;
    final complete = next > 4;
    final open = !complete && s.isDayUnlocked(next, now: t);
    final days = [
      for (var d = 1; d <= 4; d++)
        s.dayCompletionStatus[d] == true ? 'done' : (d == next && open ? 'today' : 'locked'),
    ];
    final name = complete ? '' : _dayNames[next]!;
    final wait = complete || open ? null : s.timeUntilUnlock(next, now: t);
    return GlanceSnapshot(
      reference: drop.reference,
      phrase: shortPhrase(design.still),
      weekNumber: drop.weekNumber,
      days: days,
      doneCount: days.where((d) => d == 'done').length,
      streak: s.activeStreak(now: t),
      status: complete ? 'complete' : (open ? 'today' : 'resting'),
      headline: complete
          ? 'Week ${drop.weekNumber} kept'
          : open
              ? 'Day $next · Today'
              : '$name opens at midnight',
      subline: complete ? design.rest : 'Day $next · Week ${drop.weekNumber} · ${drop.reference}',
      nextDay: complete ? 0 : next,
      nextName: name,
      unlockAt: wait == null ? null : t.add(wait),
    );
  }

  /// “Abide in me, and I in you.” → Abide in me.
  static String shortPhrase(String still) {
    final bare = still.replaceAll(RegExp('[“”"]'), '').trim();
    final first = bare.split(',').first.trim();
    return first.endsWith('.') ? first : '$first.';
  }

  Map<String, Object> toWidgetData() => {
        'ref': reference.toUpperCase(),
        'phrase': phrase,
        'week': weekNumber,
        'days': days.join(','),
        'doneCount': doneCount,
        'streak': streak,
        'status': status,
        'headline': headline,
        'subline': subline,
        'nextDay': nextDay,
        'nextName': nextName,
        'unlockAt': unlockAt?.millisecondsSinceEpoch ?? 0,
      };
}

/// Pushes [GlanceSnapshot]s to the iOS WidgetKit / Android AppWidget
/// extensions and drives the iOS Live Activity (lock screen + Dynamic Island).
class GlanceService {
  GlanceService._();
  static final GlanceService instance = GlanceService._();

  static const appGroupId = 'group.com.logosinme.logosMobileApp';
  static const _iosKinds = ['LogosVerseWidget', 'LogosWeekWidget', 'LogosLockWidget'];
  static const _androidProviders = [
    'com.logosinme.logos_mobile_app.LogosVerseWidgetProvider',
    'com.logosinme.logos_mobile_app.LogosWeekWidgetProvider',
  ];
  static const _liveActivity = MethodChannel('logos/live_activity');
  static const _liveKey = 'logos_live_activity_enabled';

  bool _ready = false;
  bool _liveEnabled = true;
  String? _lastPushed;

  bool get liveActivityEnabled => _liveEnabled;

  bool get _supported => !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  Future<void> init() async {
    if (!_supported) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _liveEnabled = prefs.getBool(_liveKey) ?? true;
      if (Platform.isIOS) await HomeWidget.setAppGroupId(appGroupId);
      _ready = true;
    } catch (e) {
      debugPrint('[Glance] init failed: $e');
    }
  }

  Future<void> setLiveActivityEnabled(bool on, JourneyState s) async {
    _liveEnabled = on;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_liveKey, on);
    _lastPushed = null;
    await sync(s);
  }

  /// Writes the snapshot and refreshes every widget; starts, updates or ends
  /// the Live Activity. Cheap to call often: identical snapshots are skipped.
  Future<GlanceSnapshot> sync(JourneyState s, {bool force = false}) async {
    final snap = GlanceSnapshot.from(s);
    if (!_supported || !_ready || s.isLoading) return snap;
    final data = snap.toWidgetData();
    final key = data.toString();
    if (!force && key == _lastPushed) return snap;
    _lastPushed = key;
    try {
      for (final e in data.entries) {
        await HomeWidget.saveWidgetData(e.key, e.value);
      }
      if (Platform.isIOS) {
        for (final kind in _iosKinds) {
          await HomeWidget.updateWidget(iOSName: kind);
        }
      } else {
        for (final p in _androidProviders) {
          await HomeWidget.updateWidget(qualifiedAndroidName: p);
        }
      }
      if (Platform.isIOS) await _syncLiveActivity(snap, data);
    } catch (e) {
      debugPrint('[Glance] sync failed: $e');
    }
    return snap;
  }

  Future<void> _syncLiveActivity(GlanceSnapshot snap, Map<String, Object> data) async {
    try {
      final wantLive = _liveEnabled && snap.status == 'resting' && snap.unlockAt != null;
      if (wantLive) {
        await _liveActivity.invokeMethod('startOrUpdate', data);
      } else {
        await _liveActivity.invokeMethod('end');
      }
    } on PlatformException catch (e) {
      debugPrint('[Glance] live activity: ${e.message}');
    } on MissingPluginException {
      // Older iOS or no extension: widgets still work.
    }
  }
}
