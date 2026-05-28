import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

abstract class ExerciseLogic {
  int get repCount;
  String get feedback;
  String get status;
  bool get isPoseValid;

  void processPose(Pose? pose);
  void reset();
}
