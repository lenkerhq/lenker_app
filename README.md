# Lenker App

Desktop VPN client for Lenker providers.

## Status

**Stage C1.1: Account auth foundation.** The app has real consumer account
registration/sign-in connected to the panel-api backend, keeps the provider
handoff path as an invite-token fallback, displays subscription info and
available regions, but does not yet connect to a VPN.

The VPN engine (sing-box integration) is planned for Stage C2.

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

To point account registration/sign-in at a deployed Lenker API:

```sh
flutter run -d macos --dart-define=LENKER_ACCOUNT_API_URL=https://api.example.com
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
│   ├── onboarding_screen.dart  # Account sign-in/register + invite token fallback
│   ├── home_screen.dart        # Account-only state or subscription info
│   └── diagnostics_screen.dart # Debug info, logout
└── services/
    ├── api_client.dart          # HTTP client for panel-api (accounts + handoff)
    ├── account_service.dart     # Consumer account session storage
    ├── auth_service.dart        # Subscription access token storage
    └── subscription_service.dart # Subscription state
```

## Flow

1. User sees account sign-in / account creation as the primary entry point.
2. App calls `POST /api/v1/accounts/register` or `POST /api/v1/accounts/login`.
3. Account session token is stored securely (keychain/keyring), separate from subscription access.
4. After login, app shows home state. If no subscription, user can add one via invite token.
5. Invite token fallback: `POST /api/v1/client/handoff/claim` exchanges invite for access token.
6. Access token is stored securely. App fetches subscription access info.
7. Connect button is disabled until VPN engine is implemented (Stage C2).

## License

AGPL-3.0-only (same as Lenker core).
