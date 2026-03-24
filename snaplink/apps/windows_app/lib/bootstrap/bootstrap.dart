import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import '../app/windows_app.dart';
import '../core/providers/app_providers.dart';
import '../core/repositories/preferences_repositories.dart';
import '../core/services/desktop_listener_service.dart';
import '../core/services/support_services.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  final preferences = await SharedPreferences.getInstance();
  final supportDirectory = await getApplicationSupportDirectory();
  final settingsRepository = DesktopSettingsRepository(preferences);
  final historyRepository = DesktopTransferHistoryRepository(preferences);
  final logRepository = DesktopLogRepository(preferences);
  final trustRegistry = DesktopTrustRegistry(preferences);
  final secureStorage = FlutterSecureStorageAdapter();
  final authVault = TrustedSecretVault(secureStorage);
  final telemetry = NoopTelemetrySink();
  final listenerService = DesktopListenerService(
    settingsRepository: settingsRepository,
    historyRepository: historyRepository,
    logRepository: logRepository,
    trustRegistry: trustRegistry,
    authVault: authVault,
    telemetrySink: telemetry,
    supportDirectoryPath: supportDirectory.path,
  );

  await listenerService.start();

  await windowManager.waitUntilReadyToShow(
    const WindowOptions(
      size: Size(1440, 900),
      minimumSize: Size(1200, 760),
      center: true,
      title: 'SNAPLINK',
      backgroundColor: Colors.transparent,
    ),
    () async {
      await windowManager.show();
      await windowManager.focus();
    },
  );

  runApp(
    ProviderScope(
      overrides: <Override>[
        settingsRepositoryProvider.overrideWithValue(settingsRepository),
        transferHistoryRepositoryProvider.overrideWithValue(historyRepository),
        galleryRepositoryProvider.overrideWithValue(historyRepository),
        logRepositoryProvider.overrideWithValue(logRepository),
        trustRegistryProvider.overrideWithValue(trustRegistry),
        trustedSecretVaultProvider.overrideWithValue(authVault),
        telemetrySinkProvider.overrideWithValue(telemetry),
        desktopListenerServiceProvider.overrideWithValue(listenerService),
      ],
      child: const SnaplinkDesktopApp(),
    ),
  );
}

