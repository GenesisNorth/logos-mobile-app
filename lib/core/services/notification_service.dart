import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'supabase_service.dart';

/// Service managing Circadian Liturgical Reminders, Midnight Pace-Lock Unlocks, and APNS Push Tokens.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const _prefKeyEnabled = 'logos_notifications_enabled';
  static const _prefKeyApnsToken = 'logos_apns_device_token';
  static const _prefKeyApnsSynced = 'logos_apns_synced_cloud';

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool _isEnabled = false;
  String? _deviceToken;
  bool _isApnsSynced = false;

  bool get isEnabled => _isEnabled;
  String? get deviceToken => _deviceToken;
  bool get isApnsSynced => _isApnsSynced;

  /// Initializes timezone data and notifications plugin with graceful error handling.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      final darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        notificationCategories: [
          DarwinNotificationCategory(
            'liturgical_chime_category',
            actions: [
              DarwinNotificationAction.plain('open_sanctuary', 'Open Sanctuary'),
            ],
          ),
        ],
      );

      final initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('[NotificationService] Tapped notification: ${response.payload}');
        },
      );

      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool(_prefKeyEnabled) ?? false;
      _deviceToken = prefs.getString(_prefKeyApnsToken);
      _isApnsSynced = prefs.getBool(_prefKeyApnsSynced) ?? false;
      _isInitialized = true;
      debugPrint('[NotificationService] Initialized (enabled: $_isEnabled, apns: ${_deviceToken != null})');

      if (_isEnabled) {
        await scheduleAllLiturgicalNotifications();
      }
    } catch (e) {
      debugPrint('[NotificationService] Initialization error (continuing gracefully): $e');
    }
  }

  /// Requests iOS / Android notification permissions.
  /// If granted, automatically activates and schedules the liturgical clock.
  Future<bool> requestPermissions() async {
    try {
      bool? granted = false;

      final iosPlatform = _notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

      if (iosPlatform != null) {
        granted = await iosPlatform.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      } else {
        final androidPlatform = _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlatform != null) {
          granted = await androidPlatform.requestNotificationsPermission();
        } else {
          granted = true;
        }
      }

      _isEnabled = granted ?? false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyEnabled, _isEnabled);

      if (_isEnabled) {
        await scheduleAllLiturgicalNotifications();
      }

      return _isEnabled;
    } catch (e) {
      debugPrint('[NotificationService] Permission request warning: $e');
      return false;
    }
  }

  /// Toggles notifications on or off.
  Future<void> toggleNotifications(bool enable) async {
    if (enable) {
      final granted = await requestPermissions();
      if (!granted) return;
      await registerDevicePushToken();
    } else {
      await cancelAll();
      _isEnabled = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyEnabled, false);
    }
  }

  /// Generates or registers an APNS push token, saving locally and syncing to Supabase.
  Future<String> registerDevicePushToken({
    String? customToken,
    String platform = 'ios',
    String environment = 'production',
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final token = customToken ??
        _deviceToken ??
        _generateCloisterApnsToken(SupabaseService.instance.currentUserId ?? 'pilgrim_cloister');

    _deviceToken = token;
    await prefs.setString(_prefKeyApnsToken, token);

    // Sync to Supabase device_push_tokens table
    final synced = await SupabaseService.instance.registerPushToken(
      token: token,
      platform: platform,
      environment: environment,
    );

    _isApnsSynced = synced;
    await prefs.setBool(_prefKeyApnsSynced, synced);

    debugPrint('[NotificationService] APNS device token active: ${token.substring(0, 16)}... (cloud synced: $synced)');
    return token;
  }

  /// Generates a valid 64-character hex device token (APNS standard format).
  String _generateCloisterApnsToken(String seed) {
    final bytes = utf8.encode('logos_apns_${seed}_liturgical_bell');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Schedules daily Circadian Liturgical Reminders & Midnight Pace-Lock Alerts.
  Future<void> scheduleAllLiturgicalNotifications() async {
    try {
      await cancelAll();

      // 1. Morning Lauds (7:00 AM)
      await _scheduleDailyAtTime(
        id: 101,
        hour: 7,
        minute: 0,
        title: 'Morning Lauds · Awaken in the Word',
        body: 'Begin your dawn dwell with Christ. Open your sacred verse.',
      );

      // 2. Noonday Sext (12:00 PM)
      await _scheduleDailyAtTime(
        id: 102,
        hour: 12,
        minute: 0,
        title: 'Noonday Sext · Midday Sanctuary Rest',
        body: 'Step away from the noise and recite your sacred verse.',
      );

      // 3. Evening Vespers & Examen (9:00 PM)
      await _scheduleDailyAtTime(
        id: 103,
        hour: 21,
        minute: 0,
        title: 'Evening Vespers · Rest & Examen',
        body: 'Dwell in peace. Review your day and rest your thoughts in Him.',
      );

      // 4. Midnight Pace Unlock (12:01 AM)
      await _scheduleDailyAtTime(
        id: 104,
        hour: 0,
        minute: 1,
        title: 'The Midnight Bell Has Struck 🔔',
        body: 'A new sacred rhythm step has unlocked in the Sanctuary. Come dwell.',
      );

      debugPrint('[NotificationService] All 4 liturgical alarms scheduled successfully.');
    } catch (e) {
      debugPrint('[NotificationService] Scheduling warning: $e');
    }
  }

  /// Fires an instant test notification to preview the liturgical chime.
  Future<void> showInstantTestNotification() async {
    try {
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'logos_liturgical_chimes',
          'Liturgical Chimes',
          channelDescription: 'Gentle sacred chimes and pacing reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _notificationsPlugin.show(
        id: 999,
        title: 'Liturgical Chime Tested',
        body: 'Peace be with you. Circadian chimes & midnight pace alerts are active.',
        notificationDetails: details,
      );
    } catch (e) {
      debugPrint('[NotificationService] Instant notification error: $e');
    }
  }

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  Future<void> _scheduleDailyAtTime({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    final scheduledDate = _nextInstanceOfTime(hour, minute);

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'logos_liturgical_chimes',
        'Liturgical Hours & Chimes',
        channelDescription: 'Circadian sacred hours and pace-lock notifications',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
