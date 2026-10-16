# SNAPLINK Test Plan

## Shared Packages

- `core_protocol`
  - QR payload encoding and decoding.
  - Protocol version and expiry validation.
  - Pairing session reuse rejection.
- `device_security`
  - Deterministic HMAC generation.
  - Replay guard duplicate detection.
- `transfer_engine`
  - Queue enqueue and retry behavior.
  - Checksum and receive pipeline finalization.
  - Filename sanitization and duplicate handling.

## Widget Smoke Tests

- Windows dashboard renders connection and receive sections.
- Mobile connect screen renders connection status and trusted section.

## Integration Coverage

- Pairing and upload integration spins up a real desktop listener with in-memory secrets and preference-backed repos.
- Mobile service scans the live QR payload, pairs, uploads a temp image, and verifies the desktop history repository records the receive.

## Manual Device Matrix

- Windows desktop app receives images from Android over the same Wi-Fi.
- Windows desktop app receives images from iOS over the same Wi-Fi.
- QR expiry, rejection, and regeneration behavior.
- Trusted reconnect after closing and reopening the mobile app.
- Disconnect and revoke flows.
- Permission denial for camera and local network access.

