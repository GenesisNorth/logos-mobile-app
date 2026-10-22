import 'package:equatable/equatable.dart';
import '../models/scripture_drop.dart';

class JourneyState extends Equatable {
  final ScriptureDrop activeDrop;
  final int activeDay; // 1 to 4
  final Map<int, bool> dayCompletionStatus; // {1: true, 2: false, ...}
  final Map<int, int> dayRecitationCount; // {1: 2, 2: 1, ...} (requires 2 per day for days 1-3)
  final int currentStreak;
  final int rootsPlanted;
  final int graceTokensBalance;
  final bool isExchangeCompleted;

  const JourneyState({
    required this.activeDrop,
    required this.activeDay,
    required this.dayCompletionStatus,
    required this.dayRecitationCount,
    required this.currentStreak,
    required this.rootsPlanted,
    required this.graceTokensBalance,
    required this.isExchangeCompleted,
  });

  factory JourneyState.initial() {
    return JourneyState(
      activeDrop: ScriptureDrop.defaultWeek1(),
      activeDay: 1,
      dayCompletionStatus: const {1: false, 2: false, 3: false, 4: false},
      dayRecitationCount: const {1: 0, 2: 0, 3: 0, 4: 0},
      currentStreak: 4,
      rootsPlanted: 12,
      graceTokensBalance: 3,
      isExchangeCompleted: false,
    );
  }

  JourneyState copyWith({
    ScriptureDrop? activeDrop,
    int? activeDay,
    Map<int, bool>? dayCompletionStatus,
    Map<int, int>? dayRecitationCount,
    int? currentStreak,
    int? rootsPlanted,
    int? graceTokensBalance,
    bool? isExchangeCompleted,
  }) {
    return JourneyState(
      activeDrop: activeDrop ?? this.activeDrop,
      activeDay: activeDay ?? this.activeDay,
      dayCompletionStatus: dayCompletionStatus ?? this.dayCompletionStatus,
      dayRecitationCount: dayRecitationCount ?? this.dayRecitationCount,
      currentStreak: currentStreak ?? this.currentStreak,
      rootsPlanted: rootsPlanted ?? this.rootsPlanted,
      graceTokensBalance: graceTokensBalance ?? this.graceTokensBalance,
      isExchangeCompleted: isExchangeCompleted ?? this.isExchangeCompleted,
    );
  }

  bool isDayUnlocked(int day) {
    if (day == 1) return true;
    // Pace-locked rule: Previous day must be completed
    return dayCompletionStatus[day - 1] == true;
  }

  @override
  List<Object?> get props => [
        activeDrop,
        activeDay,
        dayCompletionStatus,
        dayRecitationCount,
        currentStreak,
        rootsPlanted,
        graceTokensBalance,
        isExchangeCompleted,
      ];
}
