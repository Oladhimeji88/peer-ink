import 'package:windows_app/core/services/desktop_listener_service.dart';

class PairingController {
  PairingController(this._listenerService);

  final DesktopListenerService _listenerService;

  Future<void> regenerateQr() => _listenerService.regeneratePairingSession();

  Future<void> disconnectCurrent() => _listenerService.disconnect();
}

