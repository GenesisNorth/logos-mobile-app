import 'package:equatable/equatable.dart';

abstract class JourneyEvent extends Equatable {
  const JourneyEvent();

  @override
  List<Object?> get props => [];
}

class LoadJourneyProgress extends JourneyEvent {
  const LoadJourneyProgress();
}

class SignCovenant extends JourneyEvent {
  final String fullName;
  const SignCovenant(this.fullName);

  @override
  List<Object?> get props => [fullName];
}

class SelectDay extends JourneyEvent {
  final int dayNumber;
  const SelectDay(this.dayNumber);

  @override
  List<Object?> get props => [dayNumber];
}

class CompleteDayRecitation extends JourneyEvent {
  final int dayNumber;
  final double score;

  const CompleteDayRecitation({
    required this.dayNumber,
    required this.score,
  });

  @override
  List<Object?> get props => [dayNumber, score];
}

class CompleteDayStillness extends JourneyEvent {
  final int dayNumber;
  const CompleteDayStillness(this.dayNumber);

  @override
  List<Object?> get props => [dayNumber];
}

class CompleteExchange extends JourneyEvent {
  final String burdenSummary;
  final String? tearSheetImagePath;

  const CompleteExchange({
    required this.burdenSummary,
    this.tearSheetImagePath,
  });

  @override
  List<Object?> get props => [burdenSummary, tearSheetImagePath];
}

/// Spends a grace token to bridge exactly one missed calendar day so the
/// streak continues. It never marks unfinished content as complete.
class RedeemGraceToken extends JourneyEvent {
  const RedeemGraceToken();
}

class AdvanceToNextWeek extends JourneyEvent {
  const AdvanceToNextWeek();
}

class SelectWeek extends JourneyEvent {
  final int weekIndex;
  const SelectWeek(this.weekIndex);

  @override
  List<Object?> get props => [weekIndex];
}

class SelectTranslation extends JourneyEvent {
  final String translationKey;
  const SelectTranslation(this.translationKey);

  @override
  List<Object?> get props => [translationKey];
}


class UpdateDisplayName extends JourneyEvent {
  final String name;
  const UpdateDisplayName(this.name);

  @override
  List<Object?> get props => [name];
}

/// Completes a practice day that has no recitation gate (Roots, Stillness).
class CompleteDay extends JourneyEvent {
  final int dayNumber;
  const CompleteDay(this.dayNumber);

  @override
  List<Object?> get props => [dayNumber];
}

/// The 30-day "How is it now?" answer for a laid-down burden.
class RecordTearSheetCheckIn extends JourneyEvent {
  final String sheetId;
  final String answer; // 'lighter' | 'carrying'
  const RecordTearSheetCheckIn(this.sheetId, this.answer);

  @override
  List<Object?> get props => [sheetId, answer];
}
