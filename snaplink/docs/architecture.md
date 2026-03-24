# SNAPLINK Architecture

## Monorepo Shape

- `apps/windows_app`: desktop UI, local listener lifecycle, receive pipeline orchestration, gallery, logs, settings, trusted-device management.
- `apps/mobile_app`: onboarding, connect flow, QR scan, trusted reconnect, in-app camera capture, transfer queue, transfer history, and device settings.
- `packages/core_protocol`: immutable protocol and domain DTOs, QR codec, validators, shared enums, and repository or service contracts.
- `packages/device_security`: secure storage adapter, trust registry contracts, token generation, replay protection, and certificate pinning helpers.
- `packages/transfer_engine`: queue controller, checksuming, upload client, and receive pipeline finalization helpers.
- `packages/local_discovery`: trusted reconnect discovery abstraction with mDNS-first and fallback resolution.
- `packages/shared_ui`: shared theme, desktop shell, cards, and status badges.

## Layering

- Presentation: Flutter widgets, route shells, visual state.
- Application: Riverpod controllers and feature orchestration.
- Domain: shared models and use-case contracts.
- Data: repository implementations backed by local persistence.
- Infrastructure: local server sockets, file IO, secure storage, camera plugin, discovery adapters.

## Desktop Responsibilities

- Start and stop the local listener at app bootstrap.
- Generate one-time pairing sessions and encode them into the QR payload.
- Validate pairing requests, reject expired or reused sessions, and persist trusted-device state.
- Maintain one active upload connection in v1 while allowing many remembered trusted devices over time.
- Receive upload initialization over WebSocket, stream bytes over HTTP, validate checksum, sanitize filenames, dedupe by checksum, and move files into the configured save folder.
- Publish desktop UI state for dashboard, pairing, gallery, logs, settings, and trusted devices.

## Mobile Responsibilities

- Guide the user from onboarding to connection and capture.
- Scan and parse QR payloads, pair to a desktop listener, and persist trusted secrets locally.
- Reconnect to trusted desktops using discovery and last-known endpoint fallback.
- Keep camera initialization isolated from transport state.
- Capture still images, compute checksum, enqueue transfer jobs, upload immediately when connected, and record transfer history.

## Persistence Strategy

- Sensitive state: trusted secrets live behind `flutter_secure_storage` via `TrustedSecretVault`.
- Non-sensitive state: settings, logs, transfer history, and trusted device metadata are abstracted behind repositories. The current scaffold uses local preference-backed repositories so the repo stays runnable before code generation; the package boundaries are prepared for Isar-backed adapters as the next persistence swap.

## Transport Notes

- Current runtime scaffold uses a desktop-hosted WebSocket endpoint for signaling and a desktop-hosted HTTP endpoint for upload bytes.
- Protocol messages, token validation, replay protection, and checksum validation are already in the shared layer.
- The QR payload includes the certificate fingerprint field and the codebase keeps the certificate-pinning utilities isolated, so moving the desktop listener from local HTTP/WS to pinned HTTPS/WSS is a contained infrastructure change rather than an application rewrite.

