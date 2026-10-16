import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

class ChecksumService {
  const ChecksumService();

  Future<String> hashFile(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }

  String hashBytes(List<int> bytes) =>
      sha256.convert(bytes).toString();

  String hashString(String value) =>
      sha256.convert(utf8.encode(value)).toString();
}

