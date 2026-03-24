import 'dart:convert';

import '../models/connection_models.dart';

class QrPayloadCodec {
  const QrPayloadCodec();

  String encode(PairingQrPayload payload) {
    final jsonString = jsonEncode(payload.toJson());
    return base64UrlEncode(utf8.encode(jsonString));
  }

  PairingQrPayload decode(String encodedPayload) {
    final jsonString = utf8.decode(base64Url.decode(encodedPayload));
    final Map<String, dynamic> json = jsonDecode(jsonString) as Map<String, dynamic>;
    return PairingQrPayload.fromJson(json);
  }
}

