import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
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
  static const _prefKeyReminderMinutes = 'logos_reminder_minutes_of_day';
  static const _prefKeyEvening = 'logos_evening_reflection_enabled';

  /// Default daily reminder: 7:00 AM.
  static const defaultReminderMinutes = 7 * 60;

  /// Evening reflection reminder time: 9:00 PM.
  static const eveningMinutes = 21 * 60;

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool _isEnabled = false;
  String? _deviceToken;
  bool _isApnsSynced = false;

  int _reminderMinutes = defaultReminderMinutes;
  bool _eveningReflection = true;

  bool get isEnabled => _isEnabled;

  /// Minutes after local midnight for the daily practice reminder.
  int get reminderMinutes => _reminderMinutes;
  bool get eveningReflection => _eveningReflection;
  String? get deviceToken => _deviceToken;
  bool get isApnsSynced => _isApnsSynced;

  /// Initializes timezone data and notifications plugin with graceful error handling.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();
      // Schedule in the device's own time zone (tz.local defaults to UTC).
      try {
        final zone = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(zone.identifier));
      } catch (e) {
        debugPrint('[NotificationService] Could not resolve local time zone: $e');
      }

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
      _reminderMinutes = prefs.getInt(_prefKeyReminderMinutes) ?? defaultReminderMinutes;
      _eveningReflection = prefs.getBool(_prefKeyEvening) ?? true;
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
      // Remote push (FCM/APNs) arrives with the backend; local reminders need no token.
      await requestPermissions();
    } else {
      await cancelAll();
      _isEnabled = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyEnabled, false);
    }
  }

  /// Generates or registers a push token (APNS / FCM), saving locally and syncing to Supabase.
  Future<String> registerDevicePushToken({
    String? customToken,
    String? platform,
    String environment = 'production',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final activePlatform = platform ??
        (defaultTargetPlatform == TargetPlatform.android ? 'android' : 'ios');

    final token = customToken ??
        _deviceToken ??
        _generateCloisterApnsToken(SupabaseService.instance.currentUserId ?? 'pilgrim_cloister');

    _deviceToken = token;
    await prefs.setString(_prefKeyApnsToken, token);

    // Sync to Supabase device_push_tokens table
    final synced = await SupabaseService.instance.registerPushToken(
      token: token,
      platform: activePlatform,
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

  /// Changes the daily reminder time and reschedules if reminders are on.
  Future<void> setReminderMinutes(int minutesOfDay) async {
    _reminderMinutes = minutesOfDay.clamp(0, 24 * 60 - 1);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKeyReminderMinutes, _reminderMinutes);
    if (_isEnabled) await scheduleAllLiturgicalNotifications();
  }

  Future<void> setEveningReflection(bool enabled) async {
    _eveningReflection = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyEvening, enabled);
    if (_isEnabled) await scheduleAllLiturgicalNotifications();
  }

  /// Schedules the daily practice reminder and the optional evening reflection.
  /// (No midnight alert: a new step simply waits for the morning reminder.)
  Future<void> scheduleAllLiturgicalNotifications() async {
    try {
      await cancelAll();

      await _scheduleDailyAtTime(
        id: 101,
        hour: _reminderMinutes ~/ 60,
        minute: _reminderMinutes % 60,
        title: 'Your verse is waiting',
        body: 'Take a few unhurried minutes with today’s step.',
      );

      if (_eveningReflection) {
        await _scheduleDailyAtTime(
          id: 103,
          hour: eveningMinutes ~/ 60,
          minute: eveningMinutes % 60,
          title: 'Evening reflection',
          body: 'Where did you sense Christ today? Rest in His word before sleep.',
        );
      }

      debugPrint('[NotificationService] Reminders scheduled (daily ${_reminderMinutes ~/ 60}:${(_reminderMinutes % 60).toString().padLeft(2, '0')}, evening: $_eveningReflection).');
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
        'logos_daily_reminders',
        'Daily reminders',
        channelDescription: 'Your daily practice reminder and evening reflection',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
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
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
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
