# Lenker App

Cross-platform desktop VPN client for the [Lenker](https://github.com/lenkerhq/lenker_panel) ecosystem. Built with Flutter.

## Status

**Stage C1.1 — Account auth foundation.**

The app currently:
- Registers and signs in consumer accounts against the Lenker `panel-api` backend
- Keeps provider handoff (invite token) as a fallback path
- Displays subscription info and available regions
- Stores tokens locally via platform-appropriate storage

The VPN tunnel is **not yet connected** — the connect button is a placeholder until Stage C2 (sing-box engine integration).

## Ecosystem

| Repository | Role |
|---|---|
| [`lenker_panel`](https://github.com/lenkerhq/lenker_panel) | Backend control plane, node agent, web admin, migrations, deployment |
| `lenker_app` (this repo) | End-user desktop/mobile client |

## Platforms

| Platform | Status |
|---|---|
| Linux Desktop | ✅ supported |
| macOS Desktop | ✅ supported |
| Windows Desktop | planned |
| Android | planned |
| iOS | post-MVP |

## Quick Start

```sh
flutter pub get
flutter run -d macos   # or -d linux
```

Default API: `https://n8n.tayca.store/panel-api`

Custom API:
```sh
flutter run -d macos --dart-define=LENKER_ACCOUNT_API_URL=https://your-api.example.com
```

## Prerequisites

- Flutter SDK 3.2+
- Linux: `libsecret-1-dev`, `libjsoncpp-dev`
- macOS: Xcode 14+

## Build & Test

```sh
flutter analyze
flutter test
flutter build linux --release
flutter build macos --release
```

## Project Structure

```
lib/
├── main.dart                    # Entry point, providers, window setup
├── app.dart                     # MaterialApp, routing, theme
├── models/
│   ├── subscription.dart        # SubscriptionAccess, AccessEntry, RegionNode
│   └── connection_state.dart
├── screens/
│   ├── onboarding_screen.dart   # Sign-in/register + invite-token fallback
│   ├── home_screen.dart         # Account state or subscription view
│   └── diagnostics_screen.dart  # Debug info, logout
└── services/
    ├── api_client.dart          # HTTP client (accounts + handoff)
    ├── account_service.dart     # Consumer account session
    ├── auth_service.dart        # Subscription access token
    ├── subscription_service.dart # Subscription state + refresh
    └── secure_kv_store.dart     # Cross-platform secret storage
```

## Local Secret Storage

Tokens are stored via `SecureKvStore` abstraction:

- **Linux/Windows/Android/iOS** — `flutter_secure_storage` (Keychain/Keystore/Secret Service)
- **macOS** — JSON file in `getApplicationSupportDirectory()` (Keychain requires Apple Developer Team signing; ad-hoc builds fail with `-34018`)
- **Tests** — `SecureKvStore.inMemory()`

## Roadmap

| Stage | Goal | Status |
|---|---|---|
| C1 | Desktop shell, onboarding, handoff, subscription view | ✅ |
| C1.1 | Consumer account auth (register/login/session) | ✅ |
| C2 | sing-box VPN engine: process supervision, TUN, connect/disconnect | next |
| C3 | macOS VPN path (privileged helper / NetworkExtension) | planned |
| C4 | Polish: traffic stats, reconnect, branding | planned |
| C5 | Android client (VpnService) | planned |
| P0 | Provider Mode shell | planned |
| A1/A2 | App-driven self-host VPS installer | planned |

Out of MVP: multi-protocol UI, marketplace, billing, kill switch, split tunneling.

## License

AGPL-3.0-only
