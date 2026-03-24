import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';

class CameraCapturePage extends ConsumerStatefulWidget {
  const CameraCapturePage({super.key});

  @override
  ConsumerState<CameraCapturePage> createState() => _CameraCapturePageState();
}

class _CameraCapturePageState extends ConsumerState<CameraCapturePage> {
  bool _autoSend = true;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(cameraCaptureControllerProvider.notifier).initialize(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cameraState = ref.watch(cameraCaptureControllerProvider);
    final cameraController =
        ref.read(cameraCaptureControllerProvider.notifier).service.controller;
    final queue = ref.watch(transferQueueStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera'),
        actions: <Widget>[
          IconButton(
            onPressed: () => context.go('/history'),
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: cameraState.initialized &&
                    cameraController != null &&
                    cameraController.value.isInitialized
                ? CameraPreview(cameraController)
                : Container(
                    color: Colors.black,
                    child: Center(
                      child: Text(
                        cameraState.lastError ?? 'Preparing camera...',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: <Widget>[
                SwitchListTile.adaptive(
                  value: _autoSend,
                  onChanged: (bool value) => setState(() => _autoSend = value),
                  title: const Text('Auto-send after capture'),
                ),
                if (cameraState.lastCapturedPath != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Last captured: ${cameraState.lastCapturedPath}'),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: cameraState.capturing
                        ? null
                        : () => ref
                            .read(cameraCaptureControllerProvider.notifier)
                            .capture(autoSend: _autoSend),
                    icon: const Icon(Icons.camera_alt),
                    label: Text(cameraState.capturing ? 'Capturing...' : 'Capture'),
                  ),
                ),
                const SizedBox(height: 12),
                queue.when(
                  data: (jobs) => jobs.isEmpty
                      ? const SizedBox.shrink()
                      : Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Queued transfers: ${jobs.length}'),
                        ),
                  error: (Object error, StackTrace stackTrace) => Text('$error'),
                  loading: () => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

