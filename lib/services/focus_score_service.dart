// FocusScoreService — computes the daily Focus Score (0..100).
//
// Formula documented for Day 2-5 of the 14-day program:
//
//   score = 100
//         - (pickups * 1.5)              // each pickup costs 1.5 points
//         - (notifications * 0.3)         // each notification costs 0.3
//         - (blocked_minutes * 0.05)      // time spent on blocked apps
//         + bonus_for_deep_focus_sessions
//
// Clamped to [0, 100]. All inputs are on-device.

import 'database_service.dart';

class FocusScoreInput {
  final int pickups;
  final int notifications;
  final int blockedMinutes;
  final int deepFocusSessions;

  const FocusScoreInput({
    required this.pickups,
    required this.notifications,
    required this.blockedMinutes,
    this.deepFocusSessions = 0,
  });

  int compute() {
    var score = 100.0;
    score -= pickups * 1.5;
    score -= notifications * 0.3;
    score -= blockedMinutes * 0.05;
    score += deepFocusSessions * 4.0;
    return score.clamp(0, 100).round();
  }
}

class FocusScoreService {
  FocusScoreService._();
  static final FocusScoreService instance = FocusScoreService._();

  /// Persists today's score and returns the computed value.
  Future<int> recordToday(FocusScoreInput input) async {
    final today = _todayKey();
    final score = input.compute();
    await DatabaseService.instance.upsertFocusScore(
      date: today,
      score: score,
      pickups: input.pickups,
      notifications: input.notifications,
      blockedMinutes: input.blockedMinutes,
    );
    return score;
  }

  /// Returns last 14 days of scores for trend chart.
  Future<List<int>> last14Days() async {
    final rows = await DatabaseService.instance.focusScoreLast(14);
    final list = rows.reversed
        .map((r) => (r['score'] as num?)?.toInt() ?? 0)
        .toList(growable: false);
    return list;
  }

  /// Day 6 report — hours saved vs peer average (peer avg is a fixed constant
  /// for offline-first; production can fetch from a server).
  Future<FocusReport> generateDay6Report() async {
    final rows = await DatabaseService.instance.focusScoreLast(6);
    final blockedMinutes = rows.fold<int>(
      0,
      (acc, r) => acc + ((r['blocked_minutes'] as num?)?.toInt() ?? 0),
    );
    final savedMinutes = blockedMinutes; // every blocked minute == a saved minute
    const peerAvgMinutesPerDay = 215; // ~3.6h social media avg
    const peerAvgTotal = peerAvgMinutesPerDay * 6;
    return FocusReport(
      hoursSaved: savedMinutes / 60.0,
      peerAverageHours: peerAvgTotal / 60.0,
      dailyScores: rows.reversed
          .map((r) => (r['score'] as num?)?.toInt() ?? 0)
          .toList(growable: false),
    );
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}

class FocusReport {
  final double hoursSaved;
  final double peerAverageHours;
  final List<int> dailyScores;

  const FocusReport({
    required this.hoursSaved,
    required this.peerAverageHours,
    required this.dailyScores,
  });

  double get improvementVsPeer =>
      ((hoursSaved - peerAverageHours) / peerAverageHours * 100).clamp(-100, 200);
}
