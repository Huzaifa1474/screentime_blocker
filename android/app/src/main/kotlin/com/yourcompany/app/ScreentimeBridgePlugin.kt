package com.yourcompany.app

import android.content.Context
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * ScreentimeBridgePlugin
 *
 * Native handler for the MethodChannel "com.yourcompany.app/screentime_channel".
 * Implements the three Android-relevant methods:
 *   * requestAuthorization  -> checks if our AccessibilityService is enabled
 *   * selectBlockedApps     -> shows installed-app picker (Activity), saves
 *                              selected package names to SharedPreferences
 *   * setBlockingActive     -> writes the `blocking_active` boolean flag
 *
 * SharedPreferences key: "blocked_packages" (Set<String>)
 * SharedPreferences key: "blocking_active"  (Boolean)
 *
 * The AccessibilityService (AppBlockerService) reads these prefs on every
 * TYPE_WINDOW_STATE_CHANGED event.
 */
class ScreentimeBridgePlugin : FlutterPlugin, MethodCallHandler {

    companion object {
        const val CHANNEL_NAME = "com.yourcompany.app/screentime_channel"
        const val PREFS_NAME = "screentime_blocker_prefs"
        const val KEY_BLOCKED_PACKAGES = "blocked_packages"
        const val KEY_BLOCKING_ACTIVE = "blocking_active"
    }

    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "requestAuthorization" -> handleAuthorization(result)
            "selectBlockedApps" -> handleSelectBlockedApps(result)
            "setBlockingActive" -> handleSetBlockingActive(call, result)
            "setAppUninstallRestriction" -> result.success(false) // iOS-only
            else -> result.notImplemented()
        }
    }

    // ---------------------------------------------------------------------------
    // requestAuthorization
    // ---------------------------------------------------------------------------

    /**
     * Compares the enabled accessibility services string from Settings.Secure
     * against our expected component name (packageName/AppBlockerService).
     * If our service is not enabled, launches ACTION_ACCESSIBILITY_SETTINGS
     * and returns false. The Flutter layer will retry when the user returns.
     */
    private fun handleAuthorization(result: Result) {
        if (isAccessibilityServiceEnabled()) {
            result.success(true)
            return
        }
        // Launch the system accessibility settings so the user can toggle
        // our service on. Return false until enabled.
        val intent = android.content.Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
            addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(intent)
        result.success(false)
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val expected = "${context.packageName}/${AppBlockerService::class.java.name}"
        val enabled = Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        return enabled.split(":").any { it.equals(expected, ignoreCase = true) }
    }

    // ---------------------------------------------------------------------------
    // selectBlockedApps
    // ---------------------------------------------------------------------------

    /**
     * Lists installed user-facing apps (excludes system-only packages with
     * no launcher activity) and returns their package names. The Flutter
     * layer renders the picker UI and persists the chosen set back via a
     * separate call (setBlockingActive reads from SharedPreferences).
     *
     * For simplicity we return all installed launcher packages; the picker
     * UI is rendered in Dart. Persistence of the final selection happens
     * through the dedicated [saveBlockedPackages] method below (invoked
     * via MethodChannel from Dart after the user confirms).
     */
    private fun handleSelectBlockedApps(result: Result) {
        val pm = context.packageManager
        val main = android.content.Intent(android.content.Intent.ACTION_MAIN).apply {
            addCategory(android.content.Intent.CATEGORY_LAUNCHER)
        }
        val packages = pm.queryIntentActivities(main, 0)
            .map { it.activityInfo.packageName }
            .filter { it != context.packageName } // never block ourselves
            .distinct()
        result.success(packages)
    }

    /**
     * Public helper used by MainActivity to persist the user's selection
     * after the Flutter-side picker confirms.
     */
    fun saveBlockedPackages(packages: Set<String>) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putStringSet(KEY_BLOCKED_PACKAGES, packages).apply()
    }

    // ---------------------------------------------------------------------------
    // setBlockingActive
    // ---------------------------------------------------------------------------

    /**
     * Writes the `blocking_active` boolean to SharedPreferences. The
     * AppBlockerService reads this on every window event so it knows
     * whether to enforce shields.
     *
     * Also starts/stops the AppBlockerService as a foreground service so
     * OEM process killers are less likely to kill it.
     */
    private fun handleSetBlockingActive(call: MethodCall, result: Result) {
        val active = call.argument<Boolean>("active") ?: false
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putBoolean(KEY_BLOCKING_ACTIVE, active).apply()

        if (active) {
            AppBlockerService.startForeground(context)
        } else {
            AppBlockerService.stopForeground(context)
        }
        result.success(true)
    }
}
