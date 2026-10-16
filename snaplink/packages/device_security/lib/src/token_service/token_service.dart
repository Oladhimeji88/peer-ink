import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class TokenService {
  TokenService({Random? random}) : _random = random ?? Random.secure();

  final Random _random;

  String generateOpaqueToken({int length = 32}) {
    const alphabet =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List<String>.generate(
      length,
      (_) => alphabet[_random.nextInt(alphabet.length)],
    ).join();
  }

  String sha256Of(String value) =>
      sha256.convert(utf8.encode(value)).toString();

  String generateHmac({
    required String secret,
    required List<String> parts,
  }) {
    final message = parts.join('|');
    final hmac = Hmac(sha256, utf8.encode(secret));
    return hmac.convert(utf8.encode(message)).toString();
  }

  bool constantTimeEquals(String a, String b) {
    if (a.length != b.length) {
      return false;
    }
    var mismatch = 0;
    for (var index = 0; index < a.length; index++) {
      mismatch |= a.codeUnitAt(index) ^ b.codeUnitAt(index);
    }
    return mismatch == 0;
  }
}

class ReplayGuard {
  ReplayGuard({this.maxEntries = 2048});

  final int maxEntries;
  final List<String> _messageIds = <String>[];

  bool register(String messageId) {
    if (_messageIds.contains(messageId)) {
      return false;
    }
    _messageIds.add(messageId);
    if (_messageIds.length > maxEntries) {
      _messageIds.removeAt(0);
    }
    return true;
  }
}

