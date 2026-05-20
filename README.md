# Lenker App

Desktop VPN client for Lenker providers.

## Status

**Stage C1: Shell only.** The app handles provider handoff (invite token claim),
displays subscription info and available regions, but does not yet connect to a
VPN. The VPN engine (sing-box integration) is planned for Stage C2.

## Platforms

- Linux Desktop
- macOS Desktop

## Prerequisites

- Flutter SDK 3.2+
- Linux: `libsecret-1-dev`, `libjsoncpp-dev` (for flutter_secure_storage)
- macOS: Xcode

## Run

```sh
flutter pub get
flutter run -d linux
flutter run -d macos
```

## Build

```sh
flutter build linux --release
flutter build macos --release
```

## Project Structure

```
lib/
├── main.dart              # Entry point, window setup, providers
├── app.dart               # MaterialApp, routing, theme
├── models/
│   ├── subscription.dart  # SubscriptionAccess, AccessEntry, RegionNode
│   └── connection_state.dart
├── screens/
│   ├── onboarding_screen.dart  # Invite token claim
│   ├── home_screen.dart        # Subscription info, region selector
│   └── diagnostics_screen.dart # Debug info, logout
└── services/
    ├── api_client.dart          # HTTP client for panel-api
    ├── auth_service.dart        # Secure token storage
    └── subscription_service.dart # Subscription state
```

## Flow

1. User enters provider panel URL and invite token on onboarding screen.
2. App calls `POST /api/v1/client/handoff/claim` to exchange the invite for an access token.
3. Access token is stored securely (keychain/keyring).
4. App fetches subscription access info and displays plan, regions, and nodes.
5. Connect button is disabled until VPN engine is implemented (Stage C2).

## License

AGPL-3.0-only (same as Lenker core).
