import '../models/connection_models.dart';
import '../models/protocol_models.dart';

class ProtocolValidationException implements Exception {
  ProtocolValidationException(this.message);

  final String message;

  @override
  String toString() => 'ProtocolValidationException: $message';
}

class ProtocolValidator {
  const ProtocolValidator({
    this.supportedProtocolVersion = 1,
    this.qrLifetime = const Duration(seconds: 60),
  });

  final int supportedProtocolVersion;
  final Duration qrLifetime;

  void validateQrPayload(PairingQrPayload payload, DateTime now) {
    if (payload.protocolVersion != supportedProtocolVersion) {
      throw ProtocolValidationException('Unsupported protocol version.');
    }
    if (payload.expiresAt.isBefore(now)) {
      throw ProtocolValidationException('Pairing QR payload expired.');
    }
  }

  void validateSession(PairingSession session, DateTime now) {
    if (session.used) {
      throw ProtocolValidationException('Pairing session already used.');
    }
    if (session.expiresAt.isBefore(now)) {
      throw ProtocolValidationException('Pairing session expired.');
    }
  }

  void validatePairingRequest(PairingRequest request, PairingSession session) {
    if (request.sessionId != session.sessionId) {
      throw ProtocolValidationException('Unknown pairing session.');
    }
    if (request.oneTimePairingToken != session.oneTimeToken) {
      throw ProtocolValidationException('Invalid pairing token.');
    }
  }

  void validateMessage(ProtocolMessage message) {
    if (message.protocolVersion != supportedProtocolVersion) {
      throw ProtocolValidationException('Unsupported protocol message.');
    }
    if (message.messageId.trim().isEmpty) {
      throw ProtocolValidationException('message_id is required.');
    }
    if (message.type.trim().isEmpty) {
      throw ProtocolValidationException('type is required.');
    }
  }
}

