# SNAPLINK

SNAPLINK is a local-first photo bridge between a phone and a Windows PC. The desktop app hosts a secure local listener, exposes a QR pairing session, and receives photos instantly from the mobile app over the local network. The mobile app scans, trusts, reconnects, captures, uploads, and tracks delivery state without requiring cloud infrastructure.

## Stack

- Flutter + Dart
- Riverpod + GoRouter + Flutter Hooks
- Freezed + json_serializable
- Isar for non-sensitive local persistence
- flutter_secure_storage for secrets
- WebSocket signaling + HTTPS upload
- Melos monorepo

## Workspace Layout

```text
snaplink/
  apps/
    windows_app/
    mobile_app/
  packages/
    core_protocol/
    transfer_engine/
    device_security/
    local_discovery/
    shared_ui/
  docs/
```

## Architecture Summary

- `core_protocol` owns protocol DTOs, validators, QR encoding, and shared enums.
- `device_security` owns trust storage, anti-replay protection, HMAC helpers, and certificate pinning utilities.
- `transfer_engine` owns queueing, retry state, checksuming, and receive pipeline helpers.
- `local_discovery` abstracts trusted reconnect discovery with mDNS-first and last-known-endpoint fallback.
- `shared_ui` provides the shared visual language, desktop shell, and reusable widgets.
- `windows_app` hosts the secure local listener, pairing state, gallery, logs, settings, and trusted device management.
- `mobile_app` owns onboarding, discovery, scan, connection, camera capture, queueing, history, and retry UX.

## Setup

1. Install Flutter stable with Windows desktop, Android, and iOS support.
2. Install Dart, Melos, and platform toolchains:
   - `dart pub global activate melos`
   - Android Studio / Xcode as appropriate
3. From `snaplink/`, run:
   - `melos bootstrap`
   - `melos run codegen`

## Run

```bash
# Windows desktop
flutter run -d windows -t apps/windows_app/lib/main.dart

# Mobile
flutter run -t apps/mobile_app/lib/main.dart
```

## Quality Gates

```bash
melos run analyze
melos run test
melos run integration_test
```

## Build

```bash
# Windows
flutter build windows --target=apps/windows_app/lib/main.dart

# Android
flutter build apk --target=apps/mobile_app/lib/main.dart
flutter build appbundle --target=apps/mobile_app/lib/main.dart

# iOS (macOS only)
flutter build ios --target=apps/mobile_app/lib/main.dart
```

## Environment Notes

- The desktop app generates or loads a local TLS certificate and shares the fingerprint through the QR payload for certificate pinning.
- Secrets are stored only in secure storage.
- Non-sensitive transfer history, logs, settings, and trusted device metadata are persisted via Isar-backed repositories.
- No internet or external backend is required for pairing or transfer.

## Release Readiness

See:

- `docs/architecture.md`
- `docs/protocol-spec.md`
- `docs/test-plan.md`
- `docs/release-checklist.md`

