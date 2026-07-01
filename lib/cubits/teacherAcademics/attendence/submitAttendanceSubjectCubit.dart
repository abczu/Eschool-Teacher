import 'package:eschool_saas_staff/data/repositories/exam/subjectAttendanceRepository.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/errorMessageUtils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

abstract class SubmitAttendanceSubjectState {}

class SubmitAttendanceSubjectInitial extends SubmitAttendanceSubjectState {}

class SubmitAttendanceSubjectInProgress extends SubmitAttendanceSubjectState {}

class SubmitAttendanceSubjectSuccess extends SubmitAttendanceSubjectState {}

class SubmitAttendanceSubjectFailure extends SubmitAttendanceSubjectState {
  final String errorMessage;

  SubmitAttendanceSubjectFailure(this.errorMessage);
}

class SubmitAttendanceSubjectCubit extends Cubit<SubmitAttendanceSubjectState> {
  final SubjectAttendanceRepository _subjectAttendanceRepository =
      SubjectAttendanceRepository();

  SubmitAttendanceSubjectCubit() : super(SubmitAttendanceSubjectInitial());

  Future<void> submitSubjectAttendance({
    required DateTime date,
    required int classSectionId,
    required int timetableId,
    required int jumlahJp,
    required String materi,
    required String lampiran,
    required int gradeLevelId,
    required List<({StudentAttendanceStatus status, int studentId})>
        attendanceReport,
  }) async {
    emit(SubmitAttendanceSubjectInProgress());
    try {
      debugPrint('🚀 [SUBMIT_ATTENDANCE] Starting submission process');
      debugPrint('   📅 Date: ${date.year}-${date.month}-${date.day}');
      debugPrint('   🏫 Class: $classSectionId, Timetable: $timetableId');
      
      final attendanceList = attendanceReport.map(
        (attendanceReport) {
          final mappedType = _mapAttendanceStatusToType(attendanceReport.status);
          debugPrint('   👤 Student ${attendanceReport.studentId}: ${attendanceReport.status} -> Type $mappedType');

          return {
            "student_id": attendanceReport.studentId,
            "type": mappedType,
          };
        },
      ).toList();

      await _subjectAttendanceRepository.submitSubjectAttendance(
        classSectionId: classSectionId,
        date: "${date.year}-${date.month}-${date.day}",
        timetableId: timetableId,
        jumlahJp: jumlahJp,
        materi: materi,
        lampiran: lampiran,
        gradeLevelId: gradeLevelId,
        attendance: attendanceList,
      );
      emit(SubmitAttendanceSubjectSuccess());
    } catch (e) {
      debugPrint("Error during attendance submission: $e");
      final userFriendlyMessage = ErrorMessageUtils.getReadableErrorMessage(e);
      emit(SubmitAttendanceSubjectFailure(userFriendlyMessage));
      debugPrint(
          'Technical error: ${ErrorMessageUtils.getTechnicalErrorMessage(e)}');
    }
  }

  int _mapAttendanceStatusToType(StudentAttendanceStatus status) {
    switch (status) {
      case StudentAttendanceStatus.present:
        return 1;
      case StudentAttendanceStatus.absent:
        return 4;
      case StudentAttendanceStatus.sick:
        return 2;
      case StudentAttendanceStatus.permission:
        return 3;
      case StudentAttendanceStatus.alpa:
        return 4;
      // default removed
      // return 0 removed
    }
  }
}
