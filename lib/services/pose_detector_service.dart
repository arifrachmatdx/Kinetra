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
        // Use base model for responsiveness (Posefit-like realtime feel).
        // Accurate can be heavier and cause UI lag on some devices.
        model: PoseDetectionModel.base,
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

    // For Android, the camera plugin commonly outputs YUV_420_888.
    // ML Kit expects NV21 bytes for InputImage.fromBytes.
    if (Platform.isAndroid) {
      if (image.planes.length != 3) return null;

      final nv21 = _yuv420ToNv21(image);
      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: _rotationIntToImageRotation(rotation),
        format: InputImageFormat.nv21,
        // For NV21, bytesPerRow should match the image width.
        bytesPerRow: image.width,
      );
      return InputImage.fromBytes(bytes: nv21, metadata: metadata);
    }

    // Fallback (non-Android) - keep previous behavior.
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

  Uint8List _yuv420ToNv21(CameraImage image) {
    final width = image.width;
    final height = image.height;

    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final yBytes = yPlane.bytes;
    final uBytes = uPlane.bytes;
    final vBytes = vPlane.bytes;

    final yRowStride = yPlane.bytesPerRow;
    final uvRowStride = uPlane.bytesPerRow;
    final uvPixelStride = uPlane.bytesPerPixel ?? 1;

    final out = Uint8List(width * height + (width * height ~/ 2));
    var outIndex = 0;

    // Copy Y
    for (var row = 0; row < height; row++) {
      final rowStart = row * yRowStride;
      out.setRange(outIndex, outIndex + width, yBytes, rowStart);
      outIndex += width;
    }

    // Interleave VU for NV21
    final uvHeight = height ~/ 2;
    for (var row = 0; row < uvHeight; row++) {
      for (var col = 0; col < width ~/ 2; col++) {
        final uvIndex = row * uvRowStride + col * uvPixelStride;
        out[outIndex++] = vBytes[uvIndex];
        out[outIndex++] = uBytes[uvIndex];
      }
    }

    return out;
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

  InputImageRotation rotationFromDegrees(int rotation) =>
      _rotationIntToImageRotation(rotation);

  int computeRotation({
    required int sensorOrientation,
    required DeviceOrientation deviceOrientation,
    required bool isFrontCamera,
  }) {
    if (!Platform.isAndroid) return sensorOrientation % 360;

    // Device orientation to degrees (Android)
    final rotation = switch (deviceOrientation) {
      DeviceOrientation.portraitUp => 0,
      DeviceOrientation.landscapeLeft => 90,
      DeviceOrientation.portraitDown => 180,
      DeviceOrientation.landscapeRight => 270,
    };

    // Per ML Kit examples: back uses subtraction, front uses addition.
    final rotationCompensation =
        isFrontCamera ? (sensorOrientation + rotation) : (sensorOrientation - rotation);

    return (rotationCompensation % 360 + 360) % 360;
  }

  Future<void> dispose() async {
    await _detector?.close();
    _detector = null;
    _isProcessing = false;
  }
}
