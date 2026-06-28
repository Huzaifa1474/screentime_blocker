import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/rules_engine.dart';
import '../services/screentime_bridge.dart';
import '../features/deep_focus_mode.dart';

/// Step 23 — Rules engine screen.
///
/// Allows the user to configure:
///   * Scheduled sessions (e.g. Mon–Fri 9AM–5PM)
///   * Manual focus sessions (start now, end after N minutes)
///   * Deep Focus Mode toggle
class RulesEngineScreen extends StatefulWidget {
  const RulesEngineScreen({super.key});

  @override
  State<RulesEngineScreen> createState() => _RulesEngineScreenState();
}

class _RulesEngineScreenState extends State<RulesEngineScreen> {
  final _nameCtrl = TextEditingController(text: 'Work hours');
  final _days = <bool>[true, true, true, true, true, false, false]; // Mon..Sun
  TimeOfDay _start = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 17, minute: 0);
  bool _deepFocus = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  int get _daysMask {
    var mask = 0;
    for (var i = 0; i < 7; i++) {
      if (_days[i]) mask |= (1 << i);
    }
    return mask;
  }

  Future<void> _createScheduled() async {
    final svc = context.read<RulesEngineService>();
    await svc.createScheduledRule(
      name: _nameCtrl.text.isEmpty ? 'Session' : _nameCtrl.text,
      daysMask: _daysMask,
      startMin: _toMinutes(_start),
      endMin: _toMinutes(_end),
      deepFocus: _deepFocus,
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _startManual(int minutes) async {
    final svc = context.read<RulesEngineService>();
    await svc.startManualSession(
      name: 'Manual focus',
      durationMinutes: minutes,
      deepFocus: _deepFocus,
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _endManual(String id) async {
    await context.read<RulesEngineService>().endManualSession(id);
  }

  @override
  Widget build(BuildContext context) {
    final rules = context.watch<RulesEngineService>().rules;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Rules engine')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // ---------- Manual quick start ----------
            const _SectionHeader('Start a manual session'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _ManualButton(minutes: 15, label: '15 min', onTap: () => _startManual(15))),
                const SizedBox(width: 8),
                Expanded(child: _ManualButton(minutes: 30, label: '30 min', onTap: () => _startManual(30))),
                const SizedBox(width: 8),
                Expanded(child: _ManualButton(minutes: 60, label: '1 hour', onTap: () => _startManual(60))),
                const SizedBox(width: 8),
                Expanded(child: _ManualButton(minutes: 90, label: '90 min', onTap: () => _startManual(90))),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _deepFocus,
              onChanged: (v) => setState(() => _deepFocus = v),
              title: const Text('Deep Focus Mode',
                  style: TextStyle(color: Colors.white, fontSize: 15)),
              subtitle: const Text(
                'No pause, no break, no override. App uninstall blocked on iOS. '
                'System Settings blocked on Android.',
                style: TextStyle(color: Color(0xFF8A8A8E), fontSize: 12),
              ),
              activeThumbColor: const Color(0xFF7C5CFF),
            ),
            const SizedBox(height: 24),

            // ---------- Scheduled session form ----------
            const _SectionHeader('Schedule a session'),
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Session name'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _TimeTile(
                    label: 'Start',
                    time: _start,
                    onChanged: (t) => setState(() => _start = t),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimeTile(
                    label: 'End',
                    time: _end,
                    onChanged: (t) => setState(() => _end = t),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Repeat on',
              style: TextStyle(color: Color(0xFF8A8A8E), fontSize: 12),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                final on = _days[i];
                return GestureDetector(
                  onTap: () => setState(() => _days[i] = !on),
                  child: Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: on
                          ? const Color(0xFF7C5CFF)
                          : const Color(0xFF0F0F0F),
                      border: Border.all(
                        color: on
                            ? const Color(0xFF7C5CFF)
                            : const Color(0xFF2A2A2A),
                      ),
                    ),
                    child: Text(
                      labels[i],
                      style: TextStyle(
                        color: on ? Colors.white : const Color(0xFF8A8A8E),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _createScheduled,
              child: const Text('Save schedule'),
            ),
            const SizedBox(height: 32),

            // ---------- Existing rules ----------
            const _SectionHeader('Your rules'),
            const SizedBox(height: 8),
            if (rules.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No rules yet. Create one above.',
                    style: TextStyle(color: Color(0xFF8A8A8E)),
                  ),
                ),
              )
            else
              ...rules.map((r) => _RuleRow(
                    rule: r,
                    onEnd: r.kind == RuleKind.manual ? () => _endManual(r.id) : null,
                  )),
            const SizedBox(height: 24),

            // ---------- App picker shortcut ----------
            const _SectionHeader('Blocked apps'),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () async {
                await ScreentimeBridge.instance.selectBlockedApps();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Selection saved.')),
                  );
                }
              },
              child: const Text('Choose apps to block'),
            ),
            const SizedBox(height: 24),

            // ---------- Deep Focus Mode info ----------
            const DeepFocusInfoCard(),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF8A8A8E)),
        filled: true,
        fillColor: const Color(0xFF0F0F0F),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      );
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
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ManualButton extends StatelessWidget {
  final int minutes;
  final String label;
  final VoidCallback onTap;
  const _ManualButton({
    required this.minutes,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F0F),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onChanged;
  const _TimeTile({
    required this.label,
    required this.time,
    required this.onChanged,
  });

  String _fmt(TimeOfDay t) {
    final h = t.hour == 0 ? 12 : (t.hour > 12 ? t.hour - 12 : t.hour);
    final period = t.hour >= 12 ? 'PM' : 'AM';
    return '$h:${t.minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time,
          builder: (_, child) => Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF7C5CFF),
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F0F),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: Color(0xFF8A8A8E), fontSize: 12),
            ),
            Text(
              _fmt(time),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  final FocusRule rule;
  final VoidCallback? onEnd;
  const _RuleRow({required this.rule, this.onEnd});

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
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
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
                  rule.kind == RuleKind.manual
                      ? 'Manual · ${rule.durationMinutes} min'
                      : '${_fmt(rule.startMin)} – ${_fmt(rule.endMin)}',
                  style: const TextStyle(
                    color: Color(0xFF8A8A8E),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (rule.deepFocus)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF7C5CFF).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Deep',
                style: TextStyle(color: Color(0xFFB7A4FF), fontSize: 11),
              ),
            ),
          if (onEnd != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.stop_circle_outlined, color: Colors.red),
              onPressed: onEnd,
            ),
          ],
        ],
      ),
    );
  }
}
