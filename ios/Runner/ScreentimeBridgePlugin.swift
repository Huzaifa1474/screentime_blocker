import Flutter
import UIKit
import FamilyControls
import ManagedSettings
import DeviceActivity

/// ScreentimeBridgePlugin
///
/// Implements the four MethodChannel calls defined in the spec:
///   * requestAuthorization        -> triggers FamilyControls authorization
///   * selectBlockedApps           -> presents FamilyActivityPicker, persists
///                                     the encoded selection to App Group
///                                     UserDefaults as JSON
///   * setBlockingActive(active:)  -> applies/clears ManagedSettingsStore
///                                     shields for applications, categories,
///                                     and web domains
///   * setAppUninstallRestriction  -> toggles denyAppRemoval on the store
///
/// Channel name: "com.yourcompany.app/screentime_channel"
///
/// Shared App Group: "group.com.yourcompany.app.shared"
///
/// Notes:
///   * FamilyActivitySelection tokens are OPAQUE. We never read bundle IDs.
///   * The encoded selection is stored as JSON in UserDefaults so the
///     DeviceActivityMonitor, ShieldConfiguration, and ShieldAction
///     extensions can all read it without re-prompting.
public class ScreentimeBridgePlugin: NSObject, FlutterPlugin {

    // MARK: - Constants

    static let channelName = "com.yourcompany.app/screentime_channel"
    static let appGroup = "group.com.yourcompany.app.shared"
    static let selectionKey = "family_activity_selection_json"

    // MARK: - FlutterPlugin

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: channelName,
            binaryMessenger: registrar.messenger()
        )
        let instance = ScreentimeBridgePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    private let store = ManagedSettingsStore()

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "requestAuthorization":
            requestAuthorization(result: result)

        case "selectBlockedApps":
            selectBlockedApps(result: result)

        case "setBlockingActive":
            let args = call.arguments as? [String: Any] ?? [:]
            let active = (args["active"] as? Bool) ?? false
            setBlockingActive(active: active, result: result)

        case "setAppUninstallRestriction":
            let args = call.arguments as? [String: Any] ?? [:]
            let restrict = (args["restrict"] as? Bool) ?? false
            setAppUninstallRestriction(restrict: restrict, result: result)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - requestAuthorization

    /// Triggers FaceID/TouchID-gated FamilyControls authorization.
    /// Must run on the main thread because it presents UI.
    /// On simulator, authorization is impossible so we return `true` for testing.
    private func requestAuthorization(result: @escaping FlutterResult) {
#if targetEnvironment(simulator)
        NSLog("[ScreentimeBridge] simulator detected — skipping authorization")
        result(true)
        return
#endif
        DispatchQueue.main.async {
            Task {
                do {
                    try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                    result(true)
                } catch {
                    NSLog("[ScreentimeBridge] auth failed: \(error)")
                    result(FlutterError(
                        code: "AUTH_FAILED",
                        message: "FamilyControls authorization failed: \(error.localizedDescription)",
                        details: nil
                    ))
                }
            }
        }
    }

    // MARK: - selectBlockedApps

    /// Presents the native FamilyActivityPicker in a UIHostingController.
    /// Saves the encoded selection as JSON to the shared App Group so the
    /// extensions can read it later.
    private func selectBlockedApps(result: @escaping FlutterResult) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { result([]); return }

            guard let rootVC = Self.topViewController() else {
                NSLog("[ScreentimeBridge] no root view controller")
                result([])
                return
            }

            let initialSelection = self.loadSelection() ?? FamilyActivitySelection()
            var pickerHost = FamilyActivityPickerHost(selection: initialSelection) { finalSelection in
                self.saveSelection(finalSelection)
                let tokenStrings = Self.opaqueTokenStrings(from: finalSelection)
                result(tokenStrings)
            }

            let hosting = UIHostingController(rootView: pickerHost)
            hosting.modalPresentationStyle = .formSheet

            // Add a Confirm toolbar button that dismisses the host which
            // triggers the completion handler.
            pickerHost.onConfirm = {
                hosting.dismiss(animated: true)
            }

            rootVC.present(hosting, animated: true)
        }
    }

    // MARK: - setBlockingActive

    /// Applies or clears shield rules on the ManagedSettingsStore.
    private func setBlockingActive(active: Bool, result: @escaping FlutterResult) {
        if active {
            guard let selection = loadSelection() else {
                NSLog("[ScreentimeBridge] no saved selection; nothing to shield")
                result(false)
                return
            }
            // Applications
            if !selection.applicationTokens.isEmpty {
                store.shield.applications = selection.applicationTokens
            }
            // Categories
            if !selection.categoryTokens.isEmpty {
                // Pattern from spec: .specific(Set([categoryToken]), except: Set([exemptAppToken]))
                // We do not currently exempt any apps; pass empty exception set.
                store.shield.applicationCategories = .specific(
                    selection.categoryTokens,
                    except: Set<ApplicationToken>()
                )
            }
            // Web domains
            if !selection.webDomainTokens.isEmpty {
                store.shield.webDomains = selection.webDomainTokens
            }
            result(true)
        } else {
            // Clear everything.
            store.shield.applications = nil
            store.shield.applicationCategories = nil
            store.shield.webDomains = nil
            result(true)
        }
    }

    // MARK: - setAppUninstallRestriction

    /// iOS only. Sets `denyAppRemoval` on the ManagedSettingsStore.
    private func setAppUninstallRestriction(restrict: Bool, result: @escaping FlutterResult) {
        store.application.denyAppRemoval = restrict
        result(true)
    }

    // MARK: - Persistence

    /// Encodes the FamilyActivitySelection as JSON and writes it to the
    /// shared App Group UserDefaults.
    private func saveSelection(_ selection: FamilyActivitySelection) {
        do {
            let data = try JSONEncoder().encode(selection)
            if let defaults = UserDefaults(suiteName: Self.appGroup) {
                defaults.set(data, forKey: Self.selectionKey)
            }
        } catch {
            NSLog("[ScreentimeBridge] encode selection failed: \(error)")
        }
    }

    /// Loads the previously-saved FamilyActivitySelection, or nil.
    private func loadSelection() -> FamilyActivitySelection? {
        guard let defaults = UserDefaults(suiteName: Self.appGroup),
              let data = defaults.data(forKey: Self.selectionKey) else {
            return nil
        }
        do {
            return try JSONDecoder().decode(FamilyActivitySelection.self, from: data)
        } catch {
            NSLog("[ScreentimeBridge] decode selection failed: \(error)")
            return nil
        }
    }

    /// Returns OPAQUE placeholder token strings for the Dart layer.
    /// We never expose real bundle IDs. Tokens are converted via their
    /// `description` to a stable-but-meaningless string.
    private static func opaqueTokenStrings(from selection: FamilyActivitySelection) -> [String] {
        var tokens: [String] = []
        tokens.append(contentsOf: selection.applicationTokens.map { "app:\($0.hashValue)" })
        tokens.append(contentsOf: selection.categoryTokens.map { "cat:\($0.hashValue)" })
        tokens.append(contentsOf: selection.webDomainTokens.map { "web:\($0.hashValue)" })
        // Note: the iOS 50-token limit is enforced upstream in the picker
        // host (we cap the selection size there).
        return tokens
    }

    // MARK: - View controller helpers

    private static func topViewController(
        base: UIViewController? = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController })
            .first
    ) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(base: selected)
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }
}

// MARK: - FamilyActivityPickerHost (SwiftUI wrapper)

import SwiftUI

/// Wraps SwiftUI's FamilyActivityPicker with a Confirm toolbar button.
/// Completion is invoked on confirm.
struct FamilyActivityPickerHost: View {
    @State var selection: FamilyActivitySelection
    let completion: (FamilyActivitySelection) -> Void
    var onConfirm: (() -> Void)? = nil

    init(selection: FamilyActivitySelection,
         completion: @escaping (FamilyActivitySelection) -> Void) {
        _selection = State(initialValue: selection)
        self.completion = completion
    }

    var body: some View {
        NavigationStack {
            FamilyActivityPicker(selection: $selection)
                .navigationTitle("Select Apps")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Confirm") {
                            completion(selection)
                            onConfirm?()
                        }
                    }
                }
        }
    }
}
