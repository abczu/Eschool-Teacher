import 'package:eschool_saas_staff/data/models/academic/classSection.dart';
import 'package:eschool_saas_staff/data/models/academic/classTimetableSlot.dart';
import 'package:eschool_saas_staff/data/models/academic/medium.dart';
import 'package:eschool_saas_staff/data/models/auth/role.dart';
import 'package:eschool_saas_staff/data/models/academic/sessionYear.dart';
import 'package:eschool_saas_staff/data/models/academic/teacherSubject.dart';
import 'package:eschool_saas_staff/utils/system/api.dart';
import 'package:flutter/foundation.dart';

class AcademicRepository {
  Future<({List<ClassSection> classes, List<ClassSection> primaryClasses})>
      getClasses({bool? modeAll, int? gradeLevelId}) async {
    try {
      debugPrint(
          "AcademicRepository: Fetching classes with mode=all parameter");

      Map<String, dynamic> queryParameters = {};
      if (modeAll == true) {
        queryParameters["mode"] = "all";
      }
      if (gradeLevelId != null) {
        queryParameters["grade_level_id"] = gradeLevelId;
      }

      final result = await Api.get(
        url: Api.getClasses,
        queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
      );
      debugPrint("AcademicRepository: Raw API response received");

      // Mapping untuk other classes (tetap dipertahankan)
      final otherClasses = ((result['other'] ?? []) as List)
          .map((classDetails) =>
              ClassSection.fromJson(Map.from(classDetails ?? {})))
          .toList();

      // Perbaikan mapping untuk class_teacher
      final classTeacherList = ((result['class_teacher'] ?? []) as List);
      final primaryClasses = classTeacherList
          .where((classTeacher) =>
              classTeacher != null && classTeacher['class_section'] != null)
          .map((classTeacher) {
        // Gabungkan data class_section dengan class_teachers
        final classSection =
            Map<String, dynamic>.from(classTeacher['class_section']);
        classSection['class_teachers'] = [
          {
            'id': classTeacher['id'],
            'class_section_id': classTeacher['class_section_id'],
            'teacher_id': classTeacher['teacher_id'],
            'school_id': classTeacher['school_id'],
            'class_id': classTeacher['class_id'],
            'teacher': {
              // Tambahkan data teacher lengkap
              'id': classTeacher['teacher_id'],
              'first_name': classTeacher['teacher']?['first_name'],
              'last_name': classTeacher['teacher']?['last_name'],
              'full_name': classTeacher['teacher']?['full_name'],
            }
          }
        ];
        return ClassSection.fromJson(classSection);
      }).toList();

      debugPrint(
          "Primary Classes (Wali Kelas): ${primaryClasses.map((e) => e.name)}");
      debugPrint("Other Classes: ${otherClasses.map((e) => e.name)}");
      debugPrint(
          "AcademicRepository: Total classes loaded - Primary: ${primaryClasses.length}, Other: ${otherClasses.length}");

      return (classes: otherClasses, primaryClasses: primaryClasses);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<List<ClassSection>> getClassesWithTeacherDetails(
      {bool? modeAll}) async {
    try {
      final result = await Api.post(
        url: Api.getClassesWithTeacherDetails,
        body: {if (modeAll == true) "mode": "all"},
      );
      debugPrint("resultnya");
      debugPrint(result.toString());
      return ((result['data'] ?? []) as List)
          .map((classDetails) =>
              ClassSection.fromJson(Map.from(classDetails ?? {})))
          .toList();
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<List<SessionYear>> getSessionYears() async {
    try {
      final result = await Api.get(url: Api.getSessionYears);
      return ((result['data'] ?? []) as List)
          .map((sessionYear) =>
              SessionYear.fromJson(Map.from(sessionYear ?? {})))
          .toList();
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<List<Medium>> getMediums() async {
    try {
      final result = await Api.get(url: Api.getMediums);
      return ((result['data'] ?? []) as List)
          .map((medium) => Medium.fromJson(Map.from(medium ?? {})))
          .toList();
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<List<TeacherSubject>> getClassSectionSubjects(
      {required int classSectionId}) async {
    try {
      final result = await Api.get(
          url: Api.getSubjects,
          queryParameters: {"class_section_id": classSectionId});
      return ((result['data'] ?? []) as List)
          .map((teacherSubject) =>
              TeacherSubject.fromJson(Map.from(teacherSubject ?? {})))
          .toList();
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<List<ClassTimeTableSlot>> getClassTimetable(
      {required int classSectionId}) async {
    try {
      final result = await Api.get(
          url: Api.getClassTimetable,
          queryParameters: {"class_section_id": classSectionId});
      return ((result['data'] ?? []) as List)
          .map((classTimetableSlot) =>
              ClassTimeTableSlot.fromJson(Map.from(classTimetableSlot ?? {})))
          .toList();
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<List<Role>> getRoles() async {
    try {
      final result = await Api.get(
        url: Api.getRoles,
      );
      return ((result['data'] ?? []) as List)
          .map((role) => Role.fromJson(Map.from(role ?? {})))
          .toList();
    } catch (e) {
      throw ApiException(e.toString());
    }
  }
}
