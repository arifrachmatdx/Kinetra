class DurationFormatter {
  static String mmSs(Duration duration) {
    final m = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
