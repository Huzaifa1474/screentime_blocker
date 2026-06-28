import DeviceActivity
import ManagedSettings
import Foundation

/// DeviceActivityMonitorExtension
///
/// Registered as the `DeviceActivityMonitor` extension target. The OS calls
/// these lifecycle methods when a DeviceActivitySchedule starts, ends, or
/// hits an interval boundary. We use this to apply or clear ManagedSettings
/// shield rules at the right moment, without the main app needing to be
/// running.
///
/// Shared App Group: group.com.yourcompany.app.shared
/// Shared UserDefaults key: "family_activity_selection_json"
class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    private let store = ManagedSettingsStore()
    private let appGroup = "group.com.yourcompany.app.shared"
    private let selectionKey = "family_activity_selection_json"

    // MARK: - Schedule lifecycle

    override func intervalDidStart(for activity: DeviceActivityName) {
        NSLog("[DeviceActivityMonitor] intervalDidStart: \(activity.rawValue)")
        applyShields()
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        NSLog("[DeviceActivityMonitor] intervalDidEnd: \(activity.rawValue)")
        clearShields()
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name,
                                         activity: DeviceActivityName) {
        NSLog("[DeviceActivityMonitor] event threshold reached: \(event.rawValue)")
        // Used for "you've used this app for 30 minutes today" style blocks.
        applyShields()
    }

    // MARK: - Shield management

    private func applyShields() {
        guard let selection = loadSelection() else {
            NSLog("[DeviceActivityMonitor] no selection; cannot apply shields")
            return
        }
        if !selection.applicationTokens.isEmpty {
            store.shield.applications = selection.applicationTokens
        }
        if !selection.categoryTokens.isEmpty {
            store.shield.applicationCategories = .specific(
                selection.categoryTokens,
                except: Set<ApplicationToken>()
            )
        }
        if !selection.webDomainTokens.isEmpty {
            store.shield.webDomains = selection.webDomainTokens
        }
    }

    private func clearShields() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
    }

    // MARK: - Persistence (shared with main app)

    private func loadSelection() -> FamilyActivitySelection? {
        guard let defaults = UserDefaults(suiteName: appGroup),
              let data = defaults.data(forKey: selectionKey) else {
            return nil
        }
        return try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
    }
}
