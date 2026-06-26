import 'package:eschool_saas_staff/data/models/student/attendanceRanking.dart';
import 'package:eschool_saas_staff/utils/system/api.dart';
import 'package:flutter/foundation.dart';

class AttendanceRankingRepository {
  Future<AttendanceRanking> getAttendanceRankings({int? sessionYearId}) async {
    try {
      debugPrint("--- START ATTENDANCE RANKING REQUEST ---");
      debugPrint("URL: ${Api.getAttendanceRanking}");

      final response = await Api.get(
        url: "${Api.getAttendanceRanking}?all=true",
        useAuthToken: true,
        queryParameters: {
          if (sessionYearId != null) "session_year_id": sessionYearId,
        },
      );

      debugPrint("--- ATTENDANCE RANKING API RESPONSE ---");
      debugPrint("Full Response: $response");

      if (response != null) {
        return AttendanceRanking.fromJson(response);
      }
      
      throw ApiException("Empty response from server");
    } catch (e) {
      debugPrint("!!! ERROR IN ATTENDANCE RANKING REPO !!!");
      debugPrint("Error detail: $e");
      throw ApiException(e.toString());
    }
  }
}
