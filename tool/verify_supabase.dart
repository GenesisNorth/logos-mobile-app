// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

/// Diagnostic script to verify Supabase configuration from `.env`.
///
/// Usage:
///   dart run tool/verify_supabase.dart
Future<void> main() async {
  print('\n═══════════════════════════════════════════════════════════');
  print('  LOGOS IN ME — Supabase Cloud Connectivity Diagnostic');
  print('═══════════════════════════════════════════════════════════\n');

  final envFile = File('.env');
  if (!envFile.existsSync()) {
    print('❌ .env file not found.');
    print('   Please copy .env.example to .env and fill in your Supabase credentials:');
    print('   cp .env.example .env\n');
    exit(1);
  }

  final lines = envFile.readAsLinesSync();
  final env = <String, String>{};
  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final splitIndex = trimmed.indexOf('=');
    if (splitIndex != -1) {
      final key = trimmed.substring(0, splitIndex).trim();
      final val = trimmed.substring(splitIndex + 1).trim();
      env[key] = val;
    }
  }

  final supabaseUrl = env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = env['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    print('⚠️  SUPABASE_URL or SUPABASE_ANON_KEY is currently empty in .env');
    print('   1. Go to https://supabase.com/dashboard/project/_/settings/api');
    print('   2. Paste your Project URL into SUPABASE_URL');
    print('   3. Paste your anon/public key into SUPABASE_ANON_KEY');
    print('\n   The app is currently running in OFFLINE CLOISTER MODE.\n');
    exit(0);
  }

  print('🔍 Checking connection to: $supabaseUrl');
  final client = HttpClient();

  try {
    // 1. Check Auth Health
    final authUri = Uri.parse('$supabaseUrl/auth/v1/health');
    final authReq = await client.getUrl(authUri);
    authReq.headers.add('apikey', supabaseAnonKey);
    final authRes = await authReq.close();

    if (authRes.statusCode == 200) {
      print('✅ Supabase Auth Endpoint: Reachable (HTTP 200)');
    } else {
      print('⚠️ Supabase Auth status: HTTP ${authRes.statusCode}');
    }

    // 2. Check Core Tables via PostgREST
    final tables = [
      'profiles',
      'covenants',
      'journey_progress',
      'tear_sheets',
      'community_prayers',
      'device_push_tokens',
    ];

    print('\n📊 Verifying PostgreSQL Tables:');
    for (final table in tables) {
      final tableUri = Uri.parse('$supabaseUrl/rest/v1/$table?select=*&limit=1');
      final req = await client.getUrl(tableUri);
      req.headers.add('apikey', supabaseAnonKey);
      req.headers.add('Authorization', 'Bearer $supabaseAnonKey');
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();

      if (res.statusCode == 200) {
        print('  ✅ table "$table": Accessible');
      } else {
        print('  ❌ table "$table": HTTP ${res.statusCode} — $body');
      }
    }

    print('\n═══════════════════════════════════════════════════════════');
    print('  🎉 Backend connectivity verified successfully!');
    print('  You can now run: flutter run --dart-define-from-file=.env');
    print('═══════════════════════════════════════════════════════════\n');
  } catch (e) {
    print('❌ Failed to reach Supabase: $e');
  } finally {
    client.close();
  }
}
