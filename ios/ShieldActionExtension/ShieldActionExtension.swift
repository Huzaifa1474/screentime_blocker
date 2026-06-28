import ManagedSettings
import UIKit

/// ShieldActionExtension
///
/// Implements `ShieldActionDelegate`. The OS calls this when the user taps
/// a button on the custom shield screen rendered by
/// `ShieldConfigurationExtension`.
///
/// Behavior:
///   * Primary button ("Breathe") -> returns .close. The OS dismisses the
///     shield and the user is left on the home screen. The "Breathe"
///     label is intentional — it primes the user to pause rather than
///     immediately look for another app.
///   * Secondary button ("Close") -> returns .close.
class ShieldActionExtension: ShieldActionDelegate {

    override func handle(action: ShieldAction,
                         for application: Application,
                         completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            // The "Breathe" button. Dismiss the shield but stay calm.
            completionHandler(.close)
        case .secondaryButtonPressed:
            // The "Close" button. Dismiss the shield.
            completionHandler(.close)
        @unknown default:
            completionHandler(.close)
        }
    }

    override func handle(action: ShieldAction,
                         for application: Application,
                         in category: ActivityCategory,
                         completionHandler: @escaping (ShieldActionResponse) -> Void) {
        handle(action: action, for: application, completionHandler: completionHandler)
    }

    override func handle(action: ShieldAction,
                         for webDomain: WebDomain,
                         completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            completionHandler(.close)
        case .secondaryButtonPressed:
            completionHandler(.close)
        @unknown default:
            completionHandler(.close)
        }
    }

    override func handle(action: ShieldAction,
                         for webDomain: WebDomain,
                         in category: ActivityCategory,
                         completionHandler: @escaping (ShieldActionResponse) -> Void) {
        handle(action: action, for: webDomain, completionHandler: completionHandler)
    }
}
