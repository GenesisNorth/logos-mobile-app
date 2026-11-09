import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Feature flags and remote-configurable values.
///
/// Today: bundled defaults, plus any overrides cached on the device.
/// Phase B: the admin console writes an `app_config` row in Supabase; the app
/// fetches it on launch, calls [applyRemote], and the cache keeps it offline.
class AppFlags extends ChangeNotifier {
  AppFlags._();
  static final AppFlags instance = AppFlags._();

  static const _cacheKey = 'logos_app_flags_cache';

  // Community rooms
  static const roomPrayerCircles = 'room_prayer_circles';
  static const roomValley = 'room_valley';
  static const roomTheWell = 'room_the_well';
  static const roomStudyPods = 'room_study_pods';
  static const roomVoiceComfort = 'room_voice_comfort';
  static const roomMilestones = 'room_milestones';
  static const streakFamily = 'streak_family';

  // Features
  static const scripturePacks = 'scripture_packs';

  // Config values
  static const privacyUrl = 'privacy_url';
  static const termsUrl = 'terms_url';
  static const supportEmail = 'support_email';
  static const crisisLineLabel = 'crisis_line_label';
  static const crisisLineUri = 'crisis_line_uri';
  static const crisisDirectoryUrl = 'crisis_directory_url';

  static const Map<String, Object> defaults = {
    roomPrayerCircles: true,
    roomValley: true,
    roomTheWell: true,
    roomStudyPods: false,
    roomVoiceComfort: false,
    roomMilestones: false,
    streakFamily: false,
    scripturePacks: false,
    privacyUrl: '',
    termsUrl: '',
    supportEmail: '',
    crisisLineLabel: 'In the US, call or text 988',
    crisisLineUri: 'tel:988',
    crisisDirectoryUrl: 'https://findahelpline.com',
  };

  final Map<String, Object> _overrides = {};

  bool isOn(String key) => (_overrides[key] ?? defaults[key]) == true;

  String text(String key) => (_overrides[key] ?? defaults[key] ?? '').toString();

  /// Loads overrides cached from the last remote fetch.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw != null) {
        _overrides
          ..clear()
          ..addAll((jsonDecode(raw) as Map<String, dynamic>).cast<String, Object>());
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[AppFlags] cache load failed: $e');
    }
  }

  /// Applies values fetched from the admin-managed remote config and caches them.
  Future<void> applyRemote(Map<String, Object> values) async {
    _overrides
      ..clear()
      ..addAll(values);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(_overrides));
  }

  @visibleForTesting
  void setForTest(Map<String, Object> values) {
    _overrides
      ..clear()
      ..addAll(values);
    notifyListeners();
  }
}
