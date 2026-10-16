import 'package:core_protocol/core_protocol.dart';
import 'package:device_security/device_security.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TrustedDevicesController
    extends StateNotifier<AsyncValue<List<TrustedDevice>>> {
  TrustedDevicesController(this._registry)
      : super(const AsyncValue.loading()) {
    refresh();
  }

  final ITrustRegistry _registry;

  Future<void> refresh() async {
    state = AsyncValue.data(await _registry.getAll());
  }

  Future<void> rename(TrustedDevice device, String nickname) async {
    await _registry.upsert(device.copyWith(nickname: nickname));
    await refresh();
  }

  Future<void> revoke(String trustedDeviceId) async {
    await _registry.revoke(trustedDeviceId);
    await refresh();
  }
}

