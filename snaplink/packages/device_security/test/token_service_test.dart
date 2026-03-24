import 'package:device_security/device_security.dart';
import 'package:test/test.dart';

void main() {
  group('TokenService', () {
    final service = TokenService();

    test('creates deterministic HMAC values', () {
      final signatureA = service.generateHmac(
        secret: 'secret',
        parts: const <String>['a', 'b', 'c'],
      );
      final signatureB = service.generateHmac(
        secret: 'secret',
        parts: const <String>['a', 'b', 'c'],
      );

      expect(signatureA, signatureB);
    });

    test('replay guard rejects duplicates', () {
      final guard = ReplayGuard();
      expect(guard.register('message-1'), isTrue);
      expect(guard.register('message-1'), isFalse);
    });
  });
}

