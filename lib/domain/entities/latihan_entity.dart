class LatihanEntity {
  const LatihanEntity({
    required this.latihanId,
    required this.namaLatihan,
    required this.kategoriLatihan,
    required this.deskripsi,
    required this.targetRepetisi,
    required this.targetDurasi,
    required this.targetLatihan,
    required this.isActive,
  });

  final String latihanId;
  final String namaLatihan;
  final String kategoriLatihan;
  final String deskripsi;
  final int targetRepetisi;
  final int targetDurasi;
  final String targetLatihan;
  final bool isActive;
}
