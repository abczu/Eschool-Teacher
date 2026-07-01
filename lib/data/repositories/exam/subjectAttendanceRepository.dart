import 'package:eschool_saas_staff/data/models/student/attendanceStudent.dart';
import 'package:eschool_saas_staff/data/models/system/holiday.dart';
import 'package:eschool_saas_staff/utils/system/api.dart';
import 'package:eschool_saas_staff/utils/system/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

class SubjectAttendanceRepository {
  Future<
      ({
        List<AttendanceStudent> attendance,
        bool isHoliday,
        Holiday holidayDetails,
        String? materi,
        String? lampiran,
      })> getAttendance({
    required int classSectionId,
    required String date,
    int? timetableId,
    required int gradeLevelId,
  }) async {
    const scope = 'SubjectAttendanceRepository.getAttendance';
    try {
      AppLogger.info(scope, 'Request start', data: {
        'class_section_id': classSectionId,
        'date': date,
        'timetable_id': timetableId,
        'grade_level_id': gradeLevelId,
      });

      if (timetableId == null) {
        // No timetable available, return empty data
        AppLogger.debug(scope, 'No timetable available, returning empty data');
        return Future.value((
          attendance: <AttendanceStudent>[],
          isHoliday: false,
          holidayDetails: Holiday(),
          materi: null,
          lampiran: null,
        ));
      }

      final result = await Api.get(
        url: Api.getSubjectAttendance,
        useAuthToken: true,
        queryParameters: {
          "class_section_id": classSectionId,
          "date": date,
          "grade_level_id": gradeLevelId,
          if (timetableId != 0) "timetable_id": timetableId,
        },
      );

      if (result['data'] == null) {
        throw ApiException('Data is null');
      }

      // Akses array attendance_student di dalam objek data
      final attendanceData = (result['data'] as List)
          .expand((data) => data['attendance_student'] as List)
          .map((attendanceReport) =>
              AttendanceStudent.fromJson(attendanceReport))
          .toList();

      // Pastikan bahwa lampiran diparsing dengan benar
      final lampiran = (result['data'] as List).isNotEmpty
          ? (result['data'][0]['lampiran'] as String?)
          : null;

      final materi = (result['data'] as List).isNotEmpty
          ? (result['data'][0]['materi'] as String?)
          : null;

      AppLogger.debug(scope, 'Parsed response', data: {
        'attendance_count': attendanceData.length,
        'is_holiday': result['is_holiday'],
        'has_holiday_details': result['holiday'] != null,
        'lampiran': lampiran,
        'materi': materi,
      });
      return (
        attendance: attendanceData,
        isHoliday: result['is_holiday'] as bool,
        holidayDetails: Holiday.fromJson(
          Map.from(result['holiday'] == null
              ? {}
              : (result['holiday'] as List).firstOrNull ?? {}),
        ),
        materi: materi,
        lampiran: lampiran,
      );
    } catch (e, st) {
      AppLogger.error(scope, 'Failed fetching subject attendance',
          data: {
            'class_section_id': classSectionId,
            'date': date,
            'timetable_id': timetableId,
            'grade_level_id': gradeLevelId,
          },
          error: e,
          stack: st);
      throw ApiException(e.toString());
    }
  }

  Future<void> submitSubjectAttendance({
    required int classSectionId,
    required String date,
    required int timetableId,
    required int jumlahJp,
    required String materi,
    required String lampiran,
    required int gradeLevelId,
    required List<Map<String, dynamic>> attendance,
  }) async {
    const scope = 'SubjectAttendanceRepository.submitSubjectAttendance';
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(Api.submitSubjectAttendance),
      );

      // Tambahkan header otentikasi
      request.headers.addAll(Api.headers(useAuthToken: true));

      request.fields['class_section_id'] = classSectionId.toString();
      request.fields['timetable_id'] = timetableId.toString();
      request.fields['date'] = date;
      request.fields['jumlah_jp'] = jumlahJp.toString();
      request.fields['materi'] = materi;
      request.fields['grade_level_id'] = gradeLevelId.toString();

      // Convert attendance list to form data format
      // Some server-side frameworks (like Laravel) expect indices for nested arrays in multipart
      for (int i = 0; i < attendance.length; i++) {
        final studentId = attendance[i]['student_id'].toString();
        final type = attendance[i]['type'].toString();
        
        request.fields['attendance[$i][student_id]'] = studentId;
        request.fields['attendance[$i][type]'] = type;
        
        // Also log exactly what is being added to multipart to verify one last time
        debugPrint('📦 [MULTIPART] attendance[$i][student_id]: $studentId, type: $type');
      }

      if (lampiran.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath(
          'lampiran',
          lampiran,
          filename: basename(lampiran),
        ));
      }

      AppLogger.info(scope, 'Submitting multipart attendance', data: {
        'class_section_id': classSectionId,
        'timetable_id': timetableId,
        'date': date,
        'jumlah_jp': jumlahJp,
        'grade_level_id': gradeLevelId,
        'attendance_items': attendance.length,
        'has_lampiran': lampiran.isNotEmpty,
      });

      final stopwatch = Stopwatch()..start();
      var response = await request.send();
      var responseData = await http.Response.fromStream(response);
      stopwatch.stop();

      AppLogger.info(scope, 'Response received', data: {
        'status_code': response.statusCode,
        'duration_ms': stopwatch.elapsedMilliseconds,
        'body_preview': responseData.body.length > 500
            ? '${responseData.body.substring(0, 500)}...<truncated>'
            : responseData.body,
      });

      if (response.statusCode != 200) {
        throw ApiException(
            'Failed to submit attendance (${response.statusCode})');
      }
    } catch (e, st) {
      AppLogger.error(scope, 'Submit failed',
          data: {
            'class_section_id': classSectionId,
            'timetable_id': timetableId,
            'date': date,
            'jumlah_jp': jumlahJp,
            'grade_level_id': gradeLevelId,
            'attendance_items': attendance.length,
            'has_lampiran': lampiran.isNotEmpty,
          },
          error: e,
          stack: st);
      throw ApiException(e.toString());
    }
  }
}

