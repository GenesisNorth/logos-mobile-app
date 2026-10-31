import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

/// Centralized service managing Supabase initialization, anonymous authentication,
/// and live database access with graceful offline handling.
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Whether Supabase credentials are configured via build defines or environment.
  bool get isConfigured => AppConfig.hasSupabase;

  /// Direct client accessor (null when running in pure offline/unconfigured mode).
  SupabaseClient? get client => _isInitialized ? Supabase.instance.client : null;

  /// Current authenticated user ID (anonymous or registered).
  String? get currentUserId => client?.auth.currentUser?.id;

  /// Initializes Supabase and guarantees an active anonymous or authenticated session.
  /// If credentials are missing or the device is offline, this fails gracefully.
  Future<void> initialize() async {
    if (!isConfigured) {
      debugPrint('[SupabaseService] No SUPABASE_URL / ANON_KEY defined. Running in offline-first mode.');
      return;
    }

    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: AppConfig.supabaseAnonKey,
      );
      _isInitialized = true;
      debugPrint('[SupabaseService] Initialized successfully with ${AppConfig.supabaseUrl}');

      // Ensure seeker has an anonymous or persistent session
      await ensureSession();
    } catch (e, stack) {
      debugPrint('[SupabaseService] Initialization warning (app will use local storage): $e');
      if (kDebugMode) {
        debugPrint(stack.toString());
      }
    }
  }

  /// Ensures an active session is available without prompting the user.
  /// Uses anonymous auth so every pilgrim gets a persistent UUID in Supabase.
  Future<void> ensureSession() async {
    final c = client;
    if (c == null) return;

    try {
      if (c.auth.currentUser == null) {
        debugPrint('[SupabaseService] Establishing anonymous pilgrim session...');
        await c.auth.signInAnonymously();
        debugPrint('[SupabaseService] Anonymous session active: ${c.auth.currentUser?.id}');
      }
    } catch (e) {
      debugPrint('[SupabaseService] Anonymous session creation warning: $e');
    }
  }
}
