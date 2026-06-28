import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';

import '../services/database_service.dart';
import '../services/focus_score_service.dart';

/// BehavioralProgramScreen — the structured 14-day program.
///
/// Timeline:
///   Day 1     — User sets up scheduled block sessions
///   Days 2-5  — App calculates Focus Score (0..100) from daily pickups,
///               notifications received, and time spent on blocked apps
///   Day 6     — Generate Focus Report: hours saved, peer comparison
///   Days 7-14 — Introduce daily app time budgets, enable cross-device sync
///   Day 14+   — Unlock styled 3D milestone gems (shareable)
class BehavioralProgramScreen extends StatefulWidget {
  const BehavioralProgramScreen({super.key});

  @override
  State<BehavioralProgramScreen> createState() =>
      _BehavioralProgramScreenState();
}

class _BehavioralProgramScreenState extends State<BehavioralProgramScreen> {
  List<int> _scores = const [];
  List<Map<String, Object?>> _milestones = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final scores = await FocusScoreService.instance.last14Days();
    final ms = await DatabaseService.instance.unlockedMilestones();
    if (mounted) {
      setState(() {
        _scores = scores;
        _milestones = ms;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('14-day program')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            const _ProgramHeader(),
            const SizedBox(height: 24),
            if (_scores.isNotEmpty) ...[
              const _SectionHeader('Your 14-day Focus Score'),
              const SizedBox(height: 8),
              SizedBox(
                height: 160,
                child: _ScoreTrendChart(scores: _scores),
              ),
              const SizedBox(height: 32),
            ],
            const _SectionHeader('Timeline'),
            const SizedBox(height: 12),
            const _TimelineItem(
              day: 1,
              title: 'Set up scheduled block sessions',
              detail:
                  'Example: Monday to Friday, 9 AM to 5 PM. Native OS-level enforcement.',
              state: _TimelineState.done,
            ),
            const _TimelineItem(
              day: 2,
              title: 'Focus Score appears on dashboard',
              detail:
                  'Score is calculated from pickups, notifications, and time spent on blocked apps. Range: 0–100.',
              state: _TimelineState.active,
            ),
            const _TimelineItem(
              day: 6,
              title: 'First Focus Report',
              detail:
                  'See hours saved and how you compare to peer averages. Social proof for the streak.',
              state: _TimelineState.locked,
            ),
            const _TimelineItem(
              day: 7,
              title: 'Daily app time budgets',
              detail:
                  'Set per-category budgets (e.g. 20 min/day for social). Cross-device sync option appears (Chrome extension, macOS).',
              state: _TimelineState.locked,
            ),
            const _TimelineItem(
              day: 14,
              title: '3D milestone gems unlocked',
              detail:
                  'Styled 3D gems you can share to social media. New one every 7 days after.',
              state: _TimelineState.locked,
            ),
            const SizedBox(height: 32),
            const _SectionHeader('Milestones'),
            const SizedBox(height: 12),
            if (_milestones.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'No milestones unlocked yet. Complete Day 1 to unlock your first gem.',
                    style: TextStyle(color: Color(0xFF8A8A8E)),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ..._milestones.map((m) => _MilestoneTile(
                    day: (m['day'] as num?)?.toInt() ?? 0,
                  )),
            const SizedBox(height: 32),
            const _SectionHeader('Reports'),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: () async {
                final report =
                    await FocusScoreService.instance.generateDay6Report();
                if (context.mounted) {
                  await showDialog(
                    context: context,
                    builder: (_) => _Day6ReportDialog(report: report),
                  );
                }
              },
              child: const Text('Generate Day 6 Focus Report'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgramHeader extends StatelessWidget {
  const _ProgramHeader();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '14 days to reclaim your attention.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'A guided behavioral program. Each phase builds the last. No '
            'data leaves your phone — your privacy is the whole point.',
            style: TextStyle(color: Color(0xFF8A8A8E), fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

enum _TimelineState { done, active, locked }

class _TimelineItem extends StatelessWidget {
  final int day;
  final String title;
  final String detail;
  final _TimelineState state;
  const _TimelineItem({
    required this.day,
    required this.title,
    required this.detail,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final color = state == _TimelineState.done
        ? const Color(0xFF34C759)
        : state == _TimelineState.active
            ? const Color(0xFF7C5CFF)
            : const Color(0xFF3A3A3C);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.18),
                  border: Border.all(color: color, width: 1.4),
                ),
                child: state == _TimelineState.done
                    ? Icon(Icons.check, color: color, size: 16)
                    : Text(
                        '$day',
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              if (state != _TimelineState.done)
                Container(
                  width: 1.4,
                  height: 36,
                  color: const Color(0xFF2A2A2A),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Day $day · $title',
                  style: TextStyle(
                    color: state == _TimelineState.locked
                        ? const Color(0xFF8A8A8E)
                        : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                    color: Color(0xFF8A8A8E),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestoneTile extends StatelessWidget {
  final int day;
  const _MilestoneTile({required this.day});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF7C5CFF).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.diamond, color: Color(0xFFB7A4FF), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Day $day Gem',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text(
                  'Unlocked',
                  style: TextStyle(color: Color(0xFFB7A4FF), fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              // Shareable to social media — in production wires into
              // share_plus or a custom share sheet.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sharing coming soon.')),
              );
            },
            child: const Text('Share'),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 320.ms)
        .slideY(begin: 0.1, end: 0);
  }
}

class _ScoreTrendChart extends StatelessWidget {
  final List<int> scores;
  const _ScoreTrendChart({required this.scores});

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (var i = 0; i < scores.length; i++) {
      spots.add(FlSpot(i.toDouble(), scores[i].toDouble()));
    }
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 100,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: Color(0xFF1C1C1E),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF7C5CFF),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF7C5CFF).withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _Day6ReportDialog extends StatelessWidget {
  final FocusReport report;
  const _Day6ReportDialog({required this.report});

  @override
  Widget build(BuildContext context) {
    final pct = report.improvementVsPeer;
    return AlertDialog(
      backgroundColor: const Color(0xFF0F0F0F),
      title: const Text('Day 6 Focus Report',
          style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${report.hoursSaved.toStringAsFixed(1)} hours saved',
            style: const TextStyle(
              color: Color(0xFFB7A4FF),
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Peer average: ${report.peerAverageHours.toStringAsFixed(1)} h',
            style: const TextStyle(color: Color(0xFF8A8A8E), fontSize: 13),
          ),
          const SizedBox(height: 12),
          Text(
            pct >= 0
                ? 'You\'re ${pct.toStringAsFixed(0)}% above your peer group. Solid.'
                : 'You\'re ${(-pct).toStringAsFixed(0)}% below your peer group. Day 7 starts the budgets.',
            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
