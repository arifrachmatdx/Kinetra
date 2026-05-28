import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PoseTransform {
  static Size rotatedImageSize(Size imageSize, InputImageRotation rotation) {
    switch (rotation) {
      case InputImageRotation.rotation90deg:
      case InputImageRotation.rotation270deg:
        return Size(imageSize.height, imageSize.width);
      case InputImageRotation.rotation0deg:
      case InputImageRotation.rotation180deg:
        return imageSize;
    }
  }

  /// Returns a rect (in widget coordinates) where the camera image is drawn
  /// using [fit], centered within [widgetSize]. For BoxFit.cover, the rect can
  /// extend beyond the widget bounds (cropping), which is desired.
  static Rect imageRectInWidget({
    required Size widgetSize,
    required Size imageSize,
    required BoxFit fit,
  }) {
    final fitted = applyBoxFit(fit, imageSize, widgetSize);
    final destinationSize = fitted.destination;
    final dx = (widgetSize.width - destinationSize.width) / 2;
    final dy = (widgetSize.height - destinationSize.height) / 2;
    return Rect.fromLTWH(dx, dy, destinationSize.width, destinationSize.height);
  }

  static Offset translateLandmark({
    required PoseLandmark landmark,
    required Size widgetSize,
    required Size imageSize,
    required InputImageRotation rotation,
    required bool isFrontCamera,
    required BoxFit fit,
  }) {
    final rotatedSize = rotatedImageSize(imageSize, rotation);
    final rect = imageRectInWidget(widgetSize: widgetSize, imageSize: rotatedSize, fit: fit);

    // ML Kit Pose returns coordinates in the input image coordinate system
    // AFTER the rotation metadata is applied. So we should NOT rotate the
    // points again here (double-rotation causes drift/inaccuracy).
    final scaleX = rect.width / rotatedSize.width;
    final scaleY = rect.height / rotatedSize.height;

    var x = rect.left + landmark.x * scaleX;
    final y = rect.top + landmark.y * scaleY;

    if (isFrontCamera) {
      x = rect.left + rect.width - (landmark.x * scaleX);
    }

    return Offset(x, y);
  }
}

