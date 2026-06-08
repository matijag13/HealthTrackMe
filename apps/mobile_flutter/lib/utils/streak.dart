import '../models/models.dart';

/// Result of a logging-streak calculation.
class StreakResult {
  /// Consecutive logged days ending today (or yesterday if today isn't logged yet).
  final int current;

  /// Longest run of consecutive logged days ever.
  final int best;

  /// True when today already has an entry (the streak is "secured" for today).
  final bool loggedToday;

  const StreakResult({
    required this.current,
    required this.best,
    required this.loggedToday,
  });

  static const empty = StreakResult(current: 0, best: 0, loggedToday: false);
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Counts the "logging streak": consecutive days that have at least one health
/// entry. A streak stays alive into today until the day ends — if today isn't
/// logged yet but yesterday was, the streak still counts (anchored to yesterday)
/// so users get the morning nudge to keep it rather than seeing it pre-broken.
StreakResult computeLoggingStreak(List<HealthEntry> entries, {DateTime? now}) {
  if (entries.isEmpty) return StreakResult.empty;

  final today = _dateOnly(now ?? DateTime.now());
  final days = <DateTime>{for (final e in entries) _dateOnly(e.entryDate)};

  final loggedToday = days.contains(today);

  // Pick the anchor the current streak counts back from.
  DateTime? cursor;
  if (loggedToday) {
    cursor = today;
  } else if (days.contains(today.subtract(const Duration(days: 1)))) {
    cursor = today.subtract(const Duration(days: 1));
  }

  var current = 0;
  while (cursor != null && days.contains(cursor)) {
    current++;
    cursor = cursor.subtract(const Duration(days: 1));
  }

  // Best streak over all logged days.
  final sorted = days.toList()..sort();
  var best = 0;
  var run = 0;
  DateTime? prev;
  for (final day in sorted) {
    if (prev != null && day.difference(prev).inDays == 1) {
      run++;
    } else {
      run = 1;
    }
    if (run > best) best = run;
    prev = day;
  }

  return StreakResult(current: current, best: best, loggedToday: loggedToday);
}

/// The streak milestones worth celebrating.
const List<int> streakMilestones = [3, 7, 14, 30, 60, 100, 365];

/// Returns the milestone reached if [streak] exactly hits one, else null.
int? milestoneFor(int streak) =>
    streakMilestones.contains(streak) ? streak : null;
