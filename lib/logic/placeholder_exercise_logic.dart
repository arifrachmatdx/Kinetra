import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:kinetra/logic/exercise_logic.dart';

class PlaceholderExerciseLogic implements ExerciseLogic {
  PlaceholderExerciseLogic(this.exerciseName);

  final String exerciseName;

  @override
  int repCount = 0;

  @override
  String feedback = 'Latihan ini akan segera tersedia';

  @override
  String status = 'idle';

  @override
  bool isPoseValid = false;

  @override
  void processPose(Pose? pose) {
    if (pose == null) {
      isPoseValid = false;
      status = 'invalid';
      feedback = 'Pose tidak terdeteksi';
      return;
    }
    isPoseValid = true;
    status = 'idle';
    feedback = '$exerciseName — deteksi rep belum tersedia';
  }

  @override
  void reset() {
    repCount = 0;
    feedback = 'Latihan ini akan segera tersedia';
    status = 'idle';
    isPoseValid = false;
  }
}
