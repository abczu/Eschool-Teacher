import 'package:eschool_saas_staff/data/models/academic/classSection.dart';
import 'package:eschool_saas_staff/data/models/auth/guardian.dart';

class Student {
  final int? id;
  final int? userId;
  final int? classSectionId;
  final String? admissionNo;
  final String? nis;
  final String? nisn;
  final int? rollNumber;
  final String? admissionDate;
  final int? schoolId;
  final int? guardianId;
  final int? sessionYearId;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;
  final String? firstName;
  final String? lastName;
  final String? fullName;
  final Guardian? guardian;
  final ClassSection? classSection;

  Student({
    this.id,
    this.guardian,
    this.userId,
    this.classSectionId,
    this.admissionNo,
    this.nis,
    this.nisn,
    this.rollNumber,
    this.admissionDate,
    this.schoolId,
    this.guardianId,
    this.sessionYearId,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.firstName,
    this.lastName,
    this.fullName,
    this.classSection,
  });

  Student copyWith(
      {int? id,
      int? userId,
      int? classSectionId,
      String? admissionNo,
      String? nis,
      String? nisn,
      int? rollNumber,
      String? admissionDate,
      int? schoolId,
      int? guardianId,
      int? sessionYearId,
      String? createdAt,
      String? updatedAt,
      String? deletedAt,
      String? firstName,
      String? lastName,
      String? fullName,
      Guardian? guardian}) {
    return Student(
      guardian: guardian ?? this.guardian,
      id: id ?? this.id,
      userId: userId ?? this.userId,
      classSectionId: classSectionId ?? this.classSectionId,
      admissionNo: admissionNo ?? this.admissionNo,
      nis: nis ?? this.nis,
      nisn: nisn ?? this.nisn,
      rollNumber: rollNumber ?? this.rollNumber,
      admissionDate: admissionDate ?? this.admissionDate,
      schoolId: schoolId ?? this.schoolId,
      guardianId: guardianId ?? this.guardianId,
      sessionYearId: sessionYearId ?? this.sessionYearId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      fullName: fullName ?? this.fullName,
    );
  }

  Student.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int?,
        userId = json['user_id'] as int?,
        classSectionId = json['class_section_id'] as int?,
        admissionNo = json['admission_no']?.toString(),
        nis = json['nis']?.toString(),
        nisn = json['nisn']?.toString(),
        rollNumber = json['roll_number'] as int?,
        admissionDate = json['admission_date'] as String?,
        schoolId = json['school_id'] as int?,
        guardianId = json['guardian_id'] as int?,
        sessionYearId = json['session_year_id'] as int?,
        createdAt = json['created_at'] as String?,
        updatedAt = json['updated_at'] as String?,
        deletedAt = json['deleted_at'] as String?,
        firstName = json['first_name'] as String?,
        lastName = json['last_name'] as String?,
        classSection = ClassSection.fromJson(Map.from(json['class_section']?? {})),
        guardian = Guardian.fromJson(Map.from(json['guardian'] ?? {})),
        fullName = json['full_name'] as String?;

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'class_section_id': classSectionId,
        'admission_no': admissionNo,
        'nis': nis,
        'nisn': nisn,
        'roll_number': rollNumber,
        'admission_date': admissionDate,
        'school_id': schoolId,
        'guardian_id': guardianId,
        'session_year_id': sessionYearId,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'deleted_at': deletedAt,
        'first_name': firstName,
        'last_name': lastName,
        'full_name': fullName,
        'guardian': guardian?.toJson()
      };
}
