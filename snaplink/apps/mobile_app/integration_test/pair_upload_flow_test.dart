import 'dart:async';
import 'dart:io';

import 'package:core_protocol/core_protocol.dart';
import 'package:device_security/device_security.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile_app/core/repositories/preferences_repositories.dart';
import 'package:mobile_app/core/services/mobile_connection_service.dart';
import 'package:mobile_app/core/services/support_services.dart' as mobile_support;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transfer_engine/transfer_engine.dart';
import 'package:windows_app/core/repositories/preferences_repositories.dart';
import 'package:windows_app/core/services/desktop_listener_service.dart';
import 'package:windows_app/core/services/support_services.dart' as desktop_support;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('pair then upload succeeds', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final desktopPreferences = await SharedPreferences.getInstance();
    final mobilePreferences = await SharedPreferences.getInstance();
    final tempDirectory = await Directory.systemTemp.createTemp('snaplink_e2e');

    final desktopSettings = DesktopSettingsRepository(desktopPreferences);
    await desktopSettings.write(
      AppSettings.defaults().copyWith(
        saveDirectory: '${tempDirectory.path}/received',
        listenerPort: 43117,
      ),
    );
    final desktopHistory = DesktopTransferHistoryRepository(desktopPreferences);
    final desktopLogs = DesktopLogRepository(desktopPreferences);
    final desktopTrust = DesktopTrustRegistry(desktopPreferences);
    final desktopVault = desktop_support.TrustedSecretVault(_MemorySecureStorage());
    final desktopService = DesktopListenerService(
      settingsRepository: desktopSettings,
      historyRepository: desktopHistory,
      logRepository: desktopLogs,
      trustRegistry: desktopTrust,
      authVault: desktopVault,
      telemetrySink: _NoopTelemetry(),
      supportDirectoryPath: tempDirectory.path,
    );
    await desktopService.start();

    final mobileSettings = MobileSettingsRepository(mobilePreferences);
    final mobileHistory = MobileTransferHistoryRepository(mobilePreferences);
    final mobileTrust = MobileTrustRegistry(mobilePreferences);
    final mobileVault = mobile_support.TrustedSecretVault(_MemorySecureStorage());
    final mobileService = MobileConnectionService(
      settingsRepository: mobileSettings,
      historyRepository: mobileHistory,
      trustRegistry: mobileTrust,
      authVault: mobileVault,
      telemetrySink: _NoopTelemetry(),
    );

    final qrPayload = const QrPayloadCodec().encode(desktopService.currentQrPayload!);
    await mobileService.pairFromQr(qrPayload);

    final outgoingFile = File('${tempDirectory.path}/outgoing.jpg')
      ..writeAsStringSync('photo-bytes');
    final job = TransferJob(
      jobId: 'job-1',
      photo: PhotoMetadata(
        sourceFilePath: outgoingFile.path,
        originalFilename: 'outgoing.jpg',
        sanitizedFilename: 'outgoing.jpg',
        byteLength: outgoingFile.lengthSync(),
        checksumSha256: const ChecksumService().hashString('photo-bytes'),
        capturedAt: DateTime.now().toUtc(),
        mimeType: 'image/jpeg',
        sourceDeviceId: 'mobile',
      ),
      status: TransferStatus.queued,
      createdAt: DateTime.now().toUtc(),
      attemptCount: 0,
      autoSend: true,
    );

    final result = await mobileService.uploadJob(job);

    expect(result.status, TransferStatus.completed);
    expect((await desktopHistory.readAll()).length, 1);
    await desktopService.stop();
  });
}

class _MemorySecureStorage implements SecureStorageAdapter {
  final Map<String, String> _store = <String, String>{};

  @override
  Future<void> delete(String key) async {
    _store.remove(key);
  }

  @override
  Future<String?> read(String key) async => _store[key];

  @override
  Future<Map<String, String>> readAll() async => _store;

  @override
  Future<void> write({required String key, required String value}) async {
    _store[key] = value;
  }
}

class _NoopTelemetry implements ITelemetrySink {
  @override
  Future<void> recordError(
    Object error, {
    StackTrace? stackTrace,
    Map<String, Object?> context = const <String, Object?>{},
  }) async {}

  @override
  Future<void> recordEvent(
    String name, {
    Map<String, Object?> properties = const <String, Object?>{},
  }) async {}
}
