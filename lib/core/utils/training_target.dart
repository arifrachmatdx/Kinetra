import 'package:kinetra/core/constants/target_latihan.dart';
import 'package:kinetra/domain/entities/biodata_entity.dart';
import 'package:kinetra/domain/entities/latihan_entity.dart';

class TrainingTarget {
  const TrainingTarget({
    required this.repetisi,
    required this.durasiDetik,
  });

  final int repetisi;
  final int durasiDetik;
}

class TrainingTargetCalculator {
  static TrainingTarget forLatihan({
    required LatihanEntity latihan,
    required BiodataEntity? biodata,
  }) {
    // Base values from Firestore (or local seed).
    var reps = latihan.targetRepetisi;
    var dur = latihan.targetDurasi;

    if (biodata == null) {
      return TrainingTarget(repetisi: reps, durasiDetik: dur);
    }

    final usia = biodata.usia;
    final kind = _kindFromLatihan(latihan);

    final profile = _profile(usia, biodata.targetLatihan);

    // Strength: reps is main target, duration is secondary (rest/tempo).
    // Cardio/Agility: duration is main target, reps is guidance.
    final repsMul = kind == _ExerciseKind.strength
        ? profile.repsMultiplier
        : (profile.repsMultiplier * 0.9);
    final durMul = kind == _ExerciseKind.strength
        ? (profile.durationMultiplier * 0.85)
        : profile.durationMultiplier;

    reps = (reps * repsMul).round().clamp(6, 80);
    dur = (dur * durMul).round().clamp(20, 900);

    return TrainingTarget(repetisi: reps, durasiDetik: dur);
  }

  static _TargetProfile _profile(int usia, TargetLatihan goal) {
    // Age buckets: 17–25, 26–35, 36–45, 46+
    final ageBucket = _AgeBucketX.fromAge(usia);

    // Baseline multipliers per goal & age (reasonable defaults).
    // - kebugaran: moderate reps + more duration
    // - massaOtot: higher reps (strength focus)
    // - kelincahan: moderate reps + duration
    switch (goal) {
      case TargetLatihan.kebugaran:
        return switch (ageBucket) {
          _AgeBucket.a17_25 => const _TargetProfile(1.05, 1.15),
          _AgeBucket.a26_35 => const _TargetProfile(1.00, 1.10),
          _AgeBucket.a36_45 => const _TargetProfile(0.95, 1.00),
          _AgeBucket.a46plus => const _TargetProfile(0.85, 0.90),
        };
      case TargetLatihan.massaOtot:
        return switch (ageBucket) {
          _AgeBucket.a17_25 => const _TargetProfile(1.25, 1.00),
          _AgeBucket.a26_35 => const _TargetProfile(1.20, 0.95),
          _AgeBucket.a36_45 => const _TargetProfile(1.10, 0.90),
          _AgeBucket.a46plus => const _TargetProfile(0.95, 0.85),
        };
      case TargetLatihan.kelincahan:
        return switch (ageBucket) {
          _AgeBucket.a17_25 => const _TargetProfile(1.05, 1.10),
          _AgeBucket.a26_35 => const _TargetProfile(1.00, 1.05),
          _AgeBucket.a36_45 => const _TargetProfile(0.95, 0.95),
          _AgeBucket.a46plus => const _TargetProfile(0.85, 0.85),
        };
    }
  }

  static _ExerciseKind _kindFromLatihan(LatihanEntity latihan) {
    // Prefer explicit mapping by latihanId.
    switch (latihan.latihanId) {
      case 'push_up':
      case 'squat':
      case 'sit_up':
        return _ExerciseKind.strength;
      case 'jumping_jack':
      case 'high_knee':
      case 'mountain_climber':
      case 'burpee':
        return _ExerciseKind.cardio;
      case 'lunge':
      case 'skater_jump':
        return _ExerciseKind.agility;
      default:
        // Fallback by category text.
        final cat = latihan.kategoriLatihan.toLowerCase();
        if (cat.contains('massa')) return _ExerciseKind.strength;
        if (cat.contains('kelincahan')) return _ExerciseKind.agility;
        return _ExerciseKind.cardio;
    }
  }
}

enum _ExerciseKind { strength, cardio, agility }

enum _AgeBucket { a17_25, a26_35, a36_45, a46plus }

class _AgeBucketX {
  static _AgeBucket fromAge(int usia) {
    if (usia <= 25) return _AgeBucket.a17_25;
    if (usia <= 35) return _AgeBucket.a26_35;
    if (usia <= 45) return _AgeBucket.a36_45;
    return _AgeBucket.a46plus;
  }
}

class _TargetProfile {
  const _TargetProfile(this.repsMultiplier, this.durationMultiplier);
  final double repsMultiplier;
  final double durationMultiplier;
}

