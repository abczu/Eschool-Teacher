import 'package:eschool_saas_staff/data/models/student/attendanceRanking.dart';
import 'package:eschool_saas_staff/data/repositories/student/attendanceRankingRepository.dart';
import 'package:eschool_saas_staff/utils/system/errorMessageUtils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

abstract class AttendanceRankingState {}

class AttendanceRankingInitial extends AttendanceRankingState {}

class AttendanceRankingInProgress extends AttendanceRankingState {}

class AttendanceRankingFetchSuccess extends AttendanceRankingState {
  final AttendanceRanking attendanceRanking;

  AttendanceRankingFetchSuccess({required this.attendanceRanking});
}

class AttendanceRankingFetchFailure extends AttendanceRankingState {
  final String errorMessage;

  AttendanceRankingFetchFailure(this.errorMessage);
}

class AttendanceRankingCubit extends Cubit<AttendanceRankingState> {
  final AttendanceRankingRepository _attendanceRankingRepository =
      AttendanceRankingRepository();

  AttendanceRankingCubit() : super(AttendanceRankingInitial());

  void getAttendanceRanking({int? sessionYearId, int retryCount = 3}) async {
    try {
      emit(AttendanceRankingInProgress());
      final result = await _attendanceRankingRepository.getAttendanceRankings(
        sessionYearId: sessionYearId,
      );
      emit(AttendanceRankingFetchSuccess(attendanceRanking: result));
    } catch (e) {
      if (retryCount > 0) {
        // Tunggu sebentar sebelum retry
        await Future.delayed(const Duration(seconds: 2));
        getAttendanceRanking(retryCount: retryCount - 1);
      } else {
        final userFriendlyMessage =
            ErrorMessageUtils.getReadableErrorMessage(e);
        emit(AttendanceRankingFetchFailure(userFriendlyMessage));
        debugPrint(
            'Technical error: ${ErrorMessageUtils.getTechnicalErrorMessage(e)}');
      }
    }
  }
}

