import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../core/clock.dart';
import '../data/content_repository.dart';
import '../data/progress_repository.dart';
import 'journey_event.dart';
import 'journey_state.dart';

class JourneyBloc extends Bloc<JourneyEvent, JourneyState> {
  final ProgressRepository _progressRepo;
  final ContentRepository _contentRepo;
  final Clock _clock;

  JourneyBloc({
    ProgressRepository? progressRepo,
    ContentRepository? contentRepo,
    Clock? clock,
  })  : _progressRepo = progressRepo ?? LocalProgressRepository(),
        _contentRepo = contentRepo ?? const ContentRepository(),
        _clock = clock ?? const SystemClock(),
        super(JourneyState.initial((contentRepo ?? const ContentRepository()).drops.first)) {
    on<LoadJourneyProgress>(_onLoadJourneyProgress);
    on<SignCovenant>(_onSignCovenant);
    on<SelectDay>(_onSelectDay);
    on<CompleteDayRecitation>(_onCompleteDayRecitation);
    on<CompleteDayStillness>(_onCompleteDayStillness);
    on<CompleteExchange>(_onCompleteExchange);
    on<RedeemGraceToken>(_onRedeemGraceToken);
    on<AdvanceToNextWeek>(_onAdvanceToNextWeek);
  }

  Future<void> _onLoadJourneyProgress(
    LoadJourneyProgress event,
    Emitter<JourneyState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final profile = await _progressRepo.loadProfile();
    final journeyData = await _progressRepo.loadJourneyData();
    final tearSheets = await _progressRepo.loadTearSheets();

    final weekIndex = journeyData['weekIndex'] as int? ?? 0;
    final activeDrop = _contentRepo.dropForWeekIndex(weekIndex);

    // Parse day completion status
    final dayCompletionRaw = journeyData['dayCompletion'] as Map<String, dynamic>? ?? {};
    final dayCompletion = <int, bool>{
      1: dayCompletionRaw['1'] == true,
      2: dayCompletionRaw['2'] == true,
      3: dayCompletionRaw['3'] == true,
      4: dayCompletionRaw['4'] == true,
    };

    // Parse timestamps
    final timestampsRaw = journeyData['dayCompletedAt'] as Map<String, dynamic>? ?? {};
    final dayCompletedAt = <int, DateTime?>{
      1: timestampsRaw['1'] != null ? DateTime.tryParse(timestampsRaw['1'] as String) : null,
      2: timestampsRaw['2'] != null ? DateTime.tryParse(timestampsRaw['2'] as String) : null,
      3: timestampsRaw['3'] != null ? DateTime.tryParse(timestampsRaw['3'] as String) : null,
      4: timestampsRaw['4'] != null ? DateTime.tryParse(timestampsRaw['4'] as String) : null,
    };

    // Parse recitation counts
    final countsRaw = journeyData['recitationCounts'] as Map<String, dynamic>? ?? {};
    final recitationCounts = <int, int>{
      1: countsRaw['1'] as int? ?? 0,
      2: countsRaw['2'] as int? ?? 0,
      3: countsRaw['3'] as int? ?? 0,
      4: countsRaw['4'] as int? ?? 0,
    };

    final streak = journeyData['currentStreak'] as int? ?? 4;
    final roots = journeyData['rootsPlanted'] as int? ?? 12;
    final graceTokens = journeyData['graceTokensBalance'] as int? ?? 3;
    final isExchangeCompleted = journeyData['isExchangeCompleted'] as bool? ?? false;
    final activeDay = journeyData['activeDay'] as int? ?? 1;

    emit(state.copyWith(
      activeDrop: activeDrop,
      activeDay: activeDay,
      dayCompletionStatus: dayCompletion,
      dayCompletedAt: dayCompletedAt,
      dayRecitationCount: recitationCounts,
      currentStreak: streak,
      rootsPlanted: roots,
      graceTokensBalance: graceTokens,
      isExchangeCompleted: isExchangeCompleted,
      profile: profile,
      savedTearSheets: tearSheets,
      isLoading: false,
    ));
  }

  Future<void> _onSignCovenant(
    SignCovenant event,
    Emitter<JourneyState> emit,
  ) async {
    final now = _clock.now();
    final signatureHash = sha256.convert(utf8.encode(event.fullName + now.toIso8601String())).toString();

    final updatedProfile = UserProfileData(
      username: state.profile.username,
      displayName: event.fullName.trim().isEmpty ? state.profile.displayName : event.fullName.trim(),
      covenantSignature: signatureHash,
      covenantSignedAt: now,
      birthMonth: state.profile.birthMonth,
      birthDay: state.profile.birthDay,
    );

    await _progressRepo.saveProfile(updatedProfile);
    emit(state.copyWith(profile: updatedProfile));
  }

  void _onSelectDay(
    SelectDay event,
    Emitter<JourneyState> emit,
  ) {
    if (state.isDayUnlocked(event.dayNumber, now: _clock.now())) {
      emit(state.copyWith(activeDay: event.dayNumber));
      _persistJourneyData(state);
    }
  }

  Future<void> _onCompleteDayRecitation(
    CompleteDayRecitation event,
    Emitter<JourneyState> emit,
  ) async {
    final currentCount = state.dayRecitationCount[event.dayNumber] ?? 0;
    final newCount = currentCount + 1;

    final updatedCounts = Map<int, int>.from(state.dayRecitationCount);
    updatedCounts[event.dayNumber] = newCount;

    final updatedScores = Map<int, List<double>>.from(state.dayRecitationScores);
    final scoresForDay = List<double>.from(updatedScores[event.dayNumber] ?? []);
    scoresForDay.add(event.score);
    updatedScores[event.dayNumber] = scoresForDay;

    final updatedStatus = Map<int, bool>.from(state.dayCompletionStatus);
    final updatedCompletedAt = Map<int, DateTime?>.from(state.dayCompletedAt);

    // Days 1 & 2 require 2 passed recitations.
    // Day 3 requires stillness + recitations.
    // Day 4 master recitation requires 1 pass.
    if ((event.dayNumber <= 2 && newCount >= 2) || (event.dayNumber == 4 && newCount >= 1)) {
      if (updatedStatus[event.dayNumber] != true) {
        updatedStatus[event.dayNumber] = true;
        updatedCompletedAt[event.dayNumber] = _clock.now();
      }
    }

    final newState = state.copyWith(
      dayRecitationCount: updatedCounts,
      dayRecitationScores: updatedScores,
      dayCompletionStatus: updatedStatus,
      dayCompletedAt: updatedCompletedAt,
    );

    emit(newState);
    await _persistJourneyData(newState);
  }

  Future<void> _onCompleteDayStillness(
    CompleteDayStillness event,
    Emitter<JourneyState> emit,
  ) async {
    final updatedStatus = Map<int, bool>.from(state.dayCompletionStatus);
    final updatedCompletedAt = Map<int, DateTime?>.from(state.dayCompletedAt);

    updatedStatus[3] = true;
    updatedCompletedAt[3] = _clock.now();

    final newState = state.copyWith(
      dayCompletionStatus: updatedStatus,
      dayCompletedAt: updatedCompletedAt,
    );

    emit(newState);
    await _persistJourneyData(newState);
  }

  Future<void> _onCompleteExchange(
    CompleteExchange event,
    Emitter<JourneyState> emit,
  ) async {
    final now = _clock.now();
    final updatedStatus = Map<int, bool>.from(state.dayCompletionStatus);
    final updatedCompletedAt = Map<int, DateTime?>.from(state.dayCompletedAt);

    updatedStatus[4] = true;
    updatedCompletedAt[4] = now;

    final burdenHash = sha256.convert(utf8.encode(event.burdenSummary)).toString();
    final tearSheet = TearSheetData(
      id: const Uuid().v4(),
      dropId: state.activeDrop.id,
      verseText: state.activeDrop.verseText,
      reference: state.activeDrop.reference,
      burdenHash: burdenHash,
      tearSheetImagePath: event.tearSheetImagePath,
      completedAt: now,
    );

    await _progressRepo.saveTearSheet(tearSheet);
    final updatedSheets = List<TearSheetData>.from(state.savedTearSheets)..add(tearSheet);

    final newState = state.copyWith(
      isExchangeCompleted: true,
      dayCompletionStatus: updatedStatus,
      dayCompletedAt: updatedCompletedAt,
      rootsPlanted: state.rootsPlanted + 1,
      currentStreak: state.currentStreak + 1,
      savedTearSheets: updatedSheets,
    );

    emit(newState);
    await _persistJourneyData(newState);
  }

  Future<void> _onRedeemGraceToken(
    RedeemGraceToken event,
    Emitter<JourneyState> emit,
  ) async {
    if (state.graceTokensBalance <= 0) return;

    final updatedStatus = Map<int, bool>.from(state.dayCompletionStatus);
    final updatedCompletedAt = Map<int, DateTime?>.from(state.dayCompletedAt);

    updatedStatus[event.dayToRecover] = true;
    // Set timestamp to yesterday so today is unlocked immediately
    final yesterday = _clock.now().subtract(const Duration(days: 1));
    updatedCompletedAt[event.dayToRecover] = yesterday;

    final newState = state.copyWith(
      graceTokensBalance: state.graceTokensBalance - 1,
      dayCompletionStatus: updatedStatus,
      dayCompletedAt: updatedCompletedAt,
    );

    emit(newState);
    await _persistJourneyData(newState);
  }

  Future<void> _onAdvanceToNextWeek(
    AdvanceToNextWeek event,
    Emitter<JourneyState> emit,
  ) async {
    final currentIndex = _contentRepo.drops.indexOf(state.activeDrop);
    final nextDrop = _contentRepo.dropForWeekIndex(currentIndex + 1);

    const resetStatus = {1: false, 2: false, 3: false, 4: false};
    const resetCompletedAt = {1: null, 2: null, 3: null, 4: null};
    const resetCounts = {1: 0, 2: 0, 3: 0, 4: 0};

    final newState = state.copyWith(
      activeDrop: nextDrop,
      activeDay: 1,
      dayCompletionStatus: resetStatus,
      dayCompletedAt: resetCompletedAt,
      dayRecitationCount: resetCounts,
      isExchangeCompleted: false,
    );

    emit(newState);
    await _persistJourneyData(newState);
  }

  Future<void> _persistJourneyData(JourneyState state) async {
    final weekIndex = _contentRepo.drops.indexOf(state.activeDrop);
    final data = {
      'weekIndex': weekIndex,
      'activeDay': state.activeDay,
      'currentStreak': state.currentStreak,
      'rootsPlanted': state.rootsPlanted,
      'graceTokensBalance': state.graceTokensBalance,
      'isExchangeCompleted': state.isExchangeCompleted,
      'dayCompletion': {
        '1': state.dayCompletionStatus[1] ?? false,
        '2': state.dayCompletionStatus[2] ?? false,
        '3': state.dayCompletionStatus[3] ?? false,
        '4': state.dayCompletionStatus[4] ?? false,
      },
      'dayCompletedAt': {
        '1': state.dayCompletedAt[1]?.toIso8601String(),
        '2': state.dayCompletedAt[2]?.toIso8601String(),
        '3': state.dayCompletedAt[3]?.toIso8601String(),
        '4': state.dayCompletedAt[4]?.toIso8601String(),
      },
      'recitationCounts': {
        '1': state.dayRecitationCount[1] ?? 0,
        '2': state.dayRecitationCount[2] ?? 0,
        '3': state.dayRecitationCount[3] ?? 0,
        '4': state.dayRecitationCount[4] ?? 0,
      },
    };
    await _progressRepo.saveJourneyData(data);
  }
}
