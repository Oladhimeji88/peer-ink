# SNAPLINK Protocol Spec

## Pairing QR Payload

The QR encodes base64url JSON with these fields:

- `protocol_version`
- `session_id`
- `one_time_pairing_token`
- `desktop_device_id`
- `desktop_name`
- `local_ip`
- `port`
- `expires_at`
- `tls_cert_sha256`
- `capability_flags`

Desktop sessions are single-use and expire after 60 seconds.

## Message Envelope

Every signaling message is wrapped as:

- `message_id`
- `type`
- `protocol_version`
- `timestamp`
- `payload`

## Message Types

- `hello`
- `pair_request`
- `pair_response`
- `auth_challenge`
- `auth_success`
- `heartbeat`
- `heartbeat_ack`
- `upload_init`
- `upload_ready`
- `upload_ack`
- `upload_error`
- `disconnect`

## Pairing Flow

1. Desktop starts the listener and generates a fresh pairing session.
2. Desktop renders the QR payload.
3. Mobile scans the QR, validates protocol version and expiry, and opens the local signaling socket.
4. Mobile sends `pair_request` with session id, one-time token, device identity, client nonce, and capability flags.
5. Desktop validates session existence, expiry, and single-use status.
6. Desktop persists a new trusted device record and secret, returns `pair_response`, and marks the session used.
7. Both sides persist trust state for reconnect.

## Trusted Reconnect Flow

1. Mobile resolves the desktop endpoint using discovery and fallback host or port.
2. Mobile opens the signaling socket and sends `hello` with trusted-device id and device info.
3. Desktop responds with `auth_challenge` containing a server nonce.
4. Mobile signs the challenge using the trusted secret and returns `auth_success`.
5. Desktop validates the HMAC and acknowledges with `auth_success`.

## Upload Flow

1. Mobile captures a photo, computes the SHA-256 checksum, and creates a `TransferJob`.
2. Mobile sends `upload_init` over the signaling channel with metadata.
3. Desktop validates the authenticated session, max size, and duplicate checksum rules.
4. Desktop returns `upload_ready` with an `uploadId` and the local upload URL.
5. Mobile streams raw bytes to `PUT /api/uploads/{uploadId}` with the trusted bearer secret.
6. Desktop writes a temp file, validates checksum, sanitizes filename, deduplicates, and moves the final file atomically.
7. Desktop returns `upload_ack` on success or `upload_error` on failure.

## Security Controls

- One-time pairing tokens.
- Short pairing expiry.
- Replay rejection via message id tracking.
- Trusted-secret storage in secure storage.
- Reconnect HMAC challenge verification.
- Checksum validation before file finalization.
- Filename sanitization and bounded save directory handling.
- Revocation via trusted-device repository state.

