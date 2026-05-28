import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:kinetra/logic/exercise_logic.dart';
import 'package:kinetra/logic/pose_math.dart';

class SquatLogic implements ExerciseLogic {
  @override
  int repCount = 0;

  @override
  String feedback = 'Posisikan kamera dari samping';

  @override
  String status = 'idle';

  @override
  bool isPoseValid = false;

  String _phase = 'standing';
  DateTime? _lastRepTime;

  @override
  void reset() {
    repCount = 0;
    feedback = 'Posisikan kamera dari samping';
    status = 'idle';
    isPoseValid = false;
    _phase = 'standing';
    _lastRepTime = null;
  }

  @override
  void processPose(Pose? pose) {
    if (pose == null) {
      isPoseValid = false;
      status = 'invalid';
      feedback = 'Pose tidak terdeteksi';
      return;
    }

    final useLeft = _preferLeftSide(pose);
    final hip = pose.landmarks[
        useLeft ? PoseLandmarkType.leftHip : PoseLandmarkType.rightHip];
    final knee = pose.landmarks[
        useLeft ? PoseLandmarkType.leftKnee : PoseLandmarkType.rightKnee];
    final ankle = pose.landmarks[
        useLeft ? PoseLandmarkType.leftAnkle : PoseLandmarkType.rightAnkle];
    final shoulder = pose.landmarks[
        useLeft ? PoseLandmarkType.leftShoulder : PoseLandmarkType.rightShoulder];

    if (!PoseMath.isVisible(hip) ||
        !PoseMath.isVisible(knee) ||
        !PoseMath.isVisible(ankle)) {
      isPoseValid = false;
      status = 'invalid';
      feedback = 'Pose tidak terdeteksi';
      return;
    }

    isPoseValid = true;
    final kneeAngle = PoseMath.angle(hip!, knee!, ankle!);

    if (kneeAngle > 155) {
      status = 'up';
      if (_phase == 'squatting') {
        final now = DateTime.now();
        if (_lastRepTime == null ||
            now.difference(_lastRepTime!).inMilliseconds > 500) {
          repCount++;
          _lastRepTime = now;
          feedback = 'Gerakan bagus';
        }
      }
      _phase = 'standing';
    } else if (kneeAngle < 110) {
      status = 'down';
      _phase = 'squatting';
      if (kneeAngle > 95) {
        feedback = 'Turunkan badan lebih rendah';
      } else {
        feedback = 'Turunkan badan lebih rendah';
      }
    } else {
      status = 'idle';
    }

    final shoulderLm = shoulder;
    final hipLm = hip;
    if (PoseMath.isVisible(shoulderLm) && PoseMath.isVisible(hipLm)) {
      final torsoAngle = (shoulderLm!.y - hipLm!.y).abs();
      if (torsoAngle > 80) {
        feedback = 'Posisi punggung kurang lurus';
      }
    }
  }

  bool _preferLeftSide(Pose pose) {
    final left = [
      pose.landmarks[PoseLandmarkType.leftHip],
      pose.landmarks[PoseLandmarkType.leftKnee],
      pose.landmarks[PoseLandmarkType.leftAnkle],
    ];
    final right = [
      pose.landmarks[PoseLandmarkType.rightHip],
      pose.landmarks[PoseLandmarkType.rightKnee],
      pose.landmarks[PoseLandmarkType.rightAnkle],
    ];
    final leftScore = left.fold<double>(0, (s, l) => s + PoseMath.landmarkScore(l));
    final rightScore =
        right.fold<double>(0, (s, l) => s + PoseMath.landmarkScore(l));
    return leftScore >= rightScore;
  }
}
