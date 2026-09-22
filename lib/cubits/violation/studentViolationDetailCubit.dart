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
  final String? deleteErrorMessage;

  StudentViolationDetailFetchSuccess({
    required this.detail,
    this.isDeleting = false,
    this.deletingViolationId,
    this.deleteErrorMessage,
  });

  StudentViolationDetailFetchSuccess copyWith({
    StudentViolationDetail? detail,
    bool? isDeleting,
    int? deletingViolationId,
    bool clearDeletingViolationId = false,
    String? deleteErrorMessage,
    bool clearDeleteErrorMessage = false,
  }) {
    return StudentViolationDetailFetchSuccess(
      detail: detail ?? this.detail,
      isDeleting: isDeleting ?? this.isDeleting,
      deletingViolationId: clearDeletingViolationId
          ? null
          : (deletingViolationId ?? this.deletingViolationId),
      deleteErrorMessage: clearDeleteErrorMessage
          ? null
          : (deleteErrorMessage ?? this.deleteErrorMessage),
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

  /// Hapus 1 catatan pelanggaran.
  /// Alur dijamin sinkron backend:
  /// 1. Validasi ID.
  /// 2. DELETE ke backend ([ViolationRepository.deleteViolation]).
  ///    Jika gagal (throw) -> TIDAK ada perubahan lokal, kembalikan false.
  /// 3. Re-fetch detail dari backend sebagai sumber kebenaran tunggal.
  /// 4. Verifikasi ID sudah hilang di data backend. Jika masih ada -> gagal.
  /// Mengembalikan true hanya jika benar-benar terhapus di backend.
  Future<bool> deleteViolationItem(int violationId, int studentId) async {
    if (state is! StudentViolationDetailFetchSuccess) return false;
    final currentState = state as StudentViolationDetailFetchSuccess;

    if (violationId <= 0) {
      emit(currentState.copyWith(
        isDeleting: false,
        clearDeletingViolationId: true,
        deleteErrorMessage: 'ID pelanggaran tidak valid',
      ));
      return false;
    }

    try {
      emit(currentState.copyWith(
        isDeleting: true,
        deletingViolationId: violationId,
        clearDeleteErrorMessage: true,
      ));

      // 1. Hapus di backend — throw jika gagal, jadi tidak lanjut ke langkah lokal.
      await _violationRepository.deleteViolation(violationId);

      // 2. Re-fetch dari backend (single source of truth, bukan hapus lokal saja).
      final refreshed =
          await _violationRepository.getStudentViolationDetail(studentId);

      // 3. Verifikasi benar-benar hilang di backend.
      final stillExists =
          refreshed.violations.any((e) => e.id == violationId);
      if (stillExists) {
        emit(currentState.copyWith(
          isDeleting: false,
          clearDeletingViolationId: true,
          deleteErrorMessage:
              'Data masih ada di server. Penghapusan backend gagal.',
        ));
        return false;
      }

      emit(StudentViolationDetailFetchSuccess(detail: refreshed));
      return true;
    } catch (e) {
      emit(currentState.copyWith(
        isDeleting: false,
        clearDeletingViolationId: true,
        deleteErrorMessage: ErrorMessageUtils.getReadableErrorMessage(e),
      ));
      return false;
    }
  }
}
