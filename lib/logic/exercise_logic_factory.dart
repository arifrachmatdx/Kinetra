import 'package:kinetra/logic/burpee_logic.dart';
import 'package:kinetra/logic/exercise_logic.dart';
import 'package:kinetra/logic/high_knee_logic.dart';
import 'package:kinetra/logic/jumping_jack_logic.dart';
import 'package:kinetra/logic/lunge_logic.dart';
import 'package:kinetra/logic/mountain_climber_logic.dart';
import 'package:kinetra/logic/push_up_logic.dart';
import 'package:kinetra/logic/sit_up_logic.dart';
import 'package:kinetra/logic/skater_jump_logic.dart';
import 'package:kinetra/logic/squat_logic.dart';

class ExerciseLogicFactory {
  static ExerciseLogic fromLatihanId(String latihanId) {
    switch (latihanId) {
      case 'push_up':
        return PushUpLogic();
      case 'squat':
        return SquatLogic();
      case 'jumping_jack':
        return JumpingJackLogic();
      case 'high_knee':
        return HighKneeLogic();
      case 'mountain_climber':
        return MountainClimberLogic();
      case 'sit_up':
        return SitUpLogic();
      case 'lunge':
        return LungeLogic();
      case 'skater_jump':
        return SkaterJumpLogic();
      case 'burpee':
        return BurpeeLogic();
      default:
        return PushUpLogic();
    }
  }
}
