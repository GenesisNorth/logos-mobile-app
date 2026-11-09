import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The three Examen questions from the design.
const examenQuestions = [
  'Where did you notice His nearness today?',
  'Where did you resist abiding?',
  'What will you carry into tomorrow?',
];

const examenHints = ['Tonight I noticed…', 'I held back when…', 'Tomorrow I’ll carry…'];

class ExamenEntry {
  final DateTime date;
  final List<String> answers;
  const ExamenEntry(this.date, this.answers);

  Map<String, dynamic> toJson() => {'date': date.toIso8601String(), 'answers': answers};
  factory ExamenEntry.fromJson(Map<String, dynamic> j) =>
      ExamenEntry(DateTime.parse(j['date'] as String), (j['answers'] as List).cast<String>());
}

/// Evening Examen: on-device only — "No one else will read this."
class ExamenStore extends ChangeNotifier {
  ExamenStore._();
  static final ExamenStore instance = ExamenStore._();

  static const _enabledKey = 'logos_examen_evenings';
  static const _entriesKey = 'logos_examen_entries';

  bool _enabled = true;
  List<ExamenEntry> _entries = [];

  bool get eveningsEnabled => _enabled;
  List<ExamenEntry> get entries => List.unmodifiable(_entries);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_enabledKey) ?? true;
      _entries = (prefs.getStringList(_entriesKey) ?? const [])
          .map((e) => ExamenEntry.fromJson(jsonDecode(e) as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('[ExamenStore] load failed: $e');
    }
  }

  Future<void> setEveningsEnabled(bool on) async {
    _enabled = on;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, on);
  }

  Future<void> save(List<String> answers, {DateTime? now}) async {
    // An examen kept after midnight belongs to the evening before.
    final t = now ?? DateTime.now();
    final evening = t.hour < 5 ? t.subtract(const Duration(days: 1)) : t;
    _entries = [..._entries, ExamenEntry(evening, answers)];
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_entriesKey, _entries.map((e) => jsonEncode(e.toJson())).toList());
  }

  bool doneOn(DateTime day) =>
      _entries.any((e) => e.date.year == day.year && e.date.month == day.month && e.date.day == day.day);

  /// Examen evenings run 8 PM – 5 AM (the night palette hours).
  static bool isEvening(DateTime t) => t.hour >= 20 || t.hour < 5;

  /// Show the Examen card tonight?
  bool shouldOffer(DateTime now) {
    if (!_enabled || !isEvening(now)) return false;
    // After midnight the examen belongs to the previous day.
    final day = now.hour < 5 ? now.subtract(const Duration(days: 1)) : now;
    return !doneOn(day);
  }
}
