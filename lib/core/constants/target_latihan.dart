enum TargetLatihan {
  kebugaran('kebugaran', 'Kebugaran'),
  massaOtot('massaOtot', 'Peningkatan Massa Otot'),
  kelincahan('kelincahan', 'Kelincahan');

  const TargetLatihan(this.value, this.label);
  final String value;
  final String label;

  static TargetLatihan? fromValue(String? value) {
    if (value == null) return null;
    for (final t in TargetLatihan.values) {
      if (t.value == value) return t;
    }
    return null;
  }
}
