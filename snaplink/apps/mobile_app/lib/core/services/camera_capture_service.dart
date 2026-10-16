import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraCaptureService {
  CameraController? _controller;

  CameraController? get controller => _controller;

  Future<bool> initialize() async {
    final permission = await Permission.camera.request();
    if (!permission.isGranted) {
      return false;
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      return false;
    }

    _controller = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await _controller!.initialize();
    return true;
  }

  Future<XFile> capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      throw StateError('Camera is not initialized.');
    }
    return controller.takePicture();
  }

  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
  }
}
