import 'package:eschool_saas_staff/data/models/academic/subject.dart';
import 'package:eschool_saas_staff/data/models/auth/userDetails.dart';

class SubjectTeacher {
  final int? id;
  final int? classSectionId;
  final int? subjectId;
  final int? teacherId;
  final int? classSubjectId;
  final int? schoolId;
  final String? deletedAt;
  final String? subjectWithName;
  final Subject? subject;
  final UserDetails? teacher;

  SubjectTeacher({
    this.id,
    this.subject,
    this.teacher,
    this.classSectionId,
    this.subjectId,
    this.teacherId,
    this.classSubjectId,
    this.schoolId,
    this.deletedAt,
    this.subjectWithName,
  });

  SubjectTeacher copyWith(
      {int? id,
      int? classSectionId,
      int? subjectId,
      int? teacherId,
      int? classSubjectId,
      int? schoolId,
      String? deletedAt,
      String? subjectWithName,
      Subject? subject,
      UserDetails? teacher}) {
    return SubjectTeacher(
      subject: subject ?? this.subject,
      teacher: teacher ?? this.teacher,
      id: id ?? this.id,
      classSectionId: classSectionId ?? this.classSectionId,
      subjectId: subjectId ?? this.subjectId,
      teacherId: teacherId ?? this.teacherId,
      classSubjectId: classSubjectId ?? this.classSubjectId,
      schoolId: schoolId ?? this.schoolId,
      deletedAt: deletedAt ?? this.deletedAt,
      subjectWithName: subjectWithName ?? this.subjectWithName,
    );
  }

  SubjectTeacher.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int?,
        classSectionId = json['class_section_id'] as int?,
        subjectId = json['subject_id'] as int?,
        teacherId = json['teacher_id'] as int?,
        classSubjectId = json['class_subject_id'] as int?,
        schoolId = json['school_id'] as int?,
        deletedAt = json['deleted_at'] as String?,
        subject = json['subject'] != null
            ? Subject.fromJson(Map.from(json['subject']))
            : (json['subject_teachers'] is Map && json['subject_teachers']['subject'] != null
                ? Subject.fromJson(Map.from(json['subject_teachers']['subject']))
                : (json['subject_teachers'] is List && (json['subject_teachers'] as List).isNotEmpty && (json['subject_teachers'] as List).first['subject'] != null
                    ? Subject.fromJson(Map.from((json['subject_teachers'] as List).first['subject']))
                    : (json['subject_teacher'] is Map && json['subject_teacher']['subject'] != null
                        ? Subject.fromJson(Map.from(json['subject_teacher']['subject']))
                        : (json.containsKey('name') ? Subject.fromJson(json) : null)))),
        teacher = json['teacher'] != null
            ? UserDetails.fromJson(Map.from(json['teacher']))
            : (json['subject_teachers'] is Map && json['subject_teachers']['teacher'] != null
                ? UserDetails.fromJson(Map.from(json['subject_teachers']['teacher']))
                : (json['subject_teachers'] is List && (json['subject_teachers'] as List).isNotEmpty && (json['subject_teachers'] as List).first['teacher'] != null
                    ? UserDetails.fromJson(Map.from((json['subject_teachers'] as List).first['teacher']))
                    : (json['subject_teacher'] is Map && json['subject_teacher']['teacher'] != null
                        ? UserDetails.fromJson(Map.from(json['subject_teacher']['teacher']))
                        : (json.containsKey('first_name') ? UserDetails.fromJson(json) : null)))),
        subjectWithName = json['subject_with_name'] as String?;

  Map<String, dynamic> toJson() => {
        'id': id,
        'class_section_id': classSectionId,
        'subject_id': subjectId,
        'teacher_id': teacherId,
        'class_subject_id': classSubjectId,
        'school_id': schoolId,
        'deleted_at': deletedAt,
        'subject_with_name': subjectWithName,
        'subject': subject?.toJson(),
        'teacher': teacher?.toJson()
      };
}
