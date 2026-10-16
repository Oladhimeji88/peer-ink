import 'dart:convert';

import 'package:crypto/crypto.dart';

class CertificatePinning {
  const CertificatePinning();

  String fingerprintPem(String pem) => sha256.convert(utf8.encode(pem)).toString();

  bool matches({
    required String expectedSha256,
    required String pem,
  }) {
    return fingerprintPem(pem) == expectedSha256;
  }
}

