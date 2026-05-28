class WorkoutSession {
  const WorkoutSession({
    required this.sesiId,
    required this.latihanId,
    required this.namaLatihan,
    required this.repetitions,
    required this.durationSeconds,
    required this.feedbackAkhir,
    required this.kaloriEstimasi,
  });

  final String sesiId;
  final String latihanId;
  final String namaLatihan;
  final int repetitions;
  final int durationSeconds;
  final String feedbackAkhir;
  final double kaloriEstimasi;
}
