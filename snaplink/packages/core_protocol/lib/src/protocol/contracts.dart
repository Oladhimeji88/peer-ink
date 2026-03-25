import 'package:core_protocol/src/models/app_models.dart';
import 'package:core_protocol/src/models/connection_models.dart';
import 'package:core_protocol/src/models/transfer_models.dart';
import 'package:core_protocol/src/enums/protocol_enums.dart';

abstract class ITransportProvider {
  Future<void> start();
  Future<void> stop();
  bool get isRunning;
}

abstract class IConnectionManager {
  Stream<ActiveConnection?> watchActiveConnection();
  Stream<ConnectionHealthState> watchHealth();
  Future<void> connectToTrustedDevice(TrustedDevice device);
  Future<void> disconnect({String? reason});
  Future<void> sendHeartbeat();
}

abstract class ITransferEngine {
  Stream<List<TransferJob>> watchQueue();
  Stream<TransferProgress> watchProgress();
  Future<void> enqueue(TransferJob job);
  Future<void> retry(String jobId);
  Future<void> cancel(String jobId);
}

abstract class IDiscoveryService {
  Stream<List<DiscoveryCandidate>> watchCandidates();
  Future<void> startBrowsing();
  Future<void> stopBrowsing();
  Future<DiscoveryCandidate?> resolveTrustedDevice(TrustedDevice trustedDevice);
}

abstract class ISettingsRepository {
  Future<AppSettings> read();
  Future<void> write(AppSettings settings);
}

abstract class ITransferHistoryRepository {
  Stream<List<TransferResult>> watchHistory();
  Future<List<TransferResult>> readAll();
  Future<void> add(TransferResult result);
}

abstract class IGalleryRepository {
  Stream<List<TransferResult>> watchRecentPhotos();
}

abstract class ILogRepository {
  Stream<List<ReceiveLogEntry>> watchLogs();
  Future<void> append(ReceiveLogEntry entry);
}

abstract class ITelemetrySink {
  Future<void> recordEvent(
    String name, {
    Map<String, Object?> properties = const <String, Object?>{},
  });

  Future<void> recordError(
    Object error, {
    StackTrace? stackTrace,
    Map<String, Object?> context = const <String, Object?>{},
  });
}

class DiscoveryCandidate {
  const DiscoveryCandidate({
    required this.trustedDeviceId,
    required this.host,
    required this.port,
    required this.desktopName,
    required this.certificateSha256,
    this.rssi,
    this.capabilities = const <String, bool>{},
  });

  final String trustedDeviceId;
  final String host;
  final int port;
  final String desktopName;
  final String certificateSha256;
  final int? rssi;
  final Map<String, bool> capabilities;
}
