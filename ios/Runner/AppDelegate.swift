import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        if let registry = self as? FlutterPluginRegistry {
            ScreentimeBridgePlugin.register(with: registry.registrar(forPlugin: "ScreentimeBridgePlugin")!)
        }
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
