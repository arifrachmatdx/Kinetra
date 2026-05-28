import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:kinetra/core/theme/app_colors.dart';
import 'package:kinetra/features/detection/widgets/pose_transform.dart';

class PosePainter extends CustomPainter {
  PosePainter({
    required this.pose,
    required this.imageSize,
    required this.isFrontCamera,
    required this.rotation,
    this.fit = BoxFit.contain,
    this.isValid = true,
  });

  final Pose? pose;
  final Size imageSize;
  final bool isFrontCamera;
  final InputImageRotation rotation;
  final BoxFit fit;
  final bool isValid;

  static const _connections = [
    [PoseLandmarkType.nose, PoseLandmarkType.leftEyeInner],
    [PoseLandmarkType.leftEyeInner, PoseLandmarkType.leftEye],
    [PoseLandmarkType.leftEye, PoseLandmarkType.leftEyeOuter],
    [PoseLandmarkType.nose, PoseLandmarkType.rightEyeInner],
    [PoseLandmarkType.rightEyeInner, PoseLandmarkType.rightEye],
    [PoseLandmarkType.rightEye, PoseLandmarkType.rightEyeOuter],
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
    [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
    [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
    [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
    [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
    [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
    [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
    [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (pose == null || imageSize.width == 0) return;

    final color = isValid ? AppColors.poseValid : AppColors.poseInvalid;
    final pointPaint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    Offset translate(PoseLandmark landmark) {
      return PoseTransform.translateLandmark(
        landmark: landmark,
        widgetSize: size,
        imageSize: imageSize,
        rotation: rotation,
        // Mirror overlay to match selfie preview.
        isFrontCamera: isFrontCamera,
        fit: fit,
      );
    }

    for (final connection in _connections) {
      final start = pose!.landmarks[connection[0]];
      final end = pose!.landmarks[connection[1]];
      if (start == null || end == null) continue;
      if (start.likelihood < 0.3 || end.likelihood < 0.3) continue;
      canvas.drawLine(translate(start), translate(end), linePaint);
    }

    for (final landmark in pose!.landmarks.values) {
      if (landmark.likelihood < 0.3) continue;
      canvas.drawCircle(translate(landmark), 5, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.pose != pose ||
        oldDelegate.isValid != isValid ||
        oldDelegate.imageSize != imageSize;
  }
}
