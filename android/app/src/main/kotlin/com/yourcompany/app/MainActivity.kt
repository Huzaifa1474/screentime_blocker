package com.yourcompany.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val plugin = ScreentimeBridgePlugin()
        flutterEngine.plugins.add(plugin)

        // Register a side-channel so the Dart picker can persist the chosen
        // package set after the user confirms.
        io.flutter.plugin.common.MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.yourcompany.app/screentime_channel"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveBlockedPackages" -> {
                    val packages = call.argument<List<String>>("packages") ?: emptyList()
                    plugin.saveBlockedPackages(packages.toSet())
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
