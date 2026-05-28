import 'dart:math' as math;

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PoseMath {
  static double angle(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    final radians = math.atan2(c.y - b.y, c.x - b.x) - math.atan2(a.y - b.y, a.x - b.x);
    var degrees = radians.abs() * 180 / math.pi;
    if (degrees > 180) degrees = 360 - degrees;
    return degrees;
  }

  static double landmarkScore(PoseLandmark? landmark) {
    if (landmark == null) return 0;
    return landmark.likelihood;
  }

  static bool isVisible(PoseLandmark? landmark, {double min = 0.5}) {
    return landmark != null && landmark.likelihood >= min;
  }
}
