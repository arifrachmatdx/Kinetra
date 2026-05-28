import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kinetra/domain/entities/riwayat_entity.dart';

class RiwayatModel {
  RiwayatModel({
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

  factory RiwayatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    final ts = data['tanggalLatihan'];
    return RiwayatModel(
      riwayatId: data['riwayatId'] as String? ?? doc.id,
      userId: data['userId'] as String? ?? '',
      sesiId: data['sesiId'] as String? ?? '',
      tanggalLatihan: ts is Timestamp ? ts.toDate() : DateTime.now(),
      namaLatihan: data['namaLatihan'] as String? ?? '',
      hasilRepetisi: (data['hasilRepetisi'] as num?)?.toInt() ?? 0,
      durasiLatihan: (data['durasiLatihan'] as num?)?.toInt() ?? 0,
      kaloriEstimasi: (data['kaloriEstimasi'] as num?)?.toDouble(),
      feedbackAkhir: data['feedbackAkhir'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'riwayatId': riwayatId,
        'userId': userId,
        'sesiId': sesiId,
        'tanggalLatihan': Timestamp.fromDate(tanggalLatihan),
        'namaLatihan': namaLatihan,
        'hasilRepetisi': hasilRepetisi,
        'durasiLatihan': durasiLatihan,
        if (kaloriEstimasi != null) 'kaloriEstimasi': kaloriEstimasi,
        if (feedbackAkhir != null) 'feedbackAkhir': feedbackAkhir,
      };

  RiwayatEntity toEntity() => RiwayatEntity(
        riwayatId: riwayatId,
        userId: userId,
        sesiId: sesiId,
        tanggalLatihan: tanggalLatihan,
        namaLatihan: namaLatihan,
        hasilRepetisi: hasilRepetisi,
        durasiLatihan: durasiLatihan,
        kaloriEstimasi: kaloriEstimasi,
        feedbackAkhir: feedbackAkhir,
      );
}
