import ManagedSettings
import SwiftUI
import UIKit

/// ShieldConfigurationExtension
///
/// Implements `ShieldConfigurationDataSource`. The OS asks this extension
/// for the configuration of the block screen that appears when a user
/// attempts to launch a shielded app. We return a SwiftUI-rendered
/// configuration that shows our custom "Waiting Room" UI.
///
/// Visual concept: dark background, breathing circle animation, a single
/// "Breathe" call-to-action, and a small "Close" button that returns the
/// user to the home screen (handled by the ShieldActionExtension).
class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurRadius: 0,
            backgroundColor: UIColor.black,
            icon: UIImage(systemName: "lock.shield.fill"),
            title: ShieldConfiguration.Label(
                text: "Access Locked",
                color: UIColor.white
            ),
            subtitle: ShieldConfiguration.Label(
                text: "This app is paused by your Screentime Rules.",
                color: UIColor(white: 0.7, alpha: 1.0)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Breathe",
                color: UIColor.black
            ),
            primaryButtonBackgroundColor: UIColor.white,
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Close",
                color: UIColor(white: 0.85, alpha: 1.0)
            )
        )
    }

    override func configuration(shielding application: Application,
                                in category: ActivityCategory) -> ShieldConfiguration {
        configuration(shielding: application)
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurRadius: 0,
            backgroundColor: UIColor.black,
            icon: UIImage(systemName: "safari.fill"),
            title: ShieldConfiguration.Label(
                text: "Site Locked",
                color: UIColor.white
            ),
            subtitle: ShieldConfiguration.Label(
                text: "This site is paused by your Screentime Rules.",
                color: UIColor(white: 0.7, alpha: 1.0)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Breathe",
                color: UIColor.black
            ),
            primaryButtonBackgroundColor: UIColor.white,
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Close",
                color: UIColor(white: 0.85, alpha: 1.0)
            )
        )
    }

    override func configuration(shielding webDomain: WebDomain,
                                in category: ActivityCategory) -> ShieldConfiguration {
        configuration(shielding: webDomain)
    }
}
