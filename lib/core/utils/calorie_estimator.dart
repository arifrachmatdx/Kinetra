/// Estimates calories burned using MET × weight(kg) × hours.
class CalorieEstimator {
  static const defaultWeightKg = 70.0;

  static double estimate({
    required String latihanId,
    required int repetitions,
    required int durationSeconds,
    double weightKg = defaultWeightKg,
  }) {
    final met = _metForExercise(latihanId);
    final hours = durationSeconds / 3600;
    final repBonus = repetitions * 0.3;
    return (met * weightKg * hours) + repBonus;
  }

  static double _metForExercise(String latihanId) {
    switch (latihanId) {
      case 'push_up':
      case 'sit_up':
        return 8.0;
      case 'squat':
        return 6.0;
      case 'burpee':
        return 10.0;
      case 'jumping_jack':
      case 'high_knee':
      case 'mountain_climber':
        return 7.5;
      case 'lunge':
      case 'skater_jump':
        return 7.0;
      default:
        return 6.5;
    }
  }
}
