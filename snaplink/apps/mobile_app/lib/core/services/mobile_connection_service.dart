import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:core_protocol/core_protocol.dart';
import 'package:device_security/device_security.dart';
import 'package:local_discovery/local_discovery.dart';
import 'package:transfer_engine/transfer_engine.dart';

import 'package:mobile_app/core/models/mobile_connection_state.dart';
import 'package:mobile_app/core/services/support_services.dart';

class MobileConnectionService implements IConnectionManager {
  MobileConnectionService({
    required ISettingsRepository settingsRepository,
    required ITransferHistoryRepository historyRepository,
    required ITrustRegistry trustRegistry,
    required TrustedSecretVault authVault,
    required ITelemetrySink telemetrySink,
    QrPayloadCodec? qrPayloadCodec,
    ProtocolValidator? protocolValidator,
    TokenService? tokenService,
    TransferUploadClient? uploadClient,
    IDiscoveryService? discoveryService,
  })  : _settingsRepository = settingsRepository,
        _historyRepository = historyRepository,
        _trustRegistry = trustRegistry,
        _authVault = authVault,
        _telemetrySink = telemetrySink,
        _qrPayloadCodec = qrPayloadCodec ?? const QrPayloadCodec(),
        _protocolValidator = protocolValidator ?? const ProtocolValidator(),
        _tokenService = tokenService ?? TokenService(),
        _uploadClient = uploadClient ?? TransferUploadClient(),
        _discoveryService = discoveryService ?? MdnsDiscoveryService();

  final ISettingsRepository _settingsRepository;
  final ITransferHistoryRepository _historyRepository;
  final ITrustRegistry _trustRegistry;
  final TrustedSecretVault _authVault;
  final ITelemetrySink _telemetrySink;
  final QrPayloadCodec _qrPayloadCodec;
  final ProtocolValidator _protocolValidator;
  final TokenService _tokenService;
  final TransferUploadClient _uploadClient;
  final IDiscoveryService _discoveryService;

  final StreamController<MobileConnectionState> _stateController =
      StreamController<MobileConnectionState>.broadcast();
  final StreamController<ActiveConnection?> _connectionController =
      StreamController<ActiveConnection?>.broadcast();
  final StreamController<ConnectionHealthState> _healthController =
      StreamController<ConnectionHealthState>.broadcast();

  MobileConnectionState _state = MobileConnectionState.initial();
  WebSocket? _socket;
  Completer<PairingResponse>? _pairingCompleter;
  Completer<Map<String, dynamic>>? _authChallengeCompleter;
  Completer<bool>? _authAcceptedCompleter;
  Completer<UploadInitResponse>? _uploadReadyCompleter;

  Stream<MobileConnectionState> watchState() async* {
    yield _state;
    yield* _stateController.stream;
  }

  @override
  Future<void> connectToTrustedDevice(TrustedDevice device) => reconnect(device);

  @override
  Future<void> disconnect({String? reason}) async {
    await _socket?.close();
    _socket = null;
    _state = _state.copyWith(
      status: AppConnectionStatus.idle,
      clearConnection: true,
      lastError: reason,
      lastHealth: ConnectionHealthState.offline,
    );
    _emitState();
    _connectionController.add(null);
    _healthController.add(ConnectionHealthState.offline);
  }

  String get mobileDeviceId =>
      _tokenService.sha256Of(Platform.localHostname).substring(0, 24);

  Future<void> pairFromQr(String encodedPayload) async {
    final payload = _qrPayloadCodec.decode(encodedPayload);
    _protocolValidator.validateQrPayload(payload, DateTime.now().toUtc());
    final ws = await WebSocket.connect('ws://${payload.localIp}:${payload.port}/ws');
    _socket = ws;
    _listenToSocket(ws);
    _state = _state.copyWith(
      status: AppConnectionStatus.pairing,
      clearError: true,
    );
    _emitState();

    _pairingCompleter = Completer<PairingResponse>();
    _sendMessage(
      ProtocolMessageType.pairRequest.name,
      PairingRequest(
        sessionId: payload.sessionId,
        oneTimePairingToken: payload.oneTimePairingToken,
        mobileDeviceId: mobileDeviceId,
        mobileDeviceName: Platform.localHostname,
        clientNonce: _tokenService.generateOpaqueToken(length: 14),
        requestedAt: DateTime.now().toUtc(),
        certificateFingerprint: payload.tlsCertSha256,
        capabilities: const <String, bool>{
          'camera_capture': true,
          'auto_send': true,
          'review_before_send': true,
        },
      ).toJson(),
    );

    final response = await _pairingCompleter!.future.timeout(
      const Duration(seconds: 15),
    );
    if (!response.accepted) {
      _state = _state.copyWith(
        status: AppConnectionStatus.error,
        lastError: response.rejectionReason ?? 'Pairing rejected.',
      );
      _emitState();
      throw StateError(response.rejectionReason ?? 'Pairing rejected.');
    }

    final trustedDevice = TrustedDevice(
      trustedDeviceId: response.trustedDeviceId,
      desktopDeviceId: payload.desktopDeviceId,
      deviceName: payload.desktopName,
      nickname: payload.desktopName,
      platform: TrustedDevicePlatform.windows,
      pairedAt: DateTime.now().toUtc(),
      lastConnectedAt: DateTime.now().toUtc(),
      lastKnownHost: payload.localIp,
      lastKnownPort: payload.port,
      certificateSha256: payload.tlsCertSha256,
      revoked: false,
      autoReconnect: true,
    );
    await _trustRegistry.upsert(trustedDevice);
    await _authVault.save(trustedDevice.trustedDeviceId, response.refreshSecret);

    final connection = ActiveConnection(
      connectionId: _tokenService.generateOpaqueToken(length: 16),
      trustedDeviceId: trustedDevice.trustedDeviceId,
      remoteHost: trustedDevice.lastKnownHost,
      remotePort: trustedDevice.lastKnownPort,
      connectedAt: DateTime.now().toUtc(),
      healthState: ConnectionHealthState.excellent,
      lastRoundTripMs: 0,
      authenticated: true,
      remoteDevice: _currentDeviceInfo(),
    );
    _state = _state.copyWith(
      status: AppConnectionStatus.connected,
      activeConnection: connection,
      currentDevice: trustedDevice,
      clearError: true,
      lastHealth: ConnectionHealthState.excellent,
    );
    _emitState();
    _connectionController.add(connection);
    _healthController.add(ConnectionHealthState.excellent);
  }

  Future<void> reconnect(TrustedDevice trustedDevice) async {
    final candidate =
        await _discoveryService.resolveTrustedDevice(trustedDevice) ??
            DiscoveryCandidate(
              trustedDeviceId: trustedDevice.trustedDeviceId,
              host: trustedDevice.lastKnownHost,
              port: trustedDevice.lastKnownPort,
              desktopName: trustedDevice.deviceName,
              certificateSha256: trustedDevice.certificateSha256,
            );
    final ws = await WebSocket.connect('ws://${candidate.host}:${candidate.port}/ws');
    _socket = ws;
    _listenToSocket(ws);
    _state = _state.copyWith(status: AppConnectionStatus.pairing, clearError: true);
    _emitState();

    _authChallengeCompleter = Completer<Map<String, dynamic>>();
    _authAcceptedCompleter = Completer<bool>();

    _sendMessage(
      ProtocolMessageType.hello.name,
      <String, dynamic>{
        'trustedDeviceId': trustedDevice.trustedDeviceId,
        'deviceInfo': _currentDeviceInfo().toJson(),
      },
    );

    final challenge = await _authChallengeCompleter!.future.timeout(
      const Duration(seconds: 10),
    );
    final secret = await _authVault.read(trustedDevice.trustedDeviceId);
    if (secret == null) {
      throw StateError('Trusted secret is missing.');
    }
    final clientNonce = _tokenService.generateOpaqueToken(length: 16);
    final timestamp = DateTime.now().toUtc().toIso8601String();
    final signature = _tokenService.generateHmac(
      secret: secret,
      parts: <String>[
        trustedDevice.trustedDeviceId,
        challenge['desktopDeviceId'] as String,
        challenge['serverNonce'] as String,
        clientNonce,
        timestamp,
        mobileDeviceId,
      ],
    );
    _sendMessage(
      ProtocolMessageType.authSuccess.name,
      <String, dynamic>{
        'trustedDeviceId': trustedDevice.trustedDeviceId,
        'mobileDeviceId': mobileDeviceId,
        'clientNonce': clientNonce,
        'timestamp': timestamp,
        'signature': signature,
      },
    );
    final accepted = await _authAcceptedCompleter!.future.timeout(
      const Duration(seconds: 10),
    );
    if (!accepted) {
      throw StateError('Trusted reconnect rejected.');
    }

    final connection = ActiveConnection(
      connectionId: _tokenService.generateOpaqueToken(length: 16),
      trustedDeviceId: trustedDevice.trustedDeviceId,
      remoteHost: candidate.host,
      remotePort: candidate.port,
      connectedAt: DateTime.now().toUtc(),
      healthState: ConnectionHealthState.good,
      lastRoundTripMs: 0,
      authenticated: true,
      remoteDevice: _currentDeviceInfo(),
    );
    _state = _state.copyWith(
      status: AppConnectionStatus.connected,
      activeConnection: connection,
      currentDevice: trustedDevice.copyWith(
        lastKnownHost: candidate.host,
        lastKnownPort: candidate.port,
        lastConnectedAt: DateTime.now().toUtc(),
      ),
      clearError: true,
      lastHealth: ConnectionHealthState.good,
    );
    _emitState();
    _connectionController.add(connection);
    _healthController.add(ConnectionHealthState.good);
  }

  @override
  Future<void> sendHeartbeat() async {
    _sendMessage(
      ProtocolMessageType.heartbeat.name,
      <String, dynamic>{'timestamp': DateTime.now().toUtc().toIso8601String()},
    );
  }

  Future<TransferResult> uploadJob(
    TransferJob job, {
    void Function(int sent, int total)? onProgress,
  }) async {
    final socket = _socket;
    final trustedDevice = _state.currentDevice;
    if (socket == null || trustedDevice == null) {
      throw StateError('No active connection.');
    }
    final secret = await _authVault.read(trustedDevice.trustedDeviceId);
    if (secret == null) {
      throw StateError('Trusted secret missing.');
    }

    _uploadReadyCompleter = Completer<UploadInitResponse>();
    _sendMessage(
      ProtocolMessageType.uploadInit.name,
      UploadInitRequest(
        transferJobId: job.jobId,
        sanitizedFilename: job.photo.sanitizedFilename,
        byteLength: job.photo.byteLength,
        checksumSha256: job.photo.checksumSha256,
        capturedAt: job.photo.capturedAt,
        mimeType: job.photo.mimeType,
        sourceDeviceId: job.photo.sourceDeviceId,
        compressionQuality: job.photo.compressionQuality ?? 88,
      ).toJson(),
    );

    final init = await _uploadReadyCompleter!.future.timeout(
      const Duration(seconds: 10),
    );
    final file = File(job.photo.sourceFilePath);
    final ack = await _uploadClient.upload(
      init: init,
      file: file,
      authToken: secret,
      onProgress: onProgress ?? (_, __) {},
    );
    final result = TransferResult(
      jobId: job.jobId,
      status: ack.duplicate ? TransferStatus.duplicate : TransferStatus.completed,
      completedAt: ack.completedAt,
      finalFilename: ack.finalFilename,
      duplicate: ack.duplicate,
      checksumSha256: job.photo.checksumSha256,
      storagePath: file.path,
      message: ack.message,
    );
    return result;
  }

  @override
  Stream<ActiveConnection?> watchActiveConnection() => _connectionController.stream;

  @override
  Stream<ConnectionHealthState> watchHealth() => _healthController.stream;

  DeviceInfo _currentDeviceInfo() {
    return DeviceInfo(
      deviceId: mobileDeviceId,
      deviceName: Platform.localHostname,
      platform: Platform.isIOS
          ? TrustedDevicePlatform.ios
          : TrustedDevicePlatform.android,
      appVersion: '1.0.0',
      osVersion: Platform.operatingSystemVersion,
      capabilities: const <String, bool>{
        'camera_capture': true,
        'manual_resend': true,
        'queue': true,
      },
    );
  }

  void _emitState() {
    _stateController.add(_state);
  }

  void _listenToSocket(WebSocket socket) {
    socket.listen(
      (dynamic data) async {
        final json = jsonDecode(data as String) as Map<String, dynamic>;
        final message = ProtocolMessage.fromJson(json);
        switch (message.type) {
          case 'pairResponse':
          case 'pair_response':
            _pairingCompleter?.complete(PairingResponse.fromJson(message.payload));
            break;
          case 'authChallenge':
          case 'auth_challenge':
            _authChallengeCompleter?.complete(message.payload);
            break;
          case 'authSuccess':
          case 'auth_success':
            _authAcceptedCompleter?.complete(
              (message.payload['accepted'] as bool?) ?? true,
            );
            break;
          case 'heartbeatAck':
          case 'heartbeat_ack':
            _state = _state.copyWith(lastHealth: ConnectionHealthState.excellent);
            _emitState();
            _healthController.add(ConnectionHealthState.excellent);
            break;
          case 'uploadReady':
          case 'upload_ready':
            _uploadReadyCompleter?.complete(
              UploadInitResponse.fromJson(message.payload),
            );
            break;
          case 'uploadError':
          case 'upload_error':
            final error = ErrorMessage.fromJson(message.payload);
            _state = _state.copyWith(
              status: AppConnectionStatus.error,
              lastError: error.message,
            );
            _emitState();
            break;
          case 'disconnect':
            await disconnect(reason: 'Desktop closed the session.');
            break;
          default:
            break;
        }
      },
      onDone: () async => disconnect(reason: 'Connection closed.'),
      onError: (Object error, StackTrace stackTrace) async {
        await _telemetrySink.recordError(error, stackTrace: stackTrace);
        await disconnect(reason: error.toString());
      },
    );
  }

  void _sendMessage(String type, Map<String, dynamic> payload) {
    final socket = _socket;
    if (socket == null) {
      throw StateError('No socket available.');
    }
    socket.add(
      jsonEncode(
        ProtocolMessage(
          messageId: _tokenService.generateOpaqueToken(length: 14),
          type: type,
          protocolVersion: 1,
          timestamp: DateTime.now().toUtc(),
          payload: payload,
        ).toJson(),
      ),
    );
  }
}
