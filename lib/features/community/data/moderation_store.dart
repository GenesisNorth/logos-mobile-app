import 'package:shared_preferences/shared_preferences.dart';

/// Reasons offered when reporting a community post.
const reportReasons = [
  'Harmful or unkind',
  'Not lament / off-topic',
  'Spam or promotion',
  'Someone may be at risk',
];

/// Remembers posts the pilgrim hid or reported on this device.
///
/// Phase B: [report] also sends the report to the moderation queue in the
/// admin console; hidden posts stay a personal, local preference.
class ModerationStore {
  static const _hiddenKey = 'logos_hidden_posts';
  static const _reportsKey = 'logos_reported_posts';

  Future<Set<String>> hiddenIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_hiddenKey) ?? const []).toSet();
  }

  Future<void> hide(String postId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = (prefs.getStringList(_hiddenKey) ?? <String>[]).toSet()..add(postId);
    await prefs.setStringList(_hiddenKey, ids.toList());
  }

  /// Records a report (post id + reason) and hides the post for this user.
  Future<void> report(String postId, String reason) async {
    final prefs = await SharedPreferences.getInstance();
    final reports = prefs.getStringList(_reportsKey) ?? <String>[];
    reports.add('$postId|$reason|${DateTime.now().toIso8601String()}');
    await prefs.setStringList(_reportsKey, reports);
    await hide(postId);
  }

  Future<List<String>> pendingReports() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_reportsKey) ?? const [];
  }
}
