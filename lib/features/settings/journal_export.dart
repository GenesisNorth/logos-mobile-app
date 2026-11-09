import 'package:share_plus/share_plus.dart';
import '../../core/utils/date_format.dart';
import '../journey/bloc/journey_state.dart';

/// Shares a plain-text copy of the pilgrim's journey (streak, verses, Tear Sheets).
Future<void> exportJourneyJournal(JourneyState state) async {
  final profile = state.profile;
  final streak = state.activeStreak();
  final b = StringBuffer()
    ..writeln('LOGOS IN ME · My journal')
    ..writeln('========================================')
    ..writeln('Name: ${profile.displayName}')
    ..writeln('Current streak: $streak ${streak == 1 ? 'day' : 'days'}')
    ..writeln('Verses planted: ${state.rootsPlanted}');
  final signed = profile.covenantSignedAt;
  if (signed != null) b.writeln('Covenant signed: ${formatLogosDate(signed)}');
  b
    ..writeln()
    ..writeln('Tear Sheets (${state.savedTearSheets.length})')
    ..writeln('----------------------------------------');
  if (state.savedTearSheets.isEmpty) {
    b.writeln('None yet.');
  } else {
    for (final sheet in state.savedTearSheets) {
      b
        ..writeln('• ${sheet.reference} · ${formatLogosDate(sheet.completedAt)}')
        ..writeln('  “${sheet.verseText}”');
    }
  }
  b
    ..writeln()
    ..writeln('Soli Deo Gloria');

  await SharePlus.instance.share(ShareParams(text: b.toString(), subject: 'My LOGOS IN ME journal'));
}
