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

class RedeemGraceToken extends JourneyEvent {
  final int dayToRecover;

  const RedeemGraceToken({required this.dayToRecover});

  @override
  List<Object?> get props => [dayToRecover];
}

class AdvanceToNextWeek extends JourneyEvent {
  const AdvanceToNextWeek();
}
