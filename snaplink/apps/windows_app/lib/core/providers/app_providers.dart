import 'package:core_protocol/core_protocol.dart';
import 'package:device_security/device_security.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/pairing/application/pairing_controller.dart';
import '../../features/settings/application/settings_controller.dart';
import '../../features/trusted_devices/application/trusted_devices_controller.dart';
import '../models/desktop_listener_state.dart';
import '../services/desktop_listener_service.dart';
import '../services/support_services.dart';

final settingsRepositoryProvider = Provider<ISettingsRepository>((ref) {
  throw UnimplementedError();
});

final transferHistoryRepositoryProvider = Provider<ITransferHistoryRepository>((ref) {
  throw UnimplementedError();
});

final galleryRepositoryProvider = Provider<IGalleryRepository>((ref) {
  throw UnimplementedError();
});

final logRepositoryProvider = Provider<ILogRepository>((ref) {
  throw UnimplementedError();
});

final trustRegistryProvider = Provider<ITrustRegistry>((ref) {
  throw UnimplementedError();
});

final telemetrySinkProvider = Provider<ITelemetrySink>((ref) {
  throw UnimplementedError();
});

final trustedSecretVaultProvider = Provider<TrustedSecretVault>((ref) {
  throw UnimplementedError();
});

final desktopListenerServiceProvider = Provider<DesktopListenerService>((ref) {
  throw UnimplementedError();
});

final desktopListenerStateProvider = StreamProvider<DesktopListenerState>((ref) {
  return ref.watch(desktopListenerServiceProvider).watchState();
});

final galleryDataProvider = StreamProvider<List<TransferResult>>((ref) {
  return ref.watch(galleryRepositoryProvider).watchRecentPhotos();
});

final logsProvider = StreamProvider<List<ReceiveLogEntry>>((ref) {
  return ref.watch(logRepositoryProvider).watchLogs();
});

final connectionManagerProvider = Provider<IConnectionManager>((ref) {
  return ref.watch(desktopListenerServiceProvider);
});

final serverStatusProvider = Provider<String>((ref) {
  final listenerState = ref.watch(desktopListenerStateProvider).valueOrNull;
  return listenerState?.status.name ?? 'booting';
});

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, AsyncValue<AppSettings>>((ref) {
  return SettingsController(ref.watch(settingsRepositoryProvider));
});

final pairingControllerProvider = Provider<PairingController>((ref) {
  return PairingController(ref.watch(desktopListenerServiceProvider));
});

final trustedDevicesControllerProvider = StateNotifierProvider<
    TrustedDevicesController, AsyncValue<List<TrustedDevice>>>((ref) {
  return TrustedDevicesController(ref.watch(trustRegistryProvider));
});

