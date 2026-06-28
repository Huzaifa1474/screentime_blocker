import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/rules_engine.dart';
import '../services/screentime_bridge.dart';
import '../widgets/focus_score_dial.dart';
import 'rules_engine_screen.dart';
import 'waiting_room.dart';
import '../features/take_a_break.dart';
import '../program/behavioral_program.dart';

/// Step 22 — Main dashboard.
///
/// Shows:
///   * Circular Focus Score dial (today's score)
///   * Active schedules (from RulesEngineService)
///   * Today's stats (pickups / notifications / blocked minutes)
///   * Quick links to Rules, Take-a-break, Behavioral program, Waiting room
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final int _todayScore = 72;

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  Future<void> _loadRules() async {
    await context.read<RulesEngineService>().loadRules();
  }

  @override
  Widget build(BuildContext context) {
    final rules = context.watch<RulesEngineService>().rules;
    final activeRules = rules.where((r) => r.active).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Today'),
        actions: [
          IconButton(
            icon: const Icon(Icons.timeline_outlined),
            tooltip: '14-day program',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const BehavioralProgramScreen(),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            FocusScoreDial(score: _todayScore),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'You\'re in the top quartile of your last 14 days.',
                style: TextStyle(color: Color(0xFF8A8A8E), fontSize: 13),
              ),
            ),
            const SizedBox(height: 32),

            // ---------- Today's stats ----------
            const Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Pickups',
                    value: '23',
                    delta: '-8 vs yesterday',
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Notifications',
                    value: '47',
                    delta: '-21 vs yesterday',
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Blocked',
                    value: '1h 42m',
                    delta: 'Shielded time',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ---------- Active schedules ----------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Active schedules',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RulesEngineScreen(),
                    ),
                  ),
                  child: const Text('Manage'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (activeRules.isEmpty)
              const _EmptySchedulesCard()
            else
              ...activeRules.map((r) => _ScheduleCard(rule: r)),

            const SizedBox(height: 32),

            // ---------- Quick actions ----------
            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.self_improvement_outlined,
                    label: 'Take a break',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const TakeABreakScreen(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.hourglass_empty_outlined,
                    label: 'Waiting room',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const WaitingRoomScreen(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.shield_outlined,
                    label: 'Force block now',
                    onTap: () async {
                      await ScreentimeBridge.instance.setBlockingActive(true);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Shields up.')),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String delta;
  const _StatCard({
    required this.label,
    required this.value,
    required this.delta,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF8A8A8E), fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            delta,
            style: const TextStyle(color: Color(0xFFB7A4FF), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final FocusRule rule;
  const _ScheduleCard({required this.rule});

  String _fmt(int min) {
    final h = min ~/ 60;
    final m = min % 60;
    final period = h >= 12 ? 'PM' : 'AM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:${m.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: rule.deepFocus
              ? const Color(0xFF7C5CFF).withValues(alpha: 0.5)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF7C5CFF),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_fmt(rule.startMin)} – ${_fmt(rule.endMin)}'
                  '${rule.deepFocus ? '  ·  Deep Focus' : ''}',
                  style: const TextStyle(
                    color: Color(0xFF8A8A8E),
                    fontSize: 12,
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

class _EmptySchedulesCard extends StatelessWidget {
  const _EmptySchedulesCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Icon(Icons.calendar_today_outlined,
              color: Color(0xFF8A8A8E), size: 28),
          const SizedBox(height: 8),
          const Text(
            'No active schedules yet.',
            style: TextStyle(color: Colors.white, fontSize: 15),
          ),
          const SizedBox(height: 4),
          const Text(
            'Set up your first focus block to start your 14-day program.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF8A8A8E), fontSize: 13),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const RulesEngineScreen(),
              ),
            ),
            child: const Text('Create schedule'),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F0F),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFB7A4FF), size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
