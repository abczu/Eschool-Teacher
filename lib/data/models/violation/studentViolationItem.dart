import 'package:flutter/foundation.dart';
import 'package:eschool_saas_staff/data/models/violation/studentAvatarHelper.dart';

class StudentViolationItem {
  final int studentId;
  final String studentName;
  final String? nisn;
  final String? admissionNo;
  final int? classId;
  final String? className;
  final int? rollNumber;
  final int totalPoints;
  final String? sanctionName;
  final String? avatarUrl;

  StudentViolationItem({
    required this.studentId,
    required this.studentName,
    this.nisn,
    this.admissionNo,
    this.classId,
    this.className,
    this.rollNumber,
    this.totalPoints = 0,
    this.sanctionName,
    this.avatarUrl,
  });

  /// Returns avatarUrl if present, or looks up from StudentAvatarHelper cache
  String? get displayAvatarUrl =>
      avatarUrl ??
      StudentAvatarHelper.getAvatarUrl(
        studentId: studentId,
        studentName: studentName,
        classId: classId,
      );

  factory StudentViolationItem.fromJson(Map<String, dynamic> json) {
    // Siswa profile bisa berada di json['student'] atau langsung di root
    final studentData = json['student'] is Map ? json['student'] : json;
    final userData = studentData['user'] is Map ? studentData['user'] : studentData;

    final id = int.tryParse(json['student_id']?.toString() ?? '') ??
        int.tryParse(studentData['id']?.toString() ?? '') ??
        int.tryParse(json['id']?.toString() ?? '') ??
        0;

    String name = json['student_name']?.toString() ??
        json['name']?.toString() ??
        studentData['name']?.toString() ??
        userData['name']?.toString() ??
        '';

    if (name.isEmpty) {
      final first = (userData['first_name'] ?? studentData['first_name'] ?? '').toString();
      final last = (userData['last_name'] ?? studentData['last_name'] ?? '').toString();
      name = "$first $last".trim();
    }

    final classSection = studentData['class_section'] ?? json['class_section'];
    String? cName;
    int? cId;
    if (classSection is Map) {
      cName = classSection['full_name']?.toString() ??
          classSection['name']?.toString() ??
          classSection['class_name']?.toString();
      cId = int.tryParse(classSection['id']?.toString() ?? '');
    } else {
      cName = json['class_name']?.toString() ??
          studentData['class_name']?.toString() ??
          json['class_section_name']?.toString();
      cId = int.tryParse(json['class_section_id']?.toString() ?? '') ??
          int.tryParse(studentData['class_section_id']?.toString() ?? '') ??
          int.tryParse(json['class_id']?.toString() ?? '') ??
          int.tryParse(studentData['class_id']?.toString() ?? '');
    }

    final points = int.tryParse(json['total_points']?.toString() ?? '') ??
        int.tryParse(json['points']?.toString() ?? '') ??
        int.tryParse(studentData['total_points']?.toString() ?? '') ??
        0;

    // Parse avatar URL from multiple possible fields
    final resolvedAvatar = (userData['image'] ??
            userData['avatar'] ??
            userData['profileUrl'] ??
            userData['profile_url'] ??
            studentData['image'] ??
            studentData['avatar'] ??
            studentData['profileUrl'] ??
            studentData['profile_url'] ??
            json['image'] ??
            json['photo'] ??
            json['avatar'] ??
            json['profileUrl'] ??
            json['profile_url'])
        ?.toString();

    return StudentViolationItem(
      studentId: id,
      studentName: name,
      nisn: (studentData['nisn'] ?? json['nisn'])?.toString(),
      admissionNo: (studentData['admission_no'] ?? json['admission_no'])?.toString(),
      classId: cId,
      className: cName,
      rollNumber: int.tryParse((studentData['roll_number'] ?? json['roll_number'] ?? json['attendance_number'])?.toString() ?? ''),
      totalPoints: points,
      sanctionName: json['sanction_name']?.toString() ??
          json['status']?.toString() ??
          studentData['sanction_name']?.toString(),
      avatarUrl: resolvedAvatar,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'student_name': studentName,
      'nisn': nisn,
      'admission_no': admissionNo,
      'class_id': classId,
      'class_name': className,
      'roll_number': rollNumber,
      'total_points': totalPoints,
      'sanction_name': sanctionName,
      'avatar_url': avatarUrl,
    };
  }
}
