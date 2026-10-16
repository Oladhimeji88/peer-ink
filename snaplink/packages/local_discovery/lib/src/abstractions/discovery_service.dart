import 'package:core_protocol/core_protocol.dart';

abstract class DiscoverySignalPublisher {
  Future<void> publish({
    required String serviceName,
    required int port,
    required Map<String, String> txtRecords,
  });

  Future<void> stop();
}

class LastKnownEndpointCache {
  const LastKnownEndpointCache();

  DiscoveryCandidate fromTrustedDevice(TrustedDevice trustedDevice) {
    return DiscoveryCandidate(
      trustedDeviceId: trustedDevice.trustedDeviceId,
      host: trustedDevice.lastKnownHost,
      port: trustedDevice.lastKnownPort,
      desktopName: trustedDevice.deviceName,
      certificateSha256: trustedDevice.certificateSha256,
    );
  }
}

