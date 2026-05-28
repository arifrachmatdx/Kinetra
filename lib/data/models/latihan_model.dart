import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kinetra/domain/entities/latihan_entity.dart';

class LatihanModel {
  LatihanModel({
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

  factory LatihanModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return LatihanModel(
      latihanId: data['latihanId'] as String? ?? doc.id,
      namaLatihan: data['namaLatihan'] as String? ?? '',
      kategoriLatihan: data['kategoriLatihan'] as String? ?? '',
      deskripsi: data['deskripsi'] as String? ?? '',
      targetRepetisi: (data['targetRepetisi'] as num?)?.toInt() ?? 0,
      targetDurasi: (data['targetDurasi'] as num?)?.toInt() ?? 0,
      targetLatihan: data['targetLatihan'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  LatihanEntity toEntity() => LatihanEntity(
        latihanId: latihanId,
        namaLatihan: namaLatihan,
        kategoriLatihan: kategoriLatihan,
        deskripsi: deskripsi,
        targetRepetisi: targetRepetisi,
        targetDurasi: targetDurasi,
        targetLatihan: targetLatihan,
        isActive: isActive,
      );
}
