import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:kinetra/logic/exercise_logic.dart';
import 'package:kinetra/logic/pose_math.dart';

class JumpingJackLogic implements ExerciseLogic {
  @override
  int repCount = 0;

  @override
  String feedback = 'Hadap kamera, full body terlihat';

  @override
  String status = 'idle';

  @override
  bool isPoseValid = false;

  String _phase = 'down';
  DateTime? _lastRepTime;

  @override
  void reset() {
    repCount = 0;
    feedback = 'Hadap kamera, full body terlihat';
    status = 'idle';
    isPoseValid = false;
    _phase = 'down';
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

    final lw = pose.landmarks[PoseLandmarkType.leftWrist];
    final rw = pose.landmarks[PoseLandmarkType.rightWrist];
    final ls = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rs = pose.landmarks[PoseLandmarkType.rightShoulder];
    final la = pose.landmarks[PoseLandmarkType.leftAnkle];
    final ra = pose.landmarks[PoseLandmarkType.rightAnkle];
    final nose = pose.landmarks[PoseLandmarkType.nose];

    if (!PoseMath.isVisible(lw) ||
        !PoseMath.isVisible(rw) ||
        !PoseMath.isVisible(ls) ||
        !PoseMath.isVisible(rs) ||
        !PoseMath.isVisible(la) ||
        !PoseMath.isVisible(ra)) {
      isPoseValid = false;
      status = 'invalid';
      feedback = 'Pastikan full body terlihat';
      return;
    }

    isPoseValid = true;

    final leftWrist = lw!;
    final rightWrist = rw!;
    final leftShoulder = ls!;
    final rightShoulder = rs!;
    final leftAnkle = la!;
    final rightAnkle = ra!;

    // Arms "up": wrists clearly higher than shoulders.
    // Use an adaptive margin so it works across different camera distances.
    final lh = pose.landmarks[PoseLandmarkType.leftHip];
    final rh = pose.landmarks[PoseLandmarkType.rightHip];
    final torso =
        (PoseMath.isVisible(lh) && PoseMath.isVisible(rh)) ? ((lh!.y + rh!.y) / 2) : null;
    final shoulderMidY = (leftShoulder.y + rightShoulder.y) / 2;
    final margin = torso == null ? 10.0 : ((torso - shoulderMidY).abs() * 0.15).clamp(8.0, 40.0);

    final armsUp = (leftWrist.y < leftShoulder.y - margin) &&
        (rightWrist.y < rightShoulder.y - margin) &&
        (nose == null || (leftWrist.y < nose.y + margin && rightWrist.y < nose.y + margin));

    // Legs "open": ankle distance larger than shoulder width.
    final shoulderWidth =
        (leftShoulder.x - rightShoulder.x).abs().clamp(1.0, 9999.0);
    final ankleWidth = (leftAnkle.x - rightAnkle.x).abs();
    final legsOpen = ankleWidth > shoulderWidth * 1.05;

    final upPose = armsUp && legsOpen;

    if (upPose) {
      status = 'up';
      feedback = 'Bagus! Turunkan kembali';
      _phase = 'up';
      return;
    }

    // Down pose: wrists below shoulders and legs closed-ish
    final armsDown = (leftWrist.y > leftShoulder.y) &&
        (rightWrist.y > rightShoulder.y);
    final legsClosed = ankleWidth < shoulderWidth * 1.12;

    if (armsDown && legsClosed) {
      status = 'down';
      if (_phase == 'up') {
        final now = DateTime.now();
        if (_lastRepTime == null ||
            now.difference(_lastRepTime!).inMilliseconds > 350) {
          repCount++;
          _lastRepTime = now;
        }
      }
      _phase = 'down';
      feedback = 'Gerakan bagus';
      return;
    }

    status = 'idle';
    feedback = 'Lakukan jumping jack penuh (tangan atas + kaki membuka)';
  }
}
