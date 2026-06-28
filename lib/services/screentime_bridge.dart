// Screentime Bridge — Dart-side MethodChannel bridge.
//
// Mirrors the four-method contract documented in the spec:
//   * requestSystemAuthorization()  -> bool
//   * selectBlockedApps()           -> List<String>   (iOS returns opaque tokens)
//   * setBlockingActive(bool)       -> bool
//   * setAppUninstallRestriction(bool) -> bool  (iOS only; Android returns false)
//
// Channel name: com.yourcompany.app/screentime_channel
//
// IMPORTANT: On iOS, the FamilyActivitySelection tokens returned by the
// native picker are OPAQUE. They are NOT bundle IDs. The Dart layer must
// treat them as opaque handles and never attempt to decode them.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Contract for the platform channel. Mockable in tests.
abstract class ScreentimeBridgeApi {
  Future<bool> requestSystemAuthorization();
  Future<List<String>> selectBlockedApps();
  Future<bool> setBlockingActive(bool active);
  Future<bool> setAppUninstallRestriction(bool restrict);
}

/// Singleton bridge wrapping the platform MethodChannel.
///
/// Usage:
///   final ok = await ScreentimeBridge.instance.requestSystemAuthorization();
class ScreentimeBridge implements ScreentimeBridgeApi {
  ScreentimeBridge._() {
    _channel.setMethodCallHandler(_handleNativeCalls);
  }
  static final ScreentimeBridge instance = ScreentimeBridge._();

  /// MethodChannel name — MUST match the Swift plugin and Kotlin plugin.
  static const String channelName = 'com.yourcompany.app/screentime_channel';

  /// Shared App Group identifier used by all iOS targets.
  static const String appGroup = 'group.com.yourcompany.app.shared';

  /// SharedPreferences key under which we persist the active state.
  static const String _kBlockingActiveKey = 'blocking_active';

  /// SharedPreferences key for selected apps (opaque tokens on iOS).
  static const String _kBlockedAppsKey = 'blocked_apps_tokens';

  final MethodChannel _channel = const MethodChannel(channelName);

  /// Stream of blocking-state changes pushed from the native side.
  /// Used by [TakeABreakService] and [RulesEngineService] to react when
  /// the OS re-applies shields (e.g. on a DeviceActivity schedule boundary).
  final StreamController<bool> _blockingStateController =
      StreamController<bool>.broadcast();
  Stream<bool> get blockingStateStream => _blockingStateController.stream;

  /// Cache of the last-known selection (opaque tokens).
  List<String> _cachedTokens = const <String>[];

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  @override
  Future<bool> requestSystemAuthorization() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestAuthorization');
      return result ?? false;
    } on PlatformException catch (e) {
      // On iOS this throws if the family-controls entitlement is missing.
      // On Android this is normal until the user enables the service.
      _log('requestAuthorization failed: ${e.code} / ${e.message}');
      return false;
    }
  }

  @override
  Future<List<String>> selectBlockedApps() async {
    try {
      final result =
          await _channel.invokeMethod<List<dynamic>>('selectBlockedApps');
      final tokens = (result ?? const <dynamic>[])
          .map((dynamic e) => e.toString())
          .toList(growable: false);
      _cachedTokens = tokens;
      await _persistTokensLocally(tokens);
      return tokens;
    } on PlatformException catch (e) {
      _log('selectBlockedApps failed: ${e.code} / ${e.message}');
      return const <String>[];
    }
  }

  @override
  Future<bool> setBlockingActive(bool active) async {
    try {
      final result = await _channel
          .invokeMethod<bool>('setBlockingActive', <String, dynamic>{
        'active': active,
      });
      final ok = result ?? false;
      if (ok) {
        await _persistBlockingActiveLocally(active);
        _blockingStateController.add(active);
      }
      return ok;
    } on PlatformException catch (e) {
      _log('setBlockingActive failed: ${e.code} / ${e.message}');
      return false;
    }
  }

  @override
  Future<bool> setAppUninstallRestriction(bool restrict) async {
    try {
      final result = await _channel
          .invokeMethod<bool>('setAppUninstallRestriction', <String, dynamic>{
        'restrict': restrict,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      _log('setAppUninstallRestriction failed: ${e.code} / ${e.message}');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Persistence helpers (local cache only — native side is source of truth)
  // ---------------------------------------------------------------------------

  Future<void> _persistTokensLocally(List<String> tokens) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBlockedAppsKey, jsonEncode(tokens));
  }

  Future<void> _persistBlockingActiveLocally(bool active) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBlockingActiveKey, active);
  }

  Future<List<String>> loadCachedTokens() async {
    if (_cachedTokens.isNotEmpty) return _cachedTokens;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kBlockedAppsKey);
    if (raw == null) return const <String>[];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      _cachedTokens = list.map((e) => e.toString()).toList(growable: false);
      return _cachedTokens;
    } catch (_) {
      return const <String>[];
    }
  }

  Future<bool> loadCachedBlockingActive() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kBlockingActiveKey) ?? false;
  }

  // ---------------------------------------------------------------------------
  // Native -> Dart callbacks
  // ---------------------------------------------------------------------------

  Future<dynamic> _handleNativeCalls(MethodCall call) async {
    switch (call.method) {
      case 'onBlockingStateChanged':
        final active = (call.arguments['active'] as bool?) ?? false;
        await _persistBlockingActiveLocally(active);
        _blockingStateController.add(active);
        return null;
      case 'onDeepFocusIntercepted':
        // Fired by Android AppBlockerService when the user navigates to
        // system Settings while Deep Focus Mode is on.
        _log('Deep Focus intercepted system Settings access.');
        return null;
      default:
        return null;
    }
  }

  void _log(String msg) {
    // Replace with proper logging framework in production.
    // ignore: avoid_print
    print('[ScreentimeBridge] $msg');
  }
}
