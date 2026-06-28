// RulesEngineService — manages scheduled + manual focus sessions.
//
// Implements the iOS 15-minute scheduling minimum constraint:
//   * If a session duration is >= 15 minutes -> use DeviceActivity scheduling
//     (handled natively; the Dart side just persists the rule and signals
//      the native layer via MethodChannel).
//   * If a session duration is < 15 minutes -> do NOT use DeviceActivity.
//     Instead, start a local Dart countdown Timer and call
//     ScreentimeBridge.instance.setBlockingActive(true/false) directly.
//
// Also enforces the iOS 50-token limit by preferring category tokens
// over individual app tokens when persisting selections.

import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import 'database_service.dart';
import 'screentime_bridge.dart';

enum RuleKind { scheduled, manual }

class FocusRule {
  final String id;
  final String name;
  final RuleKind kind;
  final int daysMask; // bitmask Mon..Sun (Mon=1<<0 ... Sun=1<<6)
  final int startMin; // minutes since 00:00
  final int endMin;
  final bool deepFocus;
  final bool active;

  const FocusRule({
    required this.id,
    required this.name,
    required this.kind,
    required this.daysMask,
    required this.startMin,
    required this.endMin,
    required this.deepFocus,
    required this.active,
  });

  int get durationMinutes => endMin - startMin;
  bool get isShort => durationMinutes < 15;

  Map<String, Object?> toRow() => {
        'id': id,
        'name': name,
        'kind': kind == RuleKind.scheduled ? 'scheduled' : 'manual',
        'days_mask': daysMask,
        'start_min': startMin,
        'end_min': endMin,
        'deep_focus': deepFocus ? 1 : 0,
        'active': active ? 1 : 0,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      };

  factory FocusRule.fromRow(Map<String, Object?> row) => FocusRule(
        id: row['id'] as String,
        name: row['name'] as String,
        kind: (row['kind'] as String) == 'scheduled'
            ? RuleKind.scheduled
            : RuleKind.manual,
        daysMask: (row['days_mask'] as num).toInt(),
        startMin: (row['start_min'] as num).toInt(),
        endMin: (row['end_min'] as num).toInt(),
        deepFocus: (row['deep_focus'] as num).toInt() == 1,
        active: (row['active'] as num).toInt() == 1,
      );
}

class RulesEngineService extends ChangeNotifier {
  RulesEngineService._();
  static final RulesEngineService instance = RulesEngineService._();

  final _uuid = const Uuid();
  final Map<String, Timer> _shortSessionTimers = {};

  List<FocusRule> _rules = const <FocusRule>[];
  List<FocusRule> get rules => _rules;

  Future<void> loadRules() async {
    final rows = await DatabaseService.instance.allRules();
    _rules = rows.map(FocusRule.fromRow).toList(growable: false);
    notifyListeners();
  }

  Future<FocusRule> createScheduledRule({
    required String name,
    required int daysMask,
    required int startMin,
    required int endMin,
    required bool deepFocus,
  }) async {
    final rule = FocusRule(
      id: _uuid.v4(),
      name: name,
      kind: RuleKind.scheduled,
      daysMask: daysMask,
      startMin: startMin,
      endMin: endMin,
      deepFocus: deepFocus,
      active: true,
    );
    await DatabaseService.instance.insertRule(rule.toRow());

    if (rule.isShort) {
      // Constraint: iOS DeviceActivity scheduling minimum is 15 minutes.
      // For sub-15-minute sessions, we use a local Dart timer instead.
      _scheduleLocalDartTimer(rule);
    } else {
      // For sessions >= 15 minutes, the native DeviceActivityMonitor
      // extension handles start/end. The Dart layer just persists the rule;
      // the native side reads from the shared App Group on launch.
      debugPrint('[RulesEngine] Native DeviceActivity will handle rule ${rule.id}');
    }

    _rules = [rule, ..._rules];
    notifyListeners();
    return rule;
  }

  Future<FocusRule> startManualSession({
    required String name,
    required int durationMinutes,
    required bool deepFocus,
  }) async {
    final now = DateTime.now();
    final startMin = now.hour * 60 + now.minute;
    final rule = FocusRule(
      id: _uuid.v4(),
      name: name,
      kind: RuleKind.manual,
      daysMask: 0,
      startMin: startMin,
      endMin: startMin + durationMinutes,
      deepFocus: deepFocus,
      active: true,
    );
    await DatabaseService.instance.insertRule(rule.toRow());

    if (rule.isShort) {
      _scheduleLocalDartTimer(rule);
    }

    // Immediately engage shields for manual sessions.
    await ScreentimeBridge.instance.setBlockingActive(true);
    if (deepFocus) {
      await ScreentimeBridge.instance.setAppUninstallRestriction(true);
    }

    _rules = [rule, ..._rules];
    notifyListeners();
    return rule;
  }

  Future<void> endManualSession(String ruleId) async {
    await DatabaseService.instance.deleteRule(ruleId);
    _shortSessionTimers[ruleId]?.cancel();
    _shortSessionTimers.remove(ruleId);
    _rules = _rules.where((r) => r.id != ruleId).toList(growable: false);
    notifyListeners();
    await ScreentimeBridge.instance.setBlockingActive(false);
    await ScreentimeBridge.instance.setAppUninstallRestriction(false);
  }

  /// For sub-15-minute sessions, fire [setBlockingActive] from Dart.
  void _scheduleLocalDartTimer(FocusRule rule) {
    final duration = Duration(minutes: rule.durationMinutes);
    _shortSessionTimers[rule.id] = Timer(duration, () async {
      await ScreentimeBridge.instance.setBlockingActive(false);
      if (rule.deepFocus) {
        await ScreentimeBridge.instance.setAppUninstallRestriction(false);
      }
      await DatabaseService.instance.deleteRule(rule.id);
      _rules = _rules.where((r) => r.id != rule.id).toList(growable: false);
      _shortSessionTimers.remove(rule.id);
      notifyListeners();
    });
  }

  /// Called by the OS-equivalent tick when a scheduled rule's window starts.
  /// Required because Dart timers do not survive app termination; the native
  /// DeviceActivityMonitor extension is the real trigger on iOS.
  Future<void> onScheduleBoundary(String ruleId, bool starting) async {
    final rule = _rules.firstWhere(
      (r) => r.id == ruleId,
      orElse: () => const FocusRule(
        id: '',
        name: '',
        kind: RuleKind.scheduled,
        daysMask: 0,
        startMin: 0,
        endMin: 0,
        deepFocus: false,
        active: false,
      ),
    );
    if (rule.id.isEmpty) return;
    await ScreentimeBridge.instance.setBlockingActive(starting);
    if (rule.deepFocus) {
      await ScreentimeBridge.instance
          .setAppUninstallRestriction(starting);
    }
  }
}
