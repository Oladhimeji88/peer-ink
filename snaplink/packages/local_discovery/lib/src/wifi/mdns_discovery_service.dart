import 'dart:async';

import 'package:core_protocol/core_protocol.dart';
import 'package:multicast_dns/multicast_dns.dart';

import '../abstractions/discovery_service.dart';

class MdnsDiscoveryService implements IDiscoveryService {
  MdnsDiscoveryService({
    MDnsClient? client,
    LastKnownEndpointCache? fallbackCache,
  })  : _client = client ?? MDnsClient(),
        _fallbackCache = fallbackCache ?? const LastKnownEndpointCache();

  final MDnsClient _client;
  final LastKnownEndpointCache _fallbackCache;
  final StreamController<List<DiscoveryCandidate>> _controller =
      StreamController<List<DiscoveryCandidate>>.broadcast();

  @override
  Future<DiscoveryCandidate?> resolveTrustedDevice(TrustedDevice trustedDevice) async {
    try {
      await _client.start();
      await for (final PtrResourceRecord ptr
          in _client.lookup<PtrResourceRecord>(
        ResourceRecordQuery.serverPointer('_snaplink._tcp.local'),
      )) {
        if (!ptr.domainName.contains(trustedDevice.desktopDeviceId)) {
          continue;
        }
        final candidate = DiscoveryCandidate(
          trustedDeviceId: trustedDevice.trustedDeviceId,
          host: trustedDevice.lastKnownHost,
          port: trustedDevice.lastKnownPort,
          desktopName: trustedDevice.deviceName,
          certificateSha256: trustedDevice.certificateSha256,
          capabilities: const <String, bool>{'mdns': true},
        );
        return candidate;
      }
    } catch (_) {
      return _fallbackCache.fromTrustedDevice(trustedDevice);
    } finally {
      _client.stop();
    }

    return _fallbackCache.fromTrustedDevice(trustedDevice);
  }

  @override
  Future<void> startBrowsing() async {
    await _client.start();
    _controller.add(const <DiscoveryCandidate>[]);
  }

  @override
  Future<void> stopBrowsing() async {
    _client.stop();
  }

  @override
  Stream<List<DiscoveryCandidate>> watchCandidates() => _controller.stream;
}
