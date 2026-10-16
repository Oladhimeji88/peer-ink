import 'package:core_protocol/core_protocol.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsController extends StateNotifier<AsyncValue<AppSettings>> {
  SettingsController(this._repository) : super(const AsyncValue.loading()) {
    _load();
  }

  final ISettingsRepository _repository;

  Future<void> _load() async {
    state = AsyncValue.data(await _repository.read());
  }

  Future<void> save(AppSettings settings) async {
    state = AsyncValue.data(settings);
    await _repository.write(settings);
  }
}

