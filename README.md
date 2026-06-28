# Screentime Blocker

A Flutter screen time blocker app for iOS (16.0+) and Android (6.0+).

* **iOS**: Uses Apple's `FamilyControls`, `ManagedSettings`, and `DeviceActivity` frameworks. The OS enforces blocks natively — no VPN required.
* **Android**: Uses an `AccessibilityService` to detect foreground app changes and draws a full-screen overlay (`TYPE_ACCESSIBILITY_OVERLAY`) to block target apps.
* **Optional iOS fallback**: A local on-device VPN profile for blocking Safari and browser-based domains.

## Architecture

```
┌────────────────────────────────────────────────────────────┐
│                     Flutter (Dart)                         │
│                                                            │
│   lib/services/screentime_bridge.dart                      │
│     ↳ MethodChannel: com.yourcompany.app/screentime_channel│
│                                                            │
│   lib/services/database_service.dart    (SQLite, on-device)│
│   lib/services/focus_score_service.dart (0..100 scoring)   │
│   lib/services/rules_engine.dart        (schedules / manual)│
└────────────────────────────────────────────────────────────┘
        │                                │
        ▼ (iOS)                          ▼ (Android)
┌────────────────────────────┐  ┌─────────────────────────────┐
│  ios/Runner/               │  │  android/app/...kotlin/     │
│    ScreentimeBridgePlugin  │  │    ScreentimeBridgePlugin   │
│    AppDelegate             │  │    MainActivity             │
│                            │  │    AppBlockerService        │
│  ios/DeviceActivityMonitor │  │  res/xml/                   │
│    Extension/              │  │    accessibility_service_   │
│  ios/ShieldConfiguration   │  │    config.xml               │
│    Extension/              │  │  res/layout/                │
│  ios/ShieldAction          │  │    shield_overlay.xml       │
│    Extension/              │  │                             │
└────────────────────────────┘  └─────────────────────────────┘
```

## iOS targets

The main Flutter app cannot apply restrictions directly. Four Xcode targets:

| Target                              | Role                                                                 |
| ----------------------------------- | -------------------------------------------------------------------- |
| `Runner` (main app)                 | UI, MethodChannel, FamilyControls authorization                     |
| `DeviceActivityMonitorExtension`    | Triggers shield rules on schedule start/end (interval boundary)     |
| `ShieldConfigurationExtension`      | Renders the custom block screen UI                                  |
| `ShieldActionExtension`             | Handles button taps on the block screen                             |

All four targets share the App Group **`group.com.yourcompany.app.shared`**.

The main app entitlement file (`ios/Runner/Runner.entitlements`) must contain:

```xml
<key>com.apple.developer.family-controls</key>
<true/>
```

> ⚠️ The `com.apple.developer.family-controls` entitlement must be formally
> requested from Apple before App Store or TestFlight distribution. Submit
> the request early via <https://developer.apple.com/contact/request/competition-entitlement/> with a clear privacy data flow explanation.

### Xcode setup checklist

1. Open `ios/Runner.xcworkspace` in Xcode.
2. Add three new targets of type **Application Extension**:
   * `DeviceActivityMonitorExtension` — template: *Device Activity Monitor Extension*
   * `ShieldConfigurationExtension` — template: *Shield Configuration Extension*
   * `ShieldActionExtension` — template: *Shield Action Extension*
3. For each target, enable the App Groups capability and add `group.com.yourcompany.app.shared`.
4. For each target, add the `com.apple.developer.family-controls` entitlement.
5. Set the bundle identifiers as suffixes of the main app:
   * `com.yourcompany.app.monitor`
   * `com.yourcompany.app.shieldconfig`
   * `com.yourcompany.app.shieldaction`
6. Add the Swift sources in `ios/<ExtensionName>/` to their respective targets.

## Android permissions

`AndroidManifest.xml` declares:

| Permission                                | Why                                                            |
| ----------------------------------------- | -------------------------------------------------------------- |
| `BIND_ACCESSIBILITY_SERVICE`              | Required for `AppBlockerService` to detect foreground changes |
| `PACKAGE_USAGE_STATS`                     | Required to query foreground app usage                         |
| `SYSTEM_ALERT_WINDOW`                     | Legacy fallback for older Android (pre-API-22 overlay types)   |
| `FOREGROUND_SERVICE` + `_SPECIAL_USE`     | Keeps `AppBlockerService` alive; reduces OEM process killing   |
| `POST_NOTIFICATIONS`                      | Android 13+ persistent foreground notification                 |

The accessibility service is registered with the config in
`res/xml/accessibility_service_config.xml`:

* `accessibilityEventTypes = "typeWindowStateChanged"`
* `canRetrieveWindowContent = "true"`
* `packageNames = ""` (listens to all packages)

## MethodChannel contract

Channel: `com.yourcompany.app/screentime_channel`

| Method                        | iOS behavior                                                          | Android behavior                                              |
| ----------------------------- | -------------------------------------------------------------------- | ------------------------------------------------------------- |
| `requestAuthorization`        | `AuthorizationCenter.shared.requestAuthorization(for: .individual)` | Checks enabled accessibility services; opens Settings if not  |
| `selectBlockedApps`           | Presents `FamilyActivityPicker`, persists JSON to shared UserDefaults | Returns installed launcher packages; Dart persists to prefs   |
| `setBlockingActive(active:)`  | Applies / clears `ManagedSettingsStore.shield`                       | Writes `blocking_active` bool to SharedPreferences             |
| `setAppUninstallRestriction`  | Sets `store.application.denyAppRemoval`                              | Returns `false` (no-op)                                       |

## Onboarding flow

| Step | Screen                | Notes                                                                 |
| ---- | --------------------- | -------------------------------------------------------------------- |
| 1    | Splash                | Black `#000000`, initializes SQLite                                  |
| 2    | Diagnostic            | Daily estimate slider, focus goal                                    |
| 3-15 | Personalization quiz  | Grid layout, selectable cards, distraction categories                |
| 16   | Cognitive shock       | "6 years scrolling" stat + high-contrast bar chart                   |
| 17   | Micro-commitment      | Tap-and-hold "fist bump" (2.5s mandatory)                            |
| 18   | Paywall               | 7-day free trial on annual plan, before/after cards                  |
| 19   | Permission gateway    | Calls `requestSystemAuthorization()`. Cannot proceed until `true`    |
| 20   | VPN setup             | Optional local VPN profile for Safari domain filtering               |
| 21   | Milestone unlock      | 3D animated gem on black background                                  |
| 22   | Dashboard             | Circular Focus Score dial, active schedules, today's stats           |
| 23   | Rules engine          | Schedule sessions, manual focus, Deep Focus toggle                   |
| 24   | Waiting room          | Block screen with breathing animation or color game                  |

## Psychological friction features

1. **Waiting Room Delay** — `lib/features/waiting_room_delay.dart`. Mandatory progress bar; min 15s, max 4h depending on session type. No skip.
2. **Color Game** — `lib/features/color_game.dart`. Stroop task: tap the font color, not the meaning.
3. **Take a Break** — `lib/features/take_a_break.dart`. Pick 5/15/30 min; clears shields; auto re-applies them when the timer hits zero. No user action required to re-enable.
4. **Deep Focus Mode** — `lib/features/deep_focus_mode.dart`. No pause, no override, no break. iOS: `setAppUninstallRestriction(true)`. Android: `AppBlockerService` overlays the system Settings app.

## 14-day behavioral program

| Day      | Milestone                                                                |
| -------- | ------------------------------------------------------------------------ |
| Day 1    | User sets up scheduled block sessions (e.g. Mon–Fri, 9–5)               |
| Days 2-5 | App calculates Focus Score (0..100) from pickups, notifications, blocked time |
| Day 6    | Focus Report: hours saved, peer comparison                               |
| Days 7-14| Daily app time budgets, cross-device sync option (Chrome ext, macOS)     |
| Day 14+  | Styled 3D milestone gems, shareable to social media                      |

## Known constraints

| Constraint                                | How we handle it                                                                  |
| ----------------------------------------- | --------------------------------------------------------------------------------- |
| iOS 15-minute scheduling minimum          | Sub-15-minute sessions use a local Dart `Timer` calling `setBlockingActive()` directly instead of `DeviceActivityCenter` |
| iOS 50-token limit                        | Prefer category tokens over individual app tokens when persisting selections      |
| Opaque app tokens                         | Never decode `FamilyActivitySelection` bundle IDs; pass tokens as opaque handles |
| Android OEM process killing               | `AppBlockerService` runs as a foreground service with a persistent notification   |
| Google Play accessibility service review  | All usage data stays strictly on-device. Service declaration clearly documents usage |
| Apple `family-controls` entitlement gate  | Submit the entitlement request early with a clear privacy data flow explanation   |

## Privacy

* All usage data stays **on-device**. No network calls.
* SQLite is the only persistence layer (focus scores, rules, milestones, diagnostics).
* The AccessibilityService does not read screen content; it only reacts to which app is in the foreground.
* The iOS ShieldConfiguration extension renders a static shield; no content from the blocked app is captured.

## Running locally

```bash
# Flutter >= 3.19
cd screentime_blocker
flutter pub get
flutter run                    # iOS or Android
```

For iOS, open `ios/Runner.xcworkspace` in Xcode and configure the four targets as described above before running on a physical device (FamilyControls does not work in the simulator).

## License

Proprietary. Replace `com.yourcompany` with your real bundle identifier before shipping.
