import 'dart:async';
import 'dart:convert';

import 'package:core_protocol/core_protocol.dart';
import 'package:device_security/device_security.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DesktopSettingsRepository implements ISettingsRepository {
  DesktopSettingsRepository(this._preferences);

  final SharedPreferences _preferences;
  static const String _key = 'desktop.app_settings';

  @override
  Future<AppSettings> read() async {
    final payload = _preferences.getString(_key);
    if (payload == null) {
      return AppSettings.defaults();
    }
    return AppSettings.fromJson(jsonDecode(payload) as Map<String, dynamic>);
  }

  @override
  Future<void> write(AppSettings settings) async {
    await _preferences.setString(_key, jsonEncode(settings.toJson()));
  }
}

class DesktopTransferHistoryRepository
    implements ITransferHistoryRepository, IGalleryRepository {
  DesktopTransferHistoryRepository(this._preferences);

  final SharedPreferences _preferences;
  final StreamController<List<TransferResult>> _controller =
      StreamController<List<TransferResult>>.broadcast();
  static const String _key = 'desktop.transfer_history';

  @override
  Future<void> add(TransferResult result) async {
    final records = await readAll();
    final updated = <TransferResult>[result, ...records].take(250).toList();
    await _preferences.setString(
      _key,
      jsonEncode(updated.map((item) => item.toJson()).toList()),
    );
    _controller.add(updated);
  }

  @override
  Future<List<TransferResult>> readAll() async {
    final payload = _preferences.getString(_key);
    if (payload == null) {
      return const <TransferResult>[];
    }
    final decoded = jsonDecode(payload) as List<dynamic>;
    return decoded
        .map((item) => TransferResult.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Stream<List<TransferResult>> watchHistory() async* {
    yield await readAll();
    yield* _controller.stream;
  }

  @override
  Stream<List<TransferResult>> watchRecentPhotos() => watchHistory();
}

class DesktopLogRepository implements ILogRepository {
  DesktopLogRepository(this._preferences);

  final SharedPreferences _preferences;
  final StreamController<List<ReceiveLogEntry>> _controller =
      StreamController<List<ReceiveLogEntry>>.broadcast();
  static const String _key = 'desktop.receive_logs';

  @override
  Future<void> append(ReceiveLogEntry entry) async {
    final items = await _readAll();
    final updated = <ReceiveLogEntry>[entry, ...items].take(500).toList();
    await _preferences.setString(
      _key,
      jsonEncode(updated.map((item) => item.toJson()).toList()),
    );
    _controller.add(updated);
  }

  Future<List<ReceiveLogEntry>> _readAll() async {
    final payload = _preferences.getString(_key);
    if (payload == null) {
      return const <ReceiveLogEntry>[];
    }
    final decoded = jsonDecode(payload) as List<dynamic>;
    return decoded
        .map((item) => ReceiveLogEntry.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Stream<List<ReceiveLogEntry>> watchLogs() async* {
    yield await _readAll();
    yield* _controller.stream;
  }
}

class DesktopTrustRegistry implements ITrustRegistry {
  DesktopTrustRegistry(this._preferences);

  final SharedPreferences _preferences;
  static const String _key = 'desktop.trusted_devices';

  @override
  Future<void> delete(String trustedDeviceId) async {
    final items = await getAll();
    final updated =
        items.where((item) => item.trustedDeviceId != trustedDeviceId).toList();
    await _persist(updated);
  }

  @override
  Future<List<TrustedDevice>> getAll() async {
    final payload = _preferences.getString(_key);
    if (payload == null) {
      return const <TrustedDevice>[];
    }
    final decoded = jsonDecode(payload) as List<dynamic>;
    return decoded
        .map((item) => TrustedDevice.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<TrustedDevice?> getByTrustedDeviceId(String trustedDeviceId) async {
    final items = await getAll();
    for (final item in items) {
      if (item.trustedDeviceId == trustedDeviceId) {
        return item;
      }
    }
    return null;
  }

  @override
  Future<void> revoke(String trustedDeviceId) async {
    final items = await getAll();
    final updated = items
        .map(
          (item) => item.trustedDeviceId == trustedDeviceId
              ? item.copyWith(revoked: true)
              : item,
        )
        .toList();
    await _persist(updated);
  }

  @override
  Future<void> upsert(TrustedDevice device) async {
    final items = await getAll();
    final existingIndex = items.indexWhere(
      (item) => item.trustedDeviceId == device.trustedDeviceId,
    );
    if (existingIndex == -1) {
      items.add(device);
    } else {
      items[existingIndex] = device;
    }
    await _persist(items);
  }

  Future<void> _persist(List<TrustedDevice> devices) async {
    await _preferences.setString(
      _key,
      jsonEncode(devices.map((item) => item.toJson()).toList()),
    );
  }
}

