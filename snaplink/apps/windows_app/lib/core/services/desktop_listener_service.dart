import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:core_protocol/core_protocol.dart';
import 'package:device_security/device_security.dart';
import 'package:path/path.dart' as p;
import 'package:transfer_engine/transfer_engine.dart';

import '../models/desktop_listener_state.dart';
import 'support_services.dart';

class DesktopListenerService implements ITransportProvider, IConnectionManager {
  DesktopListenerService({
    required ISettingsRepository settingsRepository,
    required ITransferHistoryRepository historyRepository,
    required ILogRepository logRepository,
    required ITrustRegistry trustRegistry,
    required TrustedSecretVault authVault,
    required ITelemetrySink telemetrySink,
    required String supportDirectoryPath,
    TokenService? tokenService,
    ProtocolValidator? protocolValidator,
    QrPayloadCodec? qrPayloadCodec,
    FileReceivePipeline? fileReceivePipeline,
    DesktopNotificationService? notificationService,
  })  : _settingsRepository = settingsRepository,
        _historyRepository = historyRepository,
        _logRepository = logRepository,
        _trustRegistry = trustRegistry,
        _authVault = authVault,
        _telemetrySink = telemetrySink,
        _supportDirectoryPath = supportDirectoryPath,
        _tokenService = tokenService ?? TokenService(),
        _protocolValidator = protocolValidator ?? const ProtocolValidator(),
        _qrPayloadCodec = qrPayloadCodec ?? const QrPayloadCodec(),
        _fileReceivePipeline = fileReceivePipeline ?? FileReceivePipeline(),
        _notificationService =
            notificationService ?? const DesktopNotificationService();

  final ISettingsRepository _settingsRepository;
  final ITransferHistoryRepository _historyRepository;
  final ILogRepository _logRepository;
  final ITrustRegistry _trustRegistry;
  final TrustedSecretVault _authVault;
  final ITelemetrySink _telemetrySink;
  final String _supportDirectoryPath;
  final TokenService _tokenService;
  final ProtocolValidator _protocolValidator;
  final QrPayloadCodec _qrPayloadCodec;
  final FileReceivePipeline _fileReceivePipeline;
  final DesktopNotificationService _notificationService;

  final StreamController<DesktopListenerState> _stateController =
      StreamController<DesktopListenerState>.broadcast();
  final StreamController<ActiveConnection?> _connectionController =
      StreamController<ActiveConnection?>.broadcast();
  final StreamController<ConnectionHealthState> _healthController =
      StreamController<ConnectionHealthState>.broadcast();
  final Map<String, _PendingUpload> _pendingUploads = <String, _PendingUpload>{};
  final ReplayGuard _replayGuard = ReplayGuard();
  final Map<WebSocket, _PendingAuth> _pendingAuth = <WebSocket, _PendingAuth>{};
  final Map<String, WebSocket> _socketsByTrustedDeviceId = <String, WebSocket>{};

  DesktopListenerState _state = DesktopListenerState.initial();
  HttpServer? _server;
  PairingSession? _session;
  String? _localHost;
  AppSettings? _settings;

  Stream<DesktopListenerState> watchState() async* {
    yield _state;
    yield* _stateController.stream;
  }

  PairingQrPayload? get currentQrPayload => _session == null || _localHost == null
      ? null
      : PairingQrPayload(
          protocolVersion: 1,
          sessionId: _session!.sessionId,
          oneTimePairingToken: _session!.oneTimeToken,
          desktopDeviceId: _session!.desktopDeviceId,
          desktopName: _session!.desktopName,
          localIp: _localHost!,
          port: _session!.port,
          expiresAt: _session!.expiresAt,
          tlsCertSha256: _session!.tlsCertSha256,
          capabilityFlags: _session!.capabilityFlags,
        );

  @override
  bool get isRunning => _server != null;

  @override
  Future<void> connectToTrustedDevice(TrustedDevice device) async {
    _state = _state.copyWith(
      status: AppConnectionStatus.connected,
      currentDevice: device,
    );
    _emitState();
  }

  @override
  Future<void> disconnect({String? reason}) async {
    final trustedDeviceId = _state.currentDevice?.trustedDeviceId;
    if (trustedDeviceId != null) {
      await _socketsByTrustedDeviceId[trustedDeviceId]?.close();
      _socketsByTrustedDeviceId.remove(trustedDeviceId);
    }
    _state = _state.copyWith(
      status: AppConnectionStatus.waitingForScan,
      clearConnection: true,
      lastError: reason,
    );
    _emitState();
    _connectionController.add(null);
    _healthController.add(ConnectionHealthState.offline);
  }

  Future<void> regeneratePairingSession() async {
    if (_settings == null || _localHost == null) {
      return;
    }
    _session = PairingSession(
      sessionId: _tokenService.generateOpaqueToken(length: 18),
      oneTimeToken: _tokenService.generateOpaqueToken(length: 32),
      expiresAt: DateTime.now().toUtc().add(const Duration(seconds: 60)),
      desktopDeviceId: _desktopDeviceId,
      desktopName: Platform.localHostname,
      localIp: _localHost!,
      port: _settings!.listenerPort,
      tlsCertSha256: _tokenService.sha256Of(_desktopDeviceId),
      used: false,
      capabilityFlags: const <String, bool>{
        'wifi_local': true,
        'http_upload': true,
        'reconnect': true,
        'tls_pinning_ready': false,
      },
    );
    final qr = currentQrPayload;
    _state = _state.copyWith(
      status: AppConnectionStatus.waitingForScan,
      pairingSession: _session,
      qrPayload: qr == null ? null : _qrPayloadCodec.encode(qr),
      clearError: true,
    );
    _emitState();
  }

  @override
  Future<void> sendHeartbeat() async {
    final connection = _state.activeConnection;
    if (connection == null) {
      return;
    }
    final socket = _socketsByTrustedDeviceId[connection.trustedDeviceId];
    if (socket == null) {
      return;
    }
    _sendMessage(
      socket,
      type: ProtocolMessageType.heartbeatAck.name,
      payload: <String, dynamic>{
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }

  @override
  Future<void> start() async {
    _settings = await _settingsRepository.read();
    final desiredDirectory = _settings!.saveDirectory.isEmpty
        ? p.join(Directory.current.path, 'SnaplinkReceives')
        : _settings!.saveDirectory;
    if (_settings!.saveDirectory.isEmpty) {
      _settings = _settings!.copyWith(saveDirectory: desiredDirectory);
      await _settingsRepository.write(_settings!);
    }

    _localHost = await _resolveLocalHost();
    _server = await HttpServer.bind(InternetAddress.anyIPv4, _settings!.listenerPort);
    _server!.listen(_handleRequest, onError: _handleServerError);
    await regeneratePairingSession();
    _state = _state.copyWith(serverRunning: true);
    _emitState();
    await _appendLog(
      'Desktop listener started on ${_localHost!}:${_settings!.listenerPort}',
    );
  }

  @override
  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _state = _state.copyWith(
      serverRunning: false,
      status: AppConnectionStatus.idle,
    );
    _emitState();
  }

  @override
  Stream<ActiveConnection?> watchActiveConnection() => _connectionController.stream;

  @override
  Stream<ConnectionHealthState> watchHealth() => _healthController.stream;

  Future<void> _appendLog(
    String message, {
    ReceiveLogLevel level = ReceiveLogLevel.info,
  }) {
    return _logRepository.append(
      ReceiveLogEntry(
        id: _tokenService.generateOpaqueToken(length: 12),
        timestamp: DateTime.now().toUtc(),
        level: level,
        message: message,
      ),
    );
  }

  String get _desktopDeviceId =>
      _tokenService.sha256Of(Platform.localHostname).substring(0, 24);

  void _emitState() {
    _stateController.add(_state);
  }

  Future<void> _handleAuthSuccess(
    WebSocket socket,
    ProtocolMessage message,
  ) async {
    final pending = _pendingAuth[socket];
    if (pending == null) {
      await _sendError(socket, 'auth_state_missing', 'No pending auth challenge.');
      return;
    }
    final trustedDeviceId = message.payload['trustedDeviceId'] as String?;
    final clientNonce = message.payload['clientNonce'] as String?;
    final mobileDeviceId = message.payload['mobileDeviceId'] as String?;
    final signature = message.payload['signature'] as String?;
    final timestamp = message.payload['timestamp'] as String?;
    if (trustedDeviceId == null ||
        clientNonce == null ||
        mobileDeviceId == null ||
        signature == null ||
        timestamp == null) {
      await _sendError(socket, 'auth_payload_invalid', 'Auth payload missing fields.');
      return;
    }

    final trustedDevice = await _trustRegistry.getByTrustedDeviceId(trustedDeviceId);
    if (trustedDevice == null || trustedDevice.revoked) {
      await _sendError(socket, 'device_revoked', 'Trusted device is not allowed.');
      return;
    }

    final secret = await _authVault.read(trustedDeviceId);
    if (secret == null) {
      await _sendError(socket, 'auth_secret_missing', 'Auth secret unavailable.');
      return;
    }

    final expected = _tokenService.generateHmac(
      secret: secret,
      parts: <String>[
        trustedDeviceId,
        _desktopDeviceId,
        pending.serverNonce,
        clientNonce,
        timestamp,
        mobileDeviceId,
      ],
    );

    if (!_tokenService.constantTimeEquals(expected, signature)) {
      await _sendError(socket, 'auth_failed', 'HMAC verification failed.');
      return;
    }

    final remoteDevice = pending.deviceInfo ??
        DeviceInfo(
          deviceId: mobileDeviceId,
          deviceName: trustedDevice.deviceName,
          platform: trustedDevice.platform,
          appVersion: 'unknown',
          osVersion: 'unknown',
        );
    final connection = ActiveConnection(
      connectionId: _tokenService.generateOpaqueToken(length: 16),
      trustedDeviceId: trustedDeviceId,
      remoteHost: socket.closeCode?.toString() ?? trustedDevice.lastKnownHost,
      remotePort: trustedDevice.lastKnownPort,
      connectedAt: DateTime.now().toUtc(),
      healthState: ConnectionHealthState.good,
      lastRoundTripMs: 0,
      authenticated: true,
      remoteDevice: remoteDevice,
    );
    _socketsByTrustedDeviceId[trustedDeviceId] = socket;
    _pendingAuth.remove(socket);
    _state = _state.copyWith(
      status: AppConnectionStatus.connected,
      activeConnection: connection,
      currentDevice: trustedDevice,
      clearError: true,
    );
    _emitState();
    _connectionController.add(connection);
    _healthController.add(ConnectionHealthState.good);
    _sendMessage(
      socket,
      type: ProtocolMessageType.authSuccess.name,
      payload: <String, dynamic>{
        'accepted': true,
        'trustedDeviceId': trustedDeviceId,
      },
    );
    await _appendLog('Trusted device ${trustedDevice.nickname} reconnected.');
  }

  Future<void> _handleHello(WebSocket socket, ProtocolMessage message) async {
    final deviceInfoJson = message.payload['deviceInfo'] as Map<String, dynamic>?;
    final trustedDeviceId = message.payload['trustedDeviceId'] as String?;
    final deviceInfo =
        deviceInfoJson == null ? null : DeviceInfo.fromJson(deviceInfoJson);

    if (trustedDeviceId == null) {
      return;
    }

    final trusted = await _trustRegistry.getByTrustedDeviceId(trustedDeviceId);
    if (trusted == null || trusted.revoked) {
      await _sendError(socket, 'device_untrusted', 'Device is not trusted.');
      return;
    }
    final serverNonce = _tokenService.generateOpaqueToken(length: 20);
    _pendingAuth[socket] = _PendingAuth(
      trustedDeviceId: trustedDeviceId,
      serverNonce: serverNonce,
      deviceInfo: deviceInfo,
    );
    _sendMessage(
      socket,
      type: ProtocolMessageType.authChallenge.name,
      payload: <String, dynamic>{
        'trustedDeviceId': trustedDeviceId,
        'desktopDeviceId': _desktopDeviceId,
        'serverNonce': serverNonce,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }

  Future<void> _handlePairRequest(WebSocket socket, ProtocolMessage message) async {
    if (!_replayGuard.register(message.messageId)) {
      await _sendError(socket, 'replay_detected', 'Message replay rejected.');
      return;
    }

    final request = PairingRequest.fromJson(message.payload);
    final session = _session;
    if (session == null) {
      await _sendError(socket, 'pairing_unavailable', 'No active pairing session.');
      return;
    }

    try {
      _protocolValidator.validateSession(session, DateTime.now().toUtc());
      _protocolValidator.validatePairingRequest(request, session);
    } on ProtocolValidationException catch (error) {
      _sendMessage(
        socket,
        type: ProtocolMessageType.pairResponse.name,
        payload: PairingResponse(
          accepted: false,
          desktopDeviceId: _desktopDeviceId,
          trustedDeviceId: '',
          refreshSecret: '',
          issuedAt: DateTime.now().toUtc(),
          expiresAt: DateTime.now().toUtc(),
          rejectionReason: error.message,
        ).toJson(),
      );
      _state = _state.copyWith(
        status: AppConnectionStatus.error,
        lastError: error.message,
      );
      _emitState();
      return;
    }

    final trustedDeviceId = _tokenService.generateOpaqueToken(length: 18);
    final refreshSecret = _tokenService.generateOpaqueToken(length: 40);
    final trustedDevice = TrustedDevice(
      trustedDeviceId: trustedDeviceId,
      desktopDeviceId: _desktopDeviceId,
      deviceName: request.mobileDeviceName,
      nickname: request.mobileDeviceName,
      platform: TrustedDevicePlatform.android,
      pairedAt: DateTime.now().toUtc(),
      lastConnectedAt: DateTime.now().toUtc(),
      lastKnownHost: request.mobileDeviceName,
      lastKnownPort: _settings!.listenerPort,
      certificateSha256: request.certificateFingerprint,
      revoked: false,
      autoReconnect: true,
    );

    await _trustRegistry.upsert(trustedDevice);
    await _authVault.save(trustedDeviceId, refreshSecret);
    _session = session.copyWith(used: true);
    _sendMessage(
      socket,
      type: ProtocolMessageType.pairResponse.name,
      payload: PairingResponse(
        accepted: true,
        desktopDeviceId: _desktopDeviceId,
        trustedDeviceId: trustedDeviceId,
        refreshSecret: refreshSecret,
        issuedAt: DateTime.now().toUtc(),
        expiresAt: DateTime.now().toUtc().add(const Duration(days: 30)),
      ).toJson(),
    );

    final connection = ActiveConnection(
      connectionId: _tokenService.generateOpaqueToken(length: 16),
      trustedDeviceId: trustedDeviceId,
      remoteHost: trustedDevice.lastKnownHost,
      remotePort: trustedDevice.lastKnownPort,
      connectedAt: DateTime.now().toUtc(),
      healthState: ConnectionHealthState.excellent,
      lastRoundTripMs: 0,
      authenticated: true,
      remoteDevice: DeviceInfo(
        deviceId: request.mobileDeviceId,
        deviceName: request.mobileDeviceName,
        platform: TrustedDevicePlatform.android,
        appVersion: '1.0.0',
        osVersion: 'unknown',
        capabilities: request.capabilities,
      ),
    );

    _socketsByTrustedDeviceId[trustedDeviceId] = socket;
    _state = _state.copyWith(
      status: AppConnectionStatus.connected,
      activeConnection: connection,
      currentDevice: trustedDevice,
      clearError: true,
    );
    _emitState();
    _connectionController.add(connection);
    _healthController.add(ConnectionHealthState.excellent);
    await _appendLog('Paired device ${trustedDevice.deviceName}');
    await regeneratePairingSession();
  }

  Future<void> _handleRequest(HttpRequest request) async {
    try {
      if (WebSocketTransformer.isUpgradeRequest(request) &&
          request.uri.path == '/ws') {
        final socket = await WebSocketTransformer.upgrade(request);
        await _handleWebSocket(socket);
        return;
      }

      if (request.method == 'PUT' &&
          request.uri.pathSegments.length == 3 &&
          request.uri.pathSegments[0] == 'api' &&
          request.uri.pathSegments[1] == 'uploads') {
        await _handleUploadRequest(request, request.uri.pathSegments[2]);
        return;
      }

      if (request.uri.path == '/health') {
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode(<String, dynamic>{
              'running': isRunning,
              'status': _state.status.name,
              'connectedDevice': _state.currentDevice?.nickname,
            }),
          );
        await request.response.close();
        return;
      }

      request.response
        ..statusCode = HttpStatus.notFound
        ..write('Not found');
      await request.response.close();
    } catch (error, stackTrace) {
      await _telemetrySink.recordError(error, stackTrace: stackTrace);
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..write('Server error');
      await request.response.close();
    }
  }

  Future<void> _handleServerError(Object error, StackTrace stackTrace) async {
    _state = _state.copyWith(
      status: AppConnectionStatus.error,
      lastError: error.toString(),
    );
    _emitState();
    await _telemetrySink.recordError(error, stackTrace: stackTrace);
    await _appendLog('Listener error: $error', level: ReceiveLogLevel.error);
  }

  Future<void> _handleUploadInit(WebSocket socket, ProtocolMessage message) async {
    final connection = _state.activeConnection;
    final currentDevice = _state.currentDevice;
    if (connection == null || currentDevice == null) {
      await _sendError(socket, 'upload_rejected', 'No authenticated connection.');
      return;
    }

    final request = UploadInitRequest.fromJson(message.payload);
    if (request.byteLength > _settings!.maxUploadBytes) {
      await _sendError(socket, 'file_too_large', 'Upload exceeds configured max size.');
      return;
    }

    final previous = await _historyRepository.readAll();
    final duplicate = previous.firstWhereOrNull(
      (item) => item.checksumSha256 == request.checksumSha256,
    );
    if (duplicate != null) {
      _sendMessage(
        socket,
        type: ProtocolMessageType.uploadAck.name,
        payload: UploadAck(
          transferJobId: request.transferJobId,
          uploadId: 'duplicate',
          success: true,
          duplicate: true,
          finalFilename: duplicate.finalFilename,
          completedAt: DateTime.now().toUtc(),
          message: 'Duplicate image already stored.',
        ).toJson(),
      );
      return;
    }

    final secret = await _authVault.read(connection.trustedDeviceId);
    if (secret == null) {
      await _sendError(socket, 'auth_secret_missing', 'Upload auth token missing.');
      return;
    }

    final uploadId = _tokenService.generateOpaqueToken(length: 18);
    final tempDirectory = Directory(p.join(_supportDirectoryPath, 'tmp_uploads'));
    await tempDirectory.create(recursive: true);
    _pendingUploads[uploadId] = _PendingUpload(
      request: request,
      trustedDevice: currentDevice,
      socket: socket,
      authSecret: secret,
      tempFile: File(p.join(tempDirectory.path, '$uploadId.part')),
    );

    _sendMessage(
      socket,
      type: ProtocolMessageType.uploadReady.name,
      payload: UploadInitResponse(
        accepted: true,
        uploadId: uploadId,
        uploadUrl: Uri.parse(
          'http://${_localHost!}:${_settings!.listenerPort}/api/uploads/$uploadId',
        ),
        maxAcceptedBytes: _settings!.maxUploadBytes,
      ).toJson(),
    );
  }

  Future<void> _handleUploadRequest(HttpRequest request, String uploadId) async {
    final pending = _pendingUploads[uploadId];
    if (pending == null) {
      request.response
        ..statusCode = HttpStatus.notFound
        ..write('Unknown upload');
      await request.response.close();
      return;
    }

    final authorization = request.headers.value(HttpHeaders.authorizationHeader);
    final token = authorization?.replaceFirst('Bearer ', '');
    if (token == null || !_tokenService.constantTimeEquals(token, pending.authSecret)) {
      request.response
        ..statusCode = HttpStatus.unauthorized
        ..write('Unauthorized');
      await request.response.close();
      return;
    }

    final bytes = await request.fold<List<int>>(
      <int>[],
      (List<int> previous, List<int> element) => <int>[...previous, ...element],
    );
    await pending.tempFile.writeAsBytes(bytes);

    final metadata = PhotoMetadata(
      sourceFilePath: pending.tempFile.path,
      originalFilename: pending.request.sanitizedFilename,
      sanitizedFilename: pending.request.sanitizedFilename,
      byteLength: pending.request.byteLength,
      checksumSha256: pending.request.checksumSha256,
      capturedAt: pending.request.capturedAt,
      mimeType: pending.request.mimeType,
      sourceDeviceId: pending.request.sourceDeviceId,
      compressionQuality: pending.request.compressionQuality,
    );

    _state = _state.copyWith(status: AppConnectionStatus.receiving);
    _emitState();

    try {
      final result = await _fileReceivePipeline.finalize(
        ReceivePipelineRequest(
          transferJobId: pending.request.transferJobId,
          device: pending.trustedDevice,
          metadata: metadata,
          tempFile: pending.tempFile,
          targetDirectory: Directory(_settings!.saveDirectory),
        ),
      );
      final finalResult = result.transferResult.copyWith(
        checksumSha256: pending.request.checksumSha256,
      );
      await _historyRepository.add(finalResult);
      await _appendLog(
        'Received ${finalResult.finalFilename} from ${pending.trustedDevice.nickname}',
      );
      await _notificationService.notifyReceiveSuccess(finalResult);
      final ack = UploadAck(
        transferJobId: pending.request.transferJobId,
        uploadId: uploadId,
        success: true,
        duplicate: finalResult.duplicate,
        finalFilename: finalResult.finalFilename,
        completedAt: finalResult.completedAt,
        message: finalResult.message,
      );
      _sendMessage(
        pending.socket,
        type: ProtocolMessageType.uploadAck.name,
        payload: ack.toJson(),
      );
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(ack.toJson()));
      _state = _state.copyWith(status: AppConnectionStatus.connected);
      _emitState();
      _pendingUploads.remove(uploadId);
    } catch (error, stackTrace) {
      await _telemetrySink.recordError(error, stackTrace: stackTrace);
      await _appendLog(
        'Upload failed for ${pending.request.sanitizedFilename}',
        level: ReceiveLogLevel.error,
      );
      _sendMessage(
        pending.socket,
        type: ProtocolMessageType.uploadError.name,
        payload: ErrorMessage(code: 'upload_failed', message: error.toString())
            .toJson(),
      );
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..write(error.toString());
    } finally {
      await request.response.close();
    }
  }

  Future<void> _handleWebSocket(WebSocket socket) async {
    socket.listen(
      (dynamic data) async {
        final Map<String, dynamic> json =
            jsonDecode(data as String) as Map<String, dynamic>;
        final message = ProtocolMessage.fromJson(json);
        _protocolValidator.validateMessage(message);

        switch (message.type) {
          case 'hello':
            await _handleHello(socket, message);
          case 'pairRequest':
          case 'pair_request':
            await _handlePairRequest(socket, message);
          case 'authSuccess':
          case 'auth_success':
            await _handleAuthSuccess(socket, message);
          case 'heartbeat':
            _sendMessage(
              socket,
              type: ProtocolMessageType.heartbeatAck.name,
              payload: <String, dynamic>{
                'timestamp': DateTime.now().toUtc().toIso8601String(),
              },
            );
          case 'uploadInit':
          case 'upload_init':
            await _handleUploadInit(socket, message);
          case 'disconnect':
            await disconnect(reason: 'Remote device closed the session.');
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

  Future<String> _resolveLocalHost() async {
    try {
      final interfaces = await NetworkInterface.list();
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (address.type == InternetAddressType.IPv4 && !address.isLoopback) {
            return address.address;
          }
        }
      }
    } catch (_) {}
    return InternetAddress.loopbackIPv4.address;
  }

  Future<void> _sendError(WebSocket socket, String code, String message) async {
    _sendMessage(
      socket,
      type: ProtocolMessageType.uploadError.name,
      payload: ErrorMessage(code: code, message: message).toJson(),
    );
  }

  void _sendMessage(
    WebSocket socket, {
    required String type,
    required Map<String, dynamic> payload,
  }) {
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

class _PendingAuth {
  const _PendingAuth({
    required this.trustedDeviceId,
    required this.serverNonce,
    this.deviceInfo,
  });

  final String trustedDeviceId;
  final String serverNonce;
  final DeviceInfo? deviceInfo;
}

class _PendingUpload {
  const _PendingUpload({
    required this.request,
    required this.trustedDevice,
    required this.socket,
    required this.authSecret,
    required this.tempFile,
  });

  final UploadInitRequest request;
  final TrustedDevice trustedDevice;
  final WebSocket socket;
  final String authSecret;
  final File tempFile;
}
