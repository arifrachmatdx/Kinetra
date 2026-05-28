import 'package:camera/camera.dart';

class CameraService {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];

  CameraController? get controller => _controller;
  bool get isInitialized => _controller?.value.isInitialized ?? false;

  Future<void> initialize({bool useFrontCamera = false}) async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) {
      throw CameraException('no_camera', 'Kamera tidak tersedia');
    }

    CameraDescription camera;
    if (useFrontCamera) {
      camera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );
    } else {
      camera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );
    }

    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _controller!.initialize();
  }

  Future<void> startImageStream(void Function(CameraImage image) onImage) async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    await _controller!.startImageStream(onImage);
  }

  Future<void> stopImageStream() async {
    if (_controller?.value.isStreamingImages ?? false) {
      await _controller!.stopImageStream();
    }
  }

  bool get isFrontCamera =>
      _controller?.description.lensDirection == CameraLensDirection.front;

  int get sensorOrientation => _controller?.description.sensorOrientation ?? 90;

  Future<void> dispose() async {
    await stopImageStream();
    await _controller?.dispose();
    _controller = null;
  }
}
