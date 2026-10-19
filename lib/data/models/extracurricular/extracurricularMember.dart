import '../../../utils/system/jsonUtils.dart';

class ExtracurricularMember {
  final int? id;
  final int? studentId;
  final String? studentName;
  final String? studentNisn;
  final String? className;
  final int? extracurricularId;
  final String? extracurricularName;
  final String? status; // "0" = pending, "1" = approved, "2" = rejected
  final String? joinDate;
  final String? approvedDate;
  final String? rejectedDate;
  final String? createdAt;
  final String? updatedAt;

  ExtracurricularMember({
    this.id,
    this.studentId,
    this.studentName,
    this.studentNisn,
    this.className,
    this.extracurricularId,
    this.extracurricularName,
    this.status,
    this.joinDate,
    this.approvedDate,
    this.rejectedDate,
    this.createdAt,
    this.updatedAt,
  });

  factory ExtracurricularMember.fromJson(Map<String, dynamic> json) {
    return ExtracurricularMember(
      id: json['id'],
      studentId: json['student_id'],
      // Field teks dibaca lewat readText agar aman kalau backend mengirim
      // angka atau nilai kosong (lihat lib/utils/system/jsonUtils.dart).
      studentName: readText(json, ['student_name']),
      studentNisn: readText(json, ['student_nisn', 'nisn']),
      className: readText(json, ['class_name', 'kelas']), // API: kelas
      extracurricularId: json['extracurricular_id'] ?? json['eskul_id'],
      // API mengirim 'eskul_name'
      extracurricularName:
          readText(json, ['extracurricular_name', 'eskul_name']),
      status: json['status']?.toString(),
      // API mengirim 'from_date'
      joinDate: readText(json, ['join_date', 'from_date']),
      approvedDate: json['approved_date'],
      rejectedDate: json['rejected_date'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'student_name': studentName,
      'student_nisn': studentNisn,
      'class_name': className,
      'extracurricular_id': extracurricularId,
      'extracurricular_name': extracurricularName,
      'status': status,
      'join_date': joinDate,
      'approved_date': approvedDate,
      'rejected_date': rejectedDate,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  // Helper methods for status
  bool get isPending => status == "0";
  bool get isApproved => status == "1";
  bool get isRejected => status == "2";

  String get statusText {
    switch (status) {
      case "0":
        return "Menunggu Persetujuan";
      case "1":
        return "Disetujui";
      case "2":
        return "Ditolak";
      default:
        return "Tidak Diketahui";
    }
  }

  // Copy with method for state updates
  ExtracurricularMember copyWith({
    int? id,
    int? studentId,
    String? studentName,
    String? studentNisn,
    String? className,
    int? extracurricularId,
    String? extracurricularName,
    String? status,
    String? joinDate,
    String? approvedDate,
    String? rejectedDate,
    String? createdAt,
    String? updatedAt,
  }) {
    return ExtracurricularMember(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentNisn: studentNisn ?? this.studentNisn,
      className: className ?? this.className,
      extracurricularId: extracurricularId ?? this.extracurricularId,
      extracurricularName: extracurricularName ?? this.extracurricularName,
      status: status ?? this.status,
      joinDate: joinDate ?? this.joinDate,
      approvedDate: approvedDate ?? this.approvedDate,
      rejectedDate: rejectedDate ?? this.rejectedDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
