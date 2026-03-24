import 'package:core_protocol/core_protocol.dart';
import 'package:test/test.dart';

void main() {
  group('ProtocolValidator', () {
    const validator = ProtocolValidator();

    test('rejects expired QR payloads', () {
      final payload = PairingQrPayload(
        protocolVersion: 1,
        sessionId: 'session-1',
        oneTimePairingToken: 'token-1',
        desktopDeviceId: 'desktop-1',
        desktopName: 'Studio PC',
        localIp: '192.168.1.10',
        port: 42817,
        expiresAt: DateTime.utc(2020, 1, 1),
        tlsCertSha256: 'abc123',
        capabilityFlags: const <String, bool>{},
      );

      expect(
        () => validator.validateQrPayload(payload, DateTime.utc(2026, 1, 1)),
        throwsA(isA<ProtocolValidationException>()),
      );
    });

    test('rejects reused pairing sessions', () {
      final session = PairingSession(
        sessionId: 'session-1',
        oneTimeToken: 'token',
        expiresAt: DateTime.utc(2026, 1, 1),
        desktopDeviceId: 'desktop-1',
        desktopName: 'Studio PC',
        localIp: '192.168.1.10',
        port: 42817,
        tlsCertSha256: 'abc123',
        used: true,
        capabilityFlags: const <String, bool>{},
      );

      expect(
        () => validator.validateSession(session, DateTime.utc(2025, 12, 31)),
        throwsA(isA<ProtocolValidationException>()),
      );
    });
  });
}

