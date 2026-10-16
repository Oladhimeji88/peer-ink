import 'package:core_protocol/core_protocol.dart';
import 'package:test/test.dart';

void main() {
  group('QrPayloadCodec', () {
    test('round trips a payload', () {
      const codec = QrPayloadCodec();
      final payload = PairingQrPayload(
        protocolVersion: 1,
        sessionId: 'session-1',
        oneTimePairingToken: 'token-1',
        desktopDeviceId: 'desktop-1',
        desktopName: 'Studio PC',
        localIp: '192.168.1.10',
        port: 42817,
        expiresAt: DateTime.utc(2026, 1, 1, 12),
        tlsCertSha256: 'abc123',
        capabilityFlags: const <String, bool>{'wifi_local': true},
      );

      final encoded = codec.encode(payload);
      final decoded = codec.decode(encoded);

      expect(decoded.sessionId, payload.sessionId);
      expect(decoded.desktopName, payload.desktopName);
      expect(decoded.capabilityFlags['wifi_local'], isTrue);
    });
  });
}

