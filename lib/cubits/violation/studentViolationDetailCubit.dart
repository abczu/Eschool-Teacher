import 'package:eschool_saas_staff/data/models/violation/studentViolationDetail.dart';
import 'package:eschool_saas_staff/data/repositories/violation/violationRepository.dart';
import 'package:eschool_saas_staff/utils/system/errorMessageUtils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class StudentViolationDetailState {}

class StudentViolationDetailInitial extends StudentViolationDetailState {}

class StudentViolationDetailFetchInProgress
    extends StudentViolationDetailState {}

class StudentViolationDetailFetchSuccess extends StudentViolationDetailState {
  final StudentViolationDetail detail;
  final bool isDeleting;
  final int? deletingViolationId;

  StudentViolationDetailFetchSuccess({
    required this.detail,
    this.isDeleting = false,
    this.deletingViolationId,
  });

  StudentViolationDetailFetchSuccess copyWith({
    StudentViolationDetail? detail,
    bool? isDeleting,
    int? deletingViolationId,
  }) {
    return StudentViolationDetailFetchSuccess(
      detail: detail ?? this.detail,
      isDeleting: isDeleting ?? this.isDeleting,
      deletingViolationId: deletingViolationId ?? this.deletingViolationId,
    );
  }
}

class StudentViolationDetailFetchFailure extends StudentViolationDetailState {
  final String errorMessage;

  StudentViolationDetailFetchFailure(this.errorMessage);
}

class StudentViolationDetailCubit extends Cubit<StudentViolationDetailState> {
  final ViolationRepository _violationRepository = ViolationRepository();

  StudentViolationDetailCubit() : super(StudentViolationDetailInitial());

  Future<void> getStudentDetail(int studentId, {bool isRefresh = false}) async {
    try {
      if (!isRefresh) {
        emit(StudentViolationDetailFetchInProgress());
      }
      final result = await _violationRepository.getStudentViolationDetail(studentId);
      emit(StudentViolationDetailFetchSuccess(detail: result));
    } catch (e) {
      emit(StudentViolationDetailFetchFailure(
          ErrorMessageUtils.getReadableErrorMessage(e)));
    }
  }

  Future<bool> deleteViolationItem(int violationId, int studentId) async {
    if (state is! StudentViolationDetailFetchSuccess) return false;
    final currentState = state as StudentViolationDetailFetchSuccess;

    try {
      emit(currentState.copyWith(
        isDeleting: true,
        deletingViolationId: violationId,
      ));

      await _violationRepository.deleteViolation(violationId);

      // Re-fetch detail after successful deletion
      final refreshed = await _violationRepository.getStudentViolationDetail(studentId);
      emit(StudentViolationDetailFetchSuccess(detail: refreshed));
      return true;
    } catch (e) {
      emit(currentState.copyWith(isDeleting: false));
      return false;
    }
  }
}
