import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eschool_saas_staff/data/repositories/extracurricular/extracurricularAttendanceRepository.dart';
import 'package:eschool_saas_staff/data/models/extracurricular/extracurricularAttendance.dart';
import 'extracurricularAttendanceState.dart';
import 'package:flutter/foundation.dart';

class ExtracurricularAttendanceCubit
    extends Cubit<ExtracurricularAttendanceState> {
  final ExtracurricularAttendanceRepository _repository;

  ExtracurricularAttendanceCubit(this._repository)
      : super(ExtracurricularAttendanceInitial());

  // Get attendance data for a specific session/timetable
  Future<void> getAttendanceData({
    required int attendanceId,
    int? extracurricularId,
    String? date,
    bool silent = false,
  }) async {
    try {
      // Reload setelah simpan memakai silent agar daftar siswa tidak
      // berkedip menjadi spinner.
      if (!silent) emit(ExtracurricularAttendanceLoading());

      debugPrint(
          '🔍 [ATTENDANCE CUBIT] Getting attendance data for ID: $attendanceId');

      final attendanceData = await _repository.getExtracurricularAttendance(
        attendanceId: attendanceId,
        extracurricularId: extracurricularId,
        date: date,
      );

      debugPrint(
          '🔍 [ATTENDANCE CUBIT] Received ${attendanceData.members.length} members');

      emit(ExtracurricularAttendanceSuccess(
        message: 'Data absensi berhasil dimuat',
        attendanceData: attendanceData,
      ));
    } catch (e) {
      debugPrint('❌ [ATTENDANCE CUBIT] Error getting attendance: $e');
      emit(ExtracurricularAttendanceFailure(e.toString()));
    }
  }

  // Get extracurricular list for filter/dropdown
  Future<void> getExtracurricularList() async {
    try {
      debugPrint('🔍 [ATTENDANCE CUBIT] Starting to get extracurricular list');
      emit(ExtracurricularAttendanceLoading());

      final extracurricularList = await _repository.getExtracurricularList();

      debugPrint(
          '🔍 [ATTENDANCE CUBIT] Received ${extracurricularList.length} extracurriculars');
      debugPrint('🔍 [ATTENDANCE CUBIT] List content: $extracurricularList');

      emit(ExtracurricularAttendanceSuccess(
        message: 'Daftar ekstrakurikuler berhasil dimuat',
        extracurricularList: extracurricularList,
      ));

      debugPrint(
          '✅ [ATTENDANCE CUBIT] Successfully emitted success state with extracurricular list');
    } catch (e) {
      debugPrint('❌ [ATTENDANCE CUBIT] Error getting extracurricular list: $e');
      emit(ExtracurricularAttendanceFailure(e.toString()));
    }
  }

  // Save attendance data
  Future<void> saveAttendance({
    required int sessionId,
    required int extracurricularId,
    required String date,
    required List<AttendanceData> attendanceData,
  }) async {
    try {
      emit(ExtracurricularAttendanceSaveLoading());

      debugPrint('💾 [ATTENDANCE CUBIT] Saving attendance for session: $sessionId');
      debugPrint(
          '💾 [ATTENDANCE CUBIT] Attendance data count: ${attendanceData.length}');

      final request = ExtracurricularAttendanceRequest(
        extracurricularId: extracurricularId,
        date: date,
        attendanceData: attendanceData,
      );

      final response = await _repository.saveExtracurricularAttendance(
        sessionId: sessionId,
        request: request,
      );

      debugPrint(
          '✅ [ATTENDANCE CUBIT] Successfully saved ${response.savedCount} records');

      emit(ExtracurricularAttendanceSaveSuccess(
        message: response.message,
        savedCount: response.savedCount,
      ));
    } catch (e) {
      debugPrint('❌ [ATTENDANCE CUBIT] Error saving attendance: $e');
      emit(ExtracurricularAttendanceSaveFailure(e.toString()));
    }
  }

  // Get attendance history
  Future<void> getAttendanceHistory({
    required int extracurricularId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      emit(ExtracurricularAttendanceLoading());

      debugPrint(
          '🔍 [ATTENDANCE CUBIT] Getting attendance history for extracurricular: $extracurricularId');

      final attendanceHistory = await _repository.getAttendanceHistory(
        extracurricularId: extracurricularId,
        startDate: startDate,
        endDate: endDate,
      );

      debugPrint(
          '🔍 [ATTENDANCE CUBIT] Received ${attendanceHistory.length} attendance records');

      // Convert to response format for consistency
      final response = ExtracurricularAttendanceResponse(
        extracurricularId: extracurricularId,
        date: _repository.formatDateForApi(DateTime.now()),
        members: attendanceHistory,
      );

      emit(ExtracurricularAttendanceSuccess(
        message: 'Riwayat absensi berhasil dimuat',
        attendanceData: response,
      ));
    } catch (e) {
      debugPrint('❌ [ATTENDANCE CUBIT] Error getting attendance history: $e');
      emit(ExtracurricularAttendanceFailure(e.toString()));
    }
  }

  // Reset state to initial
  void resetState() {
    emit(ExtracurricularAttendanceInitial());
  }

  // Clear any error or success state
  void clearState() {
    emit(ExtracurricularAttendanceInitial());
  }

  // Helper method to format date for API
  String formatDateForApi(DateTime date) {
    return _repository.formatDateForApi(date);
  }

  // Helper method to parse date from API
  DateTime? parseDateFromApi(String? dateString) {
    return _repository.parseDateFromApi(dateString);
  }

  // Get staff info (if needed for session ID)
  Future<Map<String, dynamic>> getStaffInfo() async {
    try {
      return await _repository.getStaffInfo();
    } catch (e) {
      debugPrint('❌ [ATTENDANCE CUBIT] Error getting staff info: $e');
      rethrow;
    }
  }
}
