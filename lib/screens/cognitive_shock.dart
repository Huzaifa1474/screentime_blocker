import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// Step 16 — Cognitive shock screen.
///
/// Shows a stat like "You will spend 6 years scrolling in your lifetime."
/// Uses a high-contrast chart to make the number visceral.
///
/// Math: at 4.5h/day of phone use, the average 18-year-old will accumulate
/// 4.5 * 365 * 60 ≈ 98,550 hours ≈ 11.25 years by age 78. We show this as
/// a stacked bar comparing "on-phone" vs "awake, off-phone".
class CognitiveShockScreen extends StatelessWidget {
  final VoidCallback onDone;
  const CognitiveShockScreen({super.key, required this.onDone});

  static const double _hoursPerDay = 4.5;
  static const double _lifespanYears = 60; // remaining after age 18
  static const double _awakeHoursPerDay = 16;

  double get _phoneYears =>
      (_hoursPerDay * 365 * _lifespanYears) / (24 * 365);
  double get _awakeYears =>
      (_awakeHoursPerDay * 365 * _lifespanYears) / (24 * 365);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              const Text(
                'At your current pace…',
                style: TextStyle(color: Color(0xFF8A8A8E), fontSize: 14),
              ),
              const SizedBox(height: 16),
              Text(
                'You will spend ${_phoneYears.toStringAsFixed(1)} years',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'scrolling in your lifetime.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFB7A4FF),
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: _ShockChart(
                  phoneYears: _phoneYears,
                  awakeYears: _awakeYears,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'That\'s time you can never get back.\nBut the next 14 days can reset the trajectory.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF8A8A8E), fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onDone,
                child: const Text('I\'m in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShockChart extends StatelessWidget {
  final double phoneYears;
  final double awakeYears;
  const _ShockChart({required this.phoneYears, required this.awakeYears});

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: awakeYears + phoneYears + 4,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, _) {
                switch (value.toInt()) {
                  case 0:
                    return const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('On phone',
                          style: TextStyle(color: Colors.white, fontSize: 12)),
                    );
                  case 1:
                    return const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('Awake, off phone',
                          style: TextStyle(color: Colors.white, fontSize: 12)),
                    );
                  default:
                    return const SizedBox.shrink();
                }
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: phoneYears,
                color: const Color(0xFF7C5CFF),
                width: 60,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: awakeYears,
                color: const Color(0xFF2A2A2A),
                width: 60,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
