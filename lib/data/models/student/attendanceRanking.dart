import 'package:flutter/foundation.dart';

class AttendanceRanking {
  final List<GroupedByClassLevel>? groupedByClassLevel;
  final List<AllStudents>? allStudents;

  AttendanceRanking({
    this.groupedByClassLevel,
    this.allStudents,
  });

  factory AttendanceRanking.fromJson(Map<String, dynamic> json) {
    // Determine the root of the data (legacy vs newer wrapped in 'data')
    final Map<String, dynamic> data =
        (json.containsKey('data') && json['data'] is Map)
            ? json['data']
            : json;

    debugPrint("AttendanceRanking.fromJson: Processing data keys: ${data.keys.toList()}");

    return AttendanceRanking(
      groupedByClassLevel: ((data['grouped_by_grade_level'] ??
              data['grouped_by_class_level']) as List<dynamic>?)
          ?.map((e) => GroupedByClassLevel.fromJson(e as Map<String, dynamic>))
          .toList(),
      allStudents: (data['all_students'] as List<dynamic>?)
          ?.map((e) => AllStudents.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class GroupedByClassLevel {
  final String? classLevel;
  final List<TopStudents>? topStudents;

  GroupedByClassLevel({this.classLevel, this.topStudents});

  factory GroupedByClassLevel.fromJson(Map<String, dynamic> json) {
    return GroupedByClassLevel(
      classLevel: (json['grade_level'] ?? json['class_level'])?.toString(),
      topStudents: (json['top_students'] as List<dynamic>?)
          ?.map((e) => TopStudents.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TopStudents {
  final int? rank;
  final String? className;
  final String? studentName;
  final int? studentId;
  final dynamic jumlahJpSum; // Changed from String? to dynamic
  final dynamic point; // Changed from String? to dynamic
  final dynamic alphaCount; // Added for tracking alpha counts

  TopStudents({
    this.rank,
    this.className,
    this.studentName,
    this.studentId,
    this.jumlahJpSum,
    this.point,
    this.alphaCount,
  });
  factory TopStudents.fromJson(Map<String, dynamic> json) {
    // Debug helper to see actual keys if data is missing
    if (json.containsKey('student_name') && !json.containsKey('alpha_count') && !json.containsKey('point')) {
      print("AttendanceRanking Model: Missing alpha/point keys. Available keys: ${json.keys.toList()}");
    }

    return TopStudents(
      rank: json['rank'] as int?,
      className: (json['class'] ?? json['class_name'] ?? json['section_name']) as String?,
      studentName: (json['student_name'] ?? json['name']) as String?,
      studentId: json['student_id'] as int?,
      jumlahJpSum: (json['jumlah_jp_sum'] ?? json['total_jp'] ?? json['jp'])?.toString(),
      point: (json['point'] ?? json['total_point'] ?? json['poin'] ?? json['points'])?.toString(),
      alphaCount: (json['alpha_count'] ?? json['alpha'] ?? json['total_alpha'])?.toString(),
    );
  }
}

class AllStudents {
  final int? studentId;
  final String? studentName;
  final String? classLevel;
  final String? className;
  final dynamic jumlahJpSum; // Changed from String? to dynamic
  final dynamic point; // Changed from String? to dynamic
  final dynamic alphaCount; // Added for tracking alpha counts

  AllStudents({
    this.studentId,
    this.studentName,
    this.classLevel,
    this.className,
    this.jumlahJpSum,
    this.point,
    this.alphaCount,
  });
  factory AllStudents.fromJson(Map<String, dynamic> json) {
    return AllStudents(
      studentId: json['student_id'] as int?,
      studentName: (json['student_name'] ?? json['name']) as String?,
      classLevel: (json['class_level'] ?? json['level']) as String?,
      className: (json['class'] ?? json['class_name'] ?? json['section_name']) as String?,
      jumlahJpSum: (json['jumlah_jp_sum'] ?? json['total_jp'] ?? json['jp'])?.toString(),
      point: (json['point'] ?? json['total_point'] ?? json['poin'] ?? json['points'])?.toString(),
      alphaCount: (json['alpha_count'] ?? json['alpha'] ?? json['total_alpha'])?.toString(),
    );
  }
}
