import 'package:core_protocol/core_protocol.dart';
import 'package:device_security/device_security.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_app/core/models/mobile_connection_state.dart';
import 'package:mobile_app/core/providers/app_providers.dart';
import 'package:mobile_app/core/services/mobile_connection_service.dart';
import 'package:mobile_app/core/services/support_services.dart';
import 'package:mobile_app/features/connect/presentation/connect_page.dart';
import 'package:mobile_app/features/trusted_devices/application/trusted_devices_controller.dart';

void main() {
  testWidgets('connect screen renders trusted section', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          mobileConnectionStateProvider.overrideWith(
            (Ref ref) => Stream<MobileConnectionState>.value(
              MobileConnectionState.initial().copyWith(
                status: AppConnectionStatus.idle,
              ),
            ),
          ),
          trustedDevicesControllerProvider.overrideWith(
            (Ref ref) => TrustedDevicesController(_FakeTrustRegistry()),
          ),
          mobileConnectionServiceProvider.overrideWithValue(
            _ThrowingConnectionService(),
          ),
        ],
        child: const MaterialApp(home: ConnectPage()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Connection Status'), findsOneWidget);
    expect(find.text('Trusted PCs'), findsAtLeastNWidgets(1));
  });
}

class _ThrowingConnectionService extends MobileConnectionService {
  _ThrowingConnectionService()
      : super(
          settingsRepository: _FakeSettingsRepository(),
          historyRepository: _FakeHistoryRepository(),
          trustRegistry: _FakeTrustRegistry(),
          authVault: _FakeVault(),
          telemetrySink: _FakeTelemetry(),
        );
}

class _FakeSettingsRepository implements ISettingsRepository {
  @override
  Future<AppSettings> read() async => AppSettings.defaults();

  @override
  Future<void> write(AppSettings settings) async {}
}

class _FakeHistoryRepository implements ITransferHistoryRepository {
  @override
  Future<void> add(TransferResult result) async {}

  @override
  Future<List<TransferResult>> readAll() async => const <TransferResult>[];

  @override
  Stream<List<TransferResult>> watchHistory() => Stream.value(const <TransferResult>[]);
}

class _FakeTrustRegistry implements ITrustRegistry {
  @override
  Future<void> delete(String trustedDeviceId) async {}

  @override
  Future<List<TrustedDevice>> getAll() async => const <TrustedDevice>[];

  @override
  Future<TrustedDevice?> getByTrustedDeviceId(String trustedDeviceId) async => null;

  @override
  Future<void> revoke(String trustedDeviceId) async {}

  @override
  Future<void> upsert(TrustedDevice device) async {}
}

class _FakeVault extends TrustedSecretVault {
  _FakeVault() : super(_FakeSecureStorage());
}

class _FakeSecureStorage implements SecureStorageAdapter {
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

class _FakeTelemetry implements ITelemetrySink {
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
