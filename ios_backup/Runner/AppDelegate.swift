import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Register the ScreentimeBridge plugin with the Flutter engine.
        let controller = window?.rootViewController as? FlutterViewController
        if let controller = controller {
            ScreentimeBridgePlugin.register(
                with: controller.registrar(forPlugin: "ScreentimeBridgePlugin")!
            )
        }

        // Disable Flutter's default view controller bouncing so our SwiftUI
        // presentation animates cleanly on top.
        GeneratedPluginRegistrant.register(with: self)

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
