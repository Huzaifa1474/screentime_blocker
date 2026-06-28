package com.yourcompany.app

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.widget.Button
import android.widget.TextView
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

/**
 * AppBlockerService
 *
 * Extends AccessibilityService. Listens for TYPE_WINDOW_STATE_CHANGED events
 * (foreground app changes). When the newly-active package matches one in
 * the blocked list and `blocking_active` is true, inflates a full-screen
 * overlay shield (TYPE_ACCESSIBILITY_OVERLAY) covering the offending app.
 *
 * The shield has a Close button that fires ACTION_MAIN with CATEGORY_HOME
 * to bounce the user back to the home screen, then removes the overlay.
 *
 * Run as a FOREGROUND SERVICE with a persistent notification to reduce
 * the chance of OEM process killing (spec: "Android OEM process killing").
 *
 * Deep Focus Mode behavior:
 *   If `deep_focus_active` pref is true and the user opens the system
 *   Settings app, we also draw the shield to prevent them from disabling
 *   our service or uninstalling blockers.
 */
class AppBlockerService : AccessibilityService() {

    companion object {
        private const val CHANNEL_ID = "screentime_blocker_service"
        private const val NOTIFICATION_ID = 4242

        // Packages we always treat as "system settings" for Deep Focus blocking.
        private val SYSTEM_SETTINGS_PACKAGES = setOf(
            "com.android.settings",
            "com.miui.securitycenter",
            "com.samsung.android.settings",
            "com.oppo.settings"
        )

        fun startForeground(context: Context) {
            val intent = Intent(context, AppBlockerService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stopForeground(context: Context) {
            val intent = Intent(context, AppBlockerService::class.java)
            context.stopService(intent)
        }
    }

    private var overlayShieldView: View? = null
    private var isShieldShowing = false
    private var lastBlockedPackage: String? = null

    // -------------------------------------------------------------------------
    // Service lifecycle
    // -------------------------------------------------------------------------

    override fun onServiceConnected() {
        super.onServiceConnected()
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, buildNotification())
    }

    // -------------------------------------------------------------------------
    // Accessibility events
    // -------------------------------------------------------------------------

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return

        val pkg = event.packageName?.toString() ?: return
        if (pkg == packageName) return // ignore our own UI

        val prefs = getSharedPreferences(ScreentimeBridgePlugin.PREFS_NAME, Context.MODE_PRIVATE)
        val blockingActive = prefs.getBoolean(ScreentimeBridgePlugin.KEY_BLOCKING_ACTIVE, false)
        val deepFocus = prefs.getBoolean("deep_focus_active", false)
        val blocked = prefs.getStringSet(ScreentimeBridgePlugin.KEY_BLOCKED_PACKAGES, emptySet())
            ?: emptySet()

        val shouldBlock = blockingActive && pkg in blocked
        val shouldBlockSettings = deepFocus && pkg in SYSTEM_SETTINGS_PACKAGES

        if ((shouldBlock || shouldBlockSettings) && !isShieldShowing) {
            lastBlockedPackage = pkg
            drawOverlayShield()
        } else if (!shouldBlock && !shouldBlockSettings && isShieldShowing) {
            removeOverlayShield()
        }
    }

    override fun onInterrupt() {
        // No-op. Called when the service is being interrupted.
    }

    // -------------------------------------------------------------------------
    // Overlay drawing
    // -------------------------------------------------------------------------

    /**
     * Inflates R.layout.shield_overlay and attaches it as a
     * TYPE_ACCESSIBILITY_OVERLAY window. The overlay is full-screen,
     * non-focusable (so the back button still works to escape), and
     * sits above the offending app's UI.
     */
    fun drawOverlayShield() {
        if (overlayShieldView != null) return

        val wm = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        val inflater = LayoutInflater.from(this)
        val view = inflater.inflate(R.layout.shield_overlay, null, false)

        view.findViewById<TextView>(R.id.shield_message).text =
            "Access Locked by Screentime Rules"

        view.findViewById<Button>(R.id.shield_close_button).setOnClickListener {
            // Bounce the user back to the home screen, then remove the overlay.
            val home = Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_HOME)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(home)
            removeOverlayShield()
        }

        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
            WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY
        else
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_SYSTEM_ALERT

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            type,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        )

        try {
            wm.addView(view, params)
            overlayShieldView = view
            isShieldShowing = true
        } catch (e: Exception) {
            // TYPE_ACCESSIBILITY_OVERLAY requires the accessibility service to
            // be enabled. If we get here without that, log and bail.
            android.util.Log.e("AppBlockerService", "drawOverlayShield failed", e)
        }
    }

    /**
     * Removes the overlay if it is currently showing.
     */
    fun removeOverlayShield() {
        val view = overlayShieldView ?: return
        val wm = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        try {
            wm.removeView(view)
        } catch (e: Exception) {
            android.util.Log.w("AppBlockerService", "removeView failed", e)
        }
        overlayShieldView = null
        isShieldShowing = false
    }

    // -------------------------------------------------------------------------
    // Foreground notification (process-keeping)
    // -------------------------------------------------------------------------

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = android.app.NotificationChannel(
                CHANNEL_ID,
                "Screentime Blocker",
                android.app.NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Keeps the blocker running so shields stay applied."
                setShowBadge(false)
            }
            val nm = getSystemService(NotificationManager::class.java)
            nm.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): android.app.Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Screentime Blocker is active")
            .setContentText("Shield rules are being enforced.")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }
}
