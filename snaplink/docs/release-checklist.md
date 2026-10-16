# SNAPLINK Release Checklist

## Build And Tooling

- Install Flutter stable, Dart, Melos, and platform toolchains.
- Run `melos bootstrap`.
- Run `melos run codegen`.
- Run `melos run analyze`.
- Run `melos run test`.
- Run `melos run integration_test`.

## Security

- Replace local HTTP and WS listener binding with certificate-backed HTTPS and WSS before production release.
- Provision per-install desktop certificate material and persist its fingerprint.
- Verify trusted secrets only exist in secure storage.
- Re-test revoked-device rejection, pairing expiry, replay rejection, and duplicate checksum handling.

## Desktop Packaging

- Configure Windows app identity, icon, installer branding, and optional tray behavior.
- Verify configured save directory access and notification behavior.
- Verify start-on-launch and listener startup experience.

## Mobile Packaging

- Configure Android application id and signing keystore.
- Configure iOS bundle identifier, signing team, and local-network permission strings.
- Verify camera permission and reconnect flows on real devices.

## Operational Hooks

- Replace the no-op telemetry sink with production analytics and crash reporting adapters.
- Review logs for personally identifiable information before shipping.
- Document rollback and support procedures for corrupted local state or revoked trust.
