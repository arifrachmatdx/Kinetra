class RiwayatEntity {
  const RiwayatEntity({
    required this.riwayatId,
    required this.userId,
    required this.sesiId,
    required this.tanggalLatihan,
    required this.namaLatihan,
    required this.hasilRepetisi,
    required this.durasiLatihan,
    this.kaloriEstimasi,
    this.feedbackAkhir,
  });

  final String riwayatId;
  final String userId;
  final String sesiId;
  final DateTime tanggalLatihan;
  final String namaLatihan;
  final int hasilRepetisi;
  final int durasiLatihan;
  final double? kaloriEstimasi;
  final String? feedbackAkhir;
}
