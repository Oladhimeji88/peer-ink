import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:core_protocol/core_protocol.dart';
import 'package:http/http.dart' as http;

class TransferUploadClient {
  TransferUploadClient({
    http.Client? client,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  Future<UploadAck> upload({
    required UploadInitResponse init,
    required File file,
    required String authToken,
    required void Function(int sent, int total) onProgress,
  }) async {
    final request = http.Request('PUT', init.uploadUrl)
      ..headers['authorization'] = 'Bearer $authToken'
      ..headers['content-type'] = 'application/octet-stream'
      ..bodyBytes = await file.readAsBytes();

    onProgress(request.bodyBytes.length, request.bodyBytes.length);

    final streamed = await _client.send(request);
    final body = await streamed.stream.bytesToString();
    final Map<String, dynamic> json = jsonDecode(body) as Map<String, dynamic>;
    return UploadAck.fromJson(json);
  }

  void dispose() {
    _client.close();
  }
}

