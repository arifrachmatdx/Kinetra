import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PoseDetectorService {
  PoseDetector? _detector;
  bool _isProcessing = false;

  Future<void> initialize() async {
    await dispose();
    _detector = PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.stream,
        model: PoseDetectionModel.accurate,
      ),
    );
  }

  bool get isProcessing => _isProcessing;

  Future<Pose?> processCameraImage(
    CameraImage image, {
    required int rotation,
    required bool isFrontCamera,
  }) async {
    if (_detector == null || _isProcessing) return null;
    _isProcessing = true;
    try {
      final inputImage = _convertCameraImage(
        image,
        rotation: rotation,
        isFrontCamera: isFrontCamera,
      );
      if (inputImage == null) return null;
      final poses = await _detector!.processImage(inputImage);
      if (poses.isEmpty) return null;
      return poses.first;
    } finally {
      _isProcessing = false;
    }
  }

  InputImage? _convertCameraImage(
    CameraImage image, {
    required int rotation,
    required bool isFrontCamera,
  }) {
    if (image.planes.isEmpty) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    final plane = image.planes.first;
    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: _rotationIntToImageRotation(rotation),
      format: format,
      bytesPerRow: plane.bytesPerRow,
    );

    return InputImage.fromBytes(
      bytes: _concatenatePlanes(image.planes),
      metadata: metadata,
    );
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final buffer = WriteBuffer();
    for (final plane in planes) {
      buffer.putUint8List(plane.bytes);
    }
    return buffer.done().buffer.asUint8List();
  }

  InputImageRotation _rotationIntToImageRotation(int rotation) {
    switch (rotation) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  int computeRotation({
    required int sensorOrientation,
    required DeviceOrientation deviceOrientation,
    required bool isFrontCamera,
  }) {
    var rotationCompensation = sensorOrientation;
    if (Platform.isAndroid) {
      switch (deviceOrientation) {
        case DeviceOrientation.portraitUp:
          rotationCompensation = sensorOrientation;
        case DeviceOrientation.landscapeLeft:
          rotationCompensation = sensorOrientation + 90;
        case DeviceOrientation.portraitDown:
          rotationCompensation = sensorOrientation + 180;
        case DeviceOrientation.landscapeRight:
          rotationCompensation = sensorOrientation - 90;
      }
    }
    if (isFrontCamera) {
      rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
    }
    return rotationCompensation % 360;
  }

  Future<void> dispose() async {
    await _detector?.close();
    _detector = null;
    _isProcessing = false;
  }
}
