import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kinetra/core/constants/target_latihan.dart';
import 'package:kinetra/domain/entities/biodata_entity.dart';

class BiodataModel {
  BiodataModel({
    required this.biodataId,
    required this.userId,
    required this.jenisKelamin,
    required this.usia,
    required this.targetLatihan,
    required this.updatedAt,
  });

  final String biodataId;
  final String userId;
  final String jenisKelamin;
  final int usia;
  final String targetLatihan;
  final DateTime updatedAt;

  factory BiodataModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    final ts = data['updatedAt'];
    return BiodataModel(
      biodataId: data['biodataId'] as String? ?? doc.id,
      userId: data['userId'] as String? ?? '',
      jenisKelamin: data['jenisKelamin'] as String? ?? '',
      usia: (data['usia'] as num?)?.toInt() ?? 0,
      targetLatihan: data['targetLatihan'] as String? ?? '',
      updatedAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'biodataId': biodataId,
        'userId': userId,
        'jenisKelamin': jenisKelamin,
        'usia': usia,
        'targetLatihan': targetLatihan,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  BiodataEntity toEntity() => BiodataEntity(
        biodataId: biodataId,
        userId: userId,
        jenisKelamin: jenisKelamin,
        usia: usia,
        targetLatihan:
            TargetLatihan.fromValue(targetLatihan) ?? TargetLatihan.kebugaran,
        updatedAt: updatedAt,
      );
}
