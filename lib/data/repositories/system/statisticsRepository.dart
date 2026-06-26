import 'package:eschool_saas_staff/utils/system/api.dart';
import 'package:flutter/foundation.dart';

class StatisticsRepository {
  Future<
      ({
        int totalStudents,
        int totalStaffs,
        int totalTeachers,
        int totalLeaveRequests
      })> getSystemStatistics() async {
    try {
      final result = await Api.get(url: Api.getSystemStatistics);

      if (kDebugMode) {
        debugPrint(result.toString());
      }

      final data = (result['data'] is Map) ? result['data'] : result;

      // Fungsi pembantu untuk mengambil nilai dari berbagai kemungkinan kunci
      int getValue(List<String> keys) {
        if (data is! Map) return 0;
        
        // Cek di level utama
        for (var key in keys) {
          if (data.containsKey(key) && data[key] != null) {
            return int.tryParse(data[key].toString()) ?? 0;
          }
        }
        
        // Cek jika ada nested 'counter' (pola umum di beberapa API)
        if (data.containsKey('counter') && data['counter'] is Map) {
          final counter = data['counter'] as Map;
          for (var key in keys) {
            if (counter.containsKey(key) && counter[key] != null) {
              return int.tryParse(counter[key].toString()) ?? 0;
            }
          }
        }
        
        return 0;
      }

      return (
        totalStudents: getValue(['students', 'total_students', 'student_count', 'siswa', 'total_siswa', 'student']),
        totalStaffs: getValue(['staffs', 'total_staffs', 'staff', 'staff_count', 'staf', 'total_staf']),
        totalTeachers: getValue(['teachers', 'total_teachers', 'teacher_count', 'guru', 'total_guru', 'teacher']),
        totalLeaveRequests:
            getValue(['leaves', 'total_leaves', 'total_leave_requests', 'leave_requests', 'cuti', 'total_cuti', 'permintaan_cuti']),
      );
    } catch (e) {
      throw ApiException(e.toString());
    }
  }
}
