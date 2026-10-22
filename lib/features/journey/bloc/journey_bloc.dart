import 'package:flutter_bloc/flutter_bloc.dart';
import 'journey_event.dart';
import 'journey_state.dart';

class JourneyBloc extends Bloc<JourneyEvent, JourneyState> {
  JourneyBloc() : super(JourneyState.initial()) {
    on<LoadJourneyProgress>(_onLoadJourneyProgress);
    on<CompleteDayRecitation>(_onCompleteDayRecitation);
    on<CompleteExchange>(_onCompleteExchange);
    on<RedeemGraceToken>(_onRedeemGraceToken);
  }

  void _onLoadJourneyProgress(
    LoadJourneyProgress event,
    Emitter<JourneyState> emit,
  ) {
    // In Phase 0, loads from SharedPreferences / Isar DB
    emit(state);
  }

  void _onCompleteDayRecitation(
    CompleteDayRecitation event,
    Emitter<JourneyState> emit,
  ) {
    final currentCount = state.dayRecitationCount[event.dayNumber] ?? 0;
    final newCount = currentCount + 1;

    final updatedCounts = Map<int, int>.from(state.dayRecitationCount);
    updatedCounts[event.dayNumber] = newCount;

    final updatedStatus = Map<int, bool>.from(state.dayCompletionStatus);

    // Days 1-3 require 2 passed recitations to complete
    if (newCount >= 2 || event.dayNumber == 4) {
      updatedStatus[event.dayNumber] = true;
    }

    emit(state.copyWith(
      dayRecitationCount: updatedCounts,
      dayCompletionStatus: updatedStatus,
    ));
  }

  void _onCompleteExchange(
    CompleteExchange event,
    Emitter<JourneyState> emit,
  ) {
    final updatedStatus = Map<int, bool>.from(state.dayCompletionStatus);
    updatedStatus[4] = true;

    emit(state.copyWith(
      isExchangeCompleted: true,
      dayCompletionStatus: updatedStatus,
      rootsPlanted: state.rootsPlanted + 1,
      currentStreak: state.currentStreak + 1,
    ));
  }

  void _onRedeemGraceToken(
    RedeemGraceToken event,
    Emitter<JourneyState> emit,
  ) {
    if (state.graceTokensBalance <= 0) return;

    final updatedStatus = Map<int, bool>.from(state.dayCompletionStatus);
    updatedStatus[event.dayToRecover] = true;

    emit(state.copyWith(
      graceTokensBalance: state.graceTokensBalance - 1,
      dayCompletionStatus: updatedStatus,
      currentStreak: state.currentStreak + 1,
    ));
  }
}
