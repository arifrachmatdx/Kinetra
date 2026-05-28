import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:kinetra/core/theme/app_colors.dart';

class PosePainter extends CustomPainter {
  PosePainter({
    required this.pose,
    required this.imageSize,
    required this.isFrontCamera,
    this.isValid = true,
  });

  final Pose? pose;
  final Size imageSize;
  final bool isFrontCamera;
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
      final x = landmark.x * size.width / imageSize.width;
      final y = landmark.y * size.height / imageSize.height;
      final mirroredX = isFrontCamera ? size.width - x : x;
      return Offset(mirroredX, y);
    }

    for (final connection in _connections) {
      final start = pose!.landmarks[connection[0]];
      final end = pose!.landmarks[connection[1]];
      if (start == null || end == null) continue;
      if (start.likelihood < 0.5 || end.likelihood < 0.5) continue;
      canvas.drawLine(translate(start), translate(end), linePaint);
    }

    for (final landmark in pose!.landmarks.values) {
      if (landmark.likelihood < 0.5) continue;
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
