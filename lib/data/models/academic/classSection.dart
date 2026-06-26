import 'package:eschool_saas_staff/data/models/academic/classDetails.dart';
import 'package:eschool_saas_staff/data/models/academic/classTeacher.dart';
import 'package:eschool_saas_staff/data/models/academic/medium.dart';
import 'package:eschool_saas_staff/data/models/academic/section.dart';
import 'package:eschool_saas_staff/data/models/academic/subjectTeacher.dart';

class ClassSection {
  final int? id;
  final int? classId;
  final int? sectionId;
  final int? mediumId;
  final int? schoolId;
  final int? gradeLevelId;
  String? createdAt;
  String? updatedAt;
  final int? pkl;
  final String? name;
  final String? fullName;
  final ClassDetails? classDetails;
  final Section? section;
  final Medium? medium;
  final List<ClassTeacher>? classTeachers;
  final List<SubjectTeacher>? subjectTeachers;
  final int? subjectCount;

  ClassSection(
      {this.id,
      this.classId,
      this.sectionId,
      this.mediumId,
      this.schoolId,
      this.gradeLevelId,
      this.name,
      this.fullName,
      this.pkl,
      this.classDetails,
      this.medium,
      this.section,
      this.classTeachers,
      this.subjectTeachers,
      this.subjectCount});

  ClassSection copyWith(
      {int? id,
      int? classId,
      int? sectionId,
      int? mediumId,
      int? schoolId,
      int? gradeLevelId,
      int? pkl,
      String? name,
      String? fullName,
      Medium? medium,
      ClassDetails? classDetails,
      Section? section,
      List<ClassTeacher>? classTeachers,
      List<SubjectTeacher>? subjectTeachers,
      int? subjectCount}) {
    return ClassSection(
        subjectCount: subjectCount ?? this.subjectCount,
        subjectTeachers: subjectTeachers ?? this.subjectTeachers,
        classTeachers: classTeachers ?? this.classTeachers,
        id: id ?? this.id,
        classId: classId ?? this.classId,
        sectionId: sectionId ?? this.sectionId,
        mediumId: mediumId ?? this.mediumId,
        schoolId: schoolId ?? this.schoolId,
        gradeLevelId: gradeLevelId ?? this.gradeLevelId,
        name: name ?? this.name,
        fullName: fullName ?? this.fullName,
        classDetails: classDetails ?? this.classDetails,
        medium: medium ?? this.medium,
        section: section ?? this.section);
  }

  ClassSection.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int?,
        classId = json['class_id'] as int?,
        sectionId = json['section_id'] as int?,
        mediumId = json['medium_id'] as int?,
        schoolId = json['school_id'] as int?,
        gradeLevelId = json['grade_level_id'] as int?,
        name = json['name'] as String?,
        fullName = json['full_name'] as String?,
        pkl = json['pkl'] as int?,
        classDetails = json['class'] != null
            ? ClassDetails.fromJson(Map.from(json['class']))
            : null,
        medium = json['medium'] != null
            ? Medium.fromJson(Map.from(json['medium']))
            : null,
        section = json['section'] != null
            ? Section.fromJson(Map.from(json['section']))
            : null,
        // Mapping untuk class_teachers
        classTeachers =
            ((json['class_teachers'] ?? json['class_teacher'] ?? []) as List)
                .map((teacher) => ClassTeacher.fromJson(Map.from(teacher)))
                .toList(),
        subjectTeachers = ((json['subject_teachers'] ??
                json['subject_teacher'] ??
                json['class_subject'] ??
                []) as List)
            .map((teacher) => SubjectTeacher.fromJson(Map.from(teacher)))
            .toList(),
        subjectCount = json['class_subject_count'] as int?;

  Map<String, dynamic> toJson() => {
        'id': id,
        'class_id': classId,
        'section_id': sectionId,
        'medium_id': mediumId,
        'school_id': schoolId,
        'grade_level_id': gradeLevelId,
        'name': name,
        'full_name': fullName,
        'pkl': pkl,
        'class': classDetails?.toJson(),
        'medium': medium?.toJson(),
        'section': section?.toJson(),
        'subject_teachers': subjectTeachers?.map((e) => e.toJson()).toList(),
        'class_teachers': classTeachers?.map((e) => e.toJson()).toList(),
        'class_subject_count': subjectCount
      };

  String get nama => "$name $fullName".trim();

  @override
  bool operator ==(covariant ClassSection other) {
    return other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }

  @override
  String toString() {
    return (fullName ?? "");
  }

  String getClassTeacherNames() {
    return (classTeachers?.isEmpty ?? true)
        ? "-"
        : (classTeachers!
            .map((e) => e.teacher?.firstName)
            .where((name) => name != null && name.isNotEmpty)
            .toList()
            .join(","));
  }
}
