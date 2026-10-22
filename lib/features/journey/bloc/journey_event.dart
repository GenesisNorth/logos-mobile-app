import 'package:equatable/equatable.dart';

abstract class JourneyEvent extends Equatable {
  const JourneyEvent();

  @override
  List<Object?> get props => [];
}

class LoadJourneyProgress extends JourneyEvent {}

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

class CompleteExchange extends JourneyEvent {
  final String burdenSummary;

  const CompleteExchange({required this.burdenSummary});

  @override
  List<Object?> get props => [burdenSummary];
}

class RedeemGraceToken extends JourneyEvent {
  final int dayToRecover;

  const RedeemGraceToken({required this.dayToRecover});

  @override
  List<Object?> get props => [dayToRecover];
}
