import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:kinetra/logic/exercise_logic.dart';
import 'package:kinetra/logic/pose_math.dart';

class PushUpLogic implements ExerciseLogic {
  @override
  int repCount = 0;

  @override
  String feedback = 'Posisikan kamera dari samping';

  @override
  String status = 'idle';

  @override
  bool isPoseValid = false;

  String _phase = 'up';
  DateTime? _lastRepTime;

  @override
  void reset() {
    repCount = 0;
    feedback = 'Posisikan kamera dari samping';
    status = 'idle';
    isPoseValid = false;
    _phase = 'up';
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
    final shoulder = pose.landmarks[
        useLeft ? PoseLandmarkType.leftShoulder : PoseLandmarkType.rightShoulder];
    final elbow = pose.landmarks[
        useLeft ? PoseLandmarkType.leftElbow : PoseLandmarkType.rightElbow];
    final wrist = pose.landmarks[
        useLeft ? PoseLandmarkType.leftWrist : PoseLandmarkType.rightWrist];
    final hip = pose.landmarks[
        useLeft ? PoseLandmarkType.leftHip : PoseLandmarkType.rightHip];
    final ankle = pose.landmarks[
        useLeft ? PoseLandmarkType.leftAnkle : PoseLandmarkType.rightAnkle];

    if (!PoseMath.isVisible(shoulder) ||
        !PoseMath.isVisible(elbow) ||
        !PoseMath.isVisible(wrist)) {
      isPoseValid = false;
      status = 'invalid';
      feedback = 'Pose tidak terdeteksi';
      return;
    }

    isPoseValid = true;
    final elbowAngle = PoseMath.angle(shoulder!, elbow!, wrist!);

    if (PoseMath.isVisible(hip) && PoseMath.isVisible(ankle)) {
      final backAngle = PoseMath.angle(shoulder, hip!, ankle!);
      if (backAngle < 150) {
        feedback = 'Posisi punggung kurang lurus';
      }
    }

    if (elbowAngle > 155) {
      status = 'up';
      if (_phase == 'down') {
        final now = DateTime.now();
        if (_lastRepTime == null ||
            now.difference(_lastRepTime!).inMilliseconds > 400) {
          repCount++;
          _lastRepTime = now;
          feedback = 'Gerakan bagus';
        }
      }
      _phase = 'up';
    } else if (elbowAngle < 100) {
      status = 'down';
      _phase = 'down';
      if (elbowAngle > 85) {
        feedback = 'Turunkan badan lebih rendah';
      } else {
        feedback = 'Turunkan badan lebih rendah';
      }
    } else {
      status = 'idle';
      if (feedback == 'Pose tidak terdeteksi') {
        feedback = 'Lanjutkan gerakan push up';
      }
    }
  }

  bool _preferLeftSide(Pose pose) {
    final left = [
      pose.landmarks[PoseLandmarkType.leftShoulder],
      pose.landmarks[PoseLandmarkType.leftElbow],
      pose.landmarks[PoseLandmarkType.leftWrist],
    ];
    final right = [
      pose.landmarks[PoseLandmarkType.rightShoulder],
      pose.landmarks[PoseLandmarkType.rightElbow],
      pose.landmarks[PoseLandmarkType.rightWrist],
    ];
    final leftScore = left.fold<double>(0, (s, l) => s + PoseMath.landmarkScore(l));
    final rightScore =
        right.fold<double>(0, (s, l) => s + PoseMath.landmarkScore(l));
    return leftScore >= rightScore;
  }
}
