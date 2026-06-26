import 'package:eschool_saas_staff/data/models/academic/classSection.dart';
import 'package:eschool_saas_staff/data/models/academic/timeTableSlot.dart';
import 'package:eschool_saas_staff/utils/system/api.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

class TeacherAcademicsRepository {
  Future<List<TimeTableSlot>> getTeacherMyTimetable({String? dayKey}) async {
    try {
      debugPrint("--- START TIMETABLE REQUEST ---");
      debugPrint("Day Parameter from Cubit: ${dayKey ?? 'ALL'}");

      String? fullDayName;
      if (dayKey != null && dayKey.isNotEmpty && dayKey != 'all') {
        Map<String, String> dayMapping = {
          'mon': 'monday',
          'tue': 'tuesday',
          'wed': 'wednesday',
          'thu': 'thursday',
          'fri': 'friday',
          'sat': 'saturday',
          'sun': 'sunday',
        };
        fullDayName = dayMapping[dayKey.toLowerCase()] ?? dayKey;
      }

      debugPrint("Final Day Parameter sent to API: ${fullDayName ?? 'NONE (Fetching All)'}");

      final response = await Api.get(
        url: fullDayName != null
            ? "${Api.getTeacherMyTimetable}?day=$fullDayName"
            : Api.getTeacherMyTimetable,
        useAuthToken: true,
      );

      debugPrint("--- API DATA RECEIVED ---");
      debugPrint("Type: ${response['data']?.runtimeType}");

      List<TimeTableSlot> timeTableSlots = [];

      if (response['data'] is Map<String, dynamic>) {
        final Map<String, dynamic> data = response['data'];
        data.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            timeTableSlots.add(TimeTableSlot.fromJson(value));
          } else if (value is List) {
            for (var item in value) {
              if (item is Map<String, dynamic>) {
                timeTableSlots.add(TimeTableSlot.fromJson(item));
              }
            }
          }
        });
      } else if (response['data'] is List) {
        final List<dynamic> data = response['data'];
        timeTableSlots = data
            .map((slot) => TimeTableSlot.fromJson(slot as Map<String, dynamic>))
            .toList();
      }

      debugPrint("Total slots parsed: ${timeTableSlots.length}");
      debugPrint("--- END TIMETABLE REQUEST ---");

      return timeTableSlots;
    } catch (e) {
      debugPrint("!!! ERROR IN TIMETABLE REPO !!!");
      debugPrint("Error: $e");
      throw Exception(e.toString());
    }
  }

  Future<List<TimeTableSlot>> getTeacherTimetableByClassSection({
    required int classSectionId,
    required DateTime date,
  }) async {
    try {
      final response = await Api.get(
        url:
            "${Api.getTeacherMyTimetable}?class_section_id=$classSectionId&date=${DateFormat('yyyy-MM-dd').format(date)}",
        useAuthToken: true,
      );

      if (response['data'] is List) {
        final List<dynamic> data = response['data'];
        return data
            .map((slot) => TimeTableSlot.fromJson(slot as Map<String, dynamic>))
            .toList();
      }

      throw Exception("Invalid response format");
    } catch (e) {
      debugPrint("Error in getTeacherTimetableByClassSection: $e");
      throw Exception(e.toString());
    }
  }

  Future<List<ClassSection>> getClassSectionDetails(
      {int? classId, bool? modeAll, int? gradeLevelId}) async {
    try {
      final result = await Api.post(
        url: Api.getClassDetails,
        body: {
          if (classId != null) "class_id": classId,
          if (modeAll == true) "mode": "all",
          if (gradeLevelId != null) "grade_level_id": gradeLevelId,
        },
      );
      return ((result['data'] ?? []) as List)
          .map((classDetails) =>
              ClassSection.fromJson(Map.from(classDetails ?? {})))
          .toList();
    } catch (e) {
      throw ApiException(e.toString());
    }
  }
}
