import 'dart:math';

/// Utility to calculate string similarity and verify scripture recitations.
class ScriptureVerifier {
  /// The passing threshold specified in PRD (80% Levenshtein match)
  static const double passingThreshold = 0.80;

  /// Cleans and normalizes scripture text:
  /// - Strips biblical punctuation (periods, commas, em-dashes, quotation marks)
  /// - Normalizes all unicode single/double quotes
  /// - Converts to lowercase and condenses multiple spaces
  static String normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'''[.,\/#!$%\^&\*;:{}=\-_`~()'"’“”«»]'''), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Returns similarity score between 0.0 (no match) and 1.0 (exact match).
  static double calculateSimilarity(String target, String transcribed) {
    final cleanTarget = normalize(target);
    final cleanTranscribed = normalize(transcribed);

    if (cleanTarget.isEmpty && cleanTranscribed.isEmpty) return 1.0;
    if (cleanTarget.isEmpty || cleanTranscribed.isEmpty) return 0.0;
    if (cleanTarget == cleanTranscribed) return 1.0;

    final distance = computeLevenshteinDistance(cleanTarget, cleanTranscribed);
    final maxLength = max(cleanTarget.length, cleanTranscribed.length);

    final score = 1.0 - (distance / maxLength);
    return score.clamp(0.0, 1.0);
  }

  /// Checks if recitation meets or exceeds the 80% threshold.
  static bool hasPassed(String target, String transcribed) {
    return calculateSimilarity(target, transcribed) >= passingThreshold;
  }

  /// Number of leading target words the speaker has reached so far.
  ///
  /// Used for live highlighting while reciting. Greedy alignment that
  /// tolerates a skipped or misheard word (looks ahead up to 2 words).
  static int matchedWordCount(String target, String transcribed) {
    final t = normalize(target).split(' ').where((w) => w.isNotEmpty).toList();
    final s = normalize(transcribed).split(' ').where((w) => w.isNotEmpty);
    var p = 0;
    for (final word in s) {
      if (p >= t.length) break;
      for (var look = 0; look <= 2 && p + look < t.length; look++) {
        if (_wordsClose(t[p + look], word)) {
          p += look + 1;
          break;
        }
      }
    }
    return p;
  }

  static bool _wordsClose(String a, String b) {
    if (a == b) return true;
    final longer = max(a.length, b.length);
    if (longer <= 3) return false;
    return computeLevenshteinDistance(a, b) <= (longer >= 7 ? 2 : 1);
  }

  /// Classical dynamic programming Levenshtein distance algorithm.
  static int computeLevenshteinDistance(String s1, String s2) {
    final m = s1.length;
    final n = s2.length;
    List<int> v0 = List<int>.generate(n + 1, (i) => i);
    List<int> v1 = List<int>.filled(n + 1, 0);

    for (int i = 0; i < m; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < n; j++) {
        final cost = (s1[i] == s2[j]) ? 0 : 1;
        v1[j + 1] = min(
          v1[j] + 1, // Insertion
          min(
            v0[j + 1] + 1, // Deletion
            v0[j] + cost, // Substitution
          ),
        );
      }
      for (int j = 0; j <= n; j++) {
        v0[j] = v1[j];
      }
    }
    return v0[n];
  }
}
