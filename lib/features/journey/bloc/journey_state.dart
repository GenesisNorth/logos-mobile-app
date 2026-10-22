import 'package:equatable/equatable.dart';
import '../../../core/clock.dart';
import '../data/progress_repository.dart';
import '../models/scripture_drop.dart';

class JourneyState extends Equatable {
  final ScriptureDrop activeDrop;
  final int activeDay;
  final Map<int, bool> dayCompletionStatus;
  final Map<int, DateTime?> dayCompletedAt;
  final Map<int, int> dayRecitationCount;
  final Map<int, List<double>> dayRecitationScores;
  final int currentStreak;
  final int rootsPlanted;
  final int graceTokensBalance;
  final bool isExchangeCompleted;
  final UserProfileData profile;
  final List<TearSheetData> savedTearSheets;
  final bool isLoading;

  const JourneyState({
    required this.activeDrop,
    required this.activeDay,
    required this.dayCompletionStatus,
    required this.dayCompletedAt,
    required this.dayRecitationCount,
    required this.dayRecitationScores,
    required this.currentStreak,
    required this.rootsPlanted,
    required this.graceTokensBalance,
    required this.isExchangeCompleted,
    required this.profile,
    required this.savedTearSheets,
    this.isLoading = false,
  });

  factory JourneyState.initial(ScriptureDrop defaultDrop) {
    return JourneyState(
      activeDrop: defaultDrop,
      activeDay: 1,
      dayCompletionStatus: const {1: false, 2: false, 3: false, 4: false},
      dayCompletedAt: const {1: null, 2: null, 3: null, 4: null},
      dayRecitationCount: const {1: 0, 2: 0, 3: 0, 4: 0},
      dayRecitationScores: const {1: [], 2: [], 3: [], 4: []},
      currentStreak: 1,
      rootsPlanted: 0,
      graceTokensBalance: 3,
      isExchangeCompleted: false,
      profile: const UserProfileData(username: 'pilgrim', displayName: 'Genesis A.'),
      savedTearSheets: const [],
      isLoading: false,
    );
  }

  JourneyState copyWith({
    ScriptureDrop? activeDrop,
    int? activeDay,
    Map<int, bool>? dayCompletionStatus,
    Map<int, DateTime?>? dayCompletedAt,
    Map<int, int>? dayRecitationCount,
    Map<int, List<double>>? dayRecitationScores,
    int? currentStreak,
    int? rootsPlanted,
    int? graceTokensBalance,
    bool? isExchangeCompleted,
    UserProfileData? profile,
    List<TearSheetData>? savedTearSheets,
    bool? isLoading,
  }) {
    return JourneyState(
      activeDrop: activeDrop ?? this.activeDrop,
      activeDay: activeDay ?? this.activeDay,
      dayCompletionStatus: dayCompletionStatus ?? this.dayCompletionStatus,
      dayCompletedAt: dayCompletedAt ?? this.dayCompletedAt,
      dayRecitationCount: dayRecitationCount ?? this.dayRecitationCount,
      dayRecitationScores: dayRecitationScores ?? this.dayRecitationScores,
      currentStreak: currentStreak ?? this.currentStreak,
      rootsPlanted: rootsPlanted ?? this.rootsPlanted,
      graceTokensBalance: graceTokensBalance ?? this.graceTokensBalance,
      isExchangeCompleted: isExchangeCompleted ?? this.isExchangeCompleted,
      profile: profile ?? this.profile,
      savedTearSheets: savedTearSheets ?? this.savedTearSheets,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// Whether a day is unlocked according to midnight pace-lock.
  bool isDayUnlocked(int day, {DateTime? now}) {
    if (day <= 1) return true;
    final prevDay = day - 1;
    final isPrevCompleted = dayCompletionStatus[prevDay] == true;
    if (!isPrevCompleted) return false;

    final completedAt = dayCompletedAt[prevDay];
    if (completedAt == null) {
      // Completed in earlier session without timestamp: consider unlocked
      return true;
    }

    final current = now ?? DateTime.now();
    // Unlocked once we cross midnight into a subsequent calendar day
    return current.dateOnly.isAfter(completedAt.dateOnly);
  }

  /// Duration until midnight when the next day unlocks, if locked.
  Duration? timeUntilUnlock(int day, {DateTime? now}) {
    if (day <= 1) return null;
    final prevDay = day - 1;
    if (dayCompletionStatus[prevDay] != true) return null;

    final completedAt = dayCompletedAt[prevDay];
    if (completedAt == null) return null;

    final current = now ?? DateTime.now();
    if (current.dateOnly.isAfter(completedAt.dateOnly)) return null;

    final nextMidnight = completedAt.nextMidnight;
    final diff = nextMidnight.difference(current);
    return diff.isNegative ? Duration.zero : diff;
  }

  @override
  List<Object?> get props => [
        activeDrop,
        activeDay,
        dayCompletionStatus,
        dayCompletedAt,
        dayRecitationCount,
        dayRecitationScores,
        currentStreak,
        rootsPlanted,
        graceTokensBalance,
        isExchangeCompleted,
        profile,
        savedTearSheets,
        isLoading,
      ];
}
