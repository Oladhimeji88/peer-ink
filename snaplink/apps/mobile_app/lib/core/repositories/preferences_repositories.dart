import 'dart:async';
import 'dart:convert';

import 'package:core_protocol/core_protocol.dart';
import 'package:device_security/device_security.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MobileSettingsRepository implements ISettingsRepository {
  MobileSettingsRepository(this._preferences);

  final SharedPreferences _preferences;
  static const String _key = 'mobile.app_settings';

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

class MobileTransferHistoryRepository implements ITransferHistoryRepository {
  MobileTransferHistoryRepository(this._preferences);

  final SharedPreferences _preferences;
  final StreamController<List<TransferResult>> _controller =
      StreamController<List<TransferResult>>.broadcast();
  static const String _key = 'mobile.transfer_history';

  @override
  Future<void> add(TransferResult result) async {
    final current = await readAll();
    final updated = <TransferResult>[result, ...current].take(250).toList();
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
}

class MobileTrustRegistry implements ITrustRegistry {
  MobileTrustRegistry(this._preferences);

  final SharedPreferences _preferences;
  static const String _key = 'mobile.trusted_devices';

  @override
  Future<void> delete(String trustedDeviceId) async {
    final all = await getAll();
    await _persist(
      all.where((item) => item.trustedDeviceId != trustedDeviceId).toList(),
    );
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
    final all = await getAll();
    for (final item in all) {
      if (item.trustedDeviceId == trustedDeviceId) {
        return item;
      }
    }
    return null;
  }

  @override
  Future<void> revoke(String trustedDeviceId) async {
    final all = await getAll();
    await _persist(
      all
          .map(
            (item) => item.trustedDeviceId == trustedDeviceId
                ? item.copyWith(revoked: true)
                : item,
          )
          .toList(),
    );
  }

  @override
  Future<void> upsert(TrustedDevice device) async {
    final all = await getAll();
    final index = all.indexWhere((item) => item.trustedDeviceId == device.trustedDeviceId);
    if (index == -1) {
      all.add(device);
    } else {
      all[index] = device;
    }
    await _persist(all);
  }

  Future<void> _persist(List<TrustedDevice> values) async {
    await _preferences.setString(
      _key,
      jsonEncode(values.map((item) => item.toJson()).toList()),
    );
  }
}

