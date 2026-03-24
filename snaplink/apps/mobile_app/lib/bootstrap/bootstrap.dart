import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/mobile_app.dart';
import '../core/providers/app_providers.dart';
import '../core/repositories/preferences_repositories.dart';
import '../core/services/camera_capture_service.dart';
import '../core/services/mobile_connection_service.dart';
import '../core/services/support_services.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  final preferences = await SharedPreferences.getInstance();
  final settingsRepository = MobileSettingsRepository(preferences);
  final historyRepository = MobileTransferHistoryRepository(preferences);
  final trustRegistry = MobileTrustRegistry(preferences);
  final secureStorage = FlutterSecureStorageAdapter();
  final authVault = TrustedSecretVault(secureStorage);
  final telemetry = NoopTelemetrySink();
  final connectionService = MobileConnectionService(
    settingsRepository: settingsRepository,
    historyRepository: historyRepository,
    trustRegistry: trustRegistry,
    authVault: authVault,
    telemetrySink: telemetry,
  );
  final cameraService = CameraCaptureService();

  runApp(
    ProviderScope(
      overrides: <Override>[
        settingsRepositoryProvider.overrideWithValue(settingsRepository),
        transferHistoryRepositoryProvider.overrideWithValue(historyRepository),
        trustRegistryProvider.overrideWithValue(trustRegistry),
        trustedSecretVaultProvider.overrideWithValue(authVault),
        telemetrySinkProvider.overrideWithValue(telemetry),
        mobileConnectionServiceProvider.overrideWithValue(connectionService),
        cameraCaptureServiceProvider.overrideWithValue(cameraService),
      ],
      child: const SnaplinkMobileApp(),
    ),
  );
}

