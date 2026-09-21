import 'package:eschool_saas_staff/data/repositories/violation/violationRepository.dart';
import 'package:eschool_saas_staff/utils/system/errorMessageUtils.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class ExportViolationPdfState {}

class ExportViolationPdfInitial extends ExportViolationPdfState {}

class ExportViolationPdfInProgress extends ExportViolationPdfState {}

class ExportViolationPdfSuccess extends ExportViolationPdfState {
  final String filePath;

  ExportViolationPdfSuccess({required this.filePath});
}

class ExportViolationPdfFailure extends ExportViolationPdfState {
  final String errorMessage;

  ExportViolationPdfFailure(this.errorMessage);
}

class ExportViolationPdfCubit extends Cubit<ExportViolationPdfState> {
  final ViolationRepository _violationRepository = ViolationRepository();

  ExportViolationPdfCubit() : super(ExportViolationPdfInitial());

  Future<void> exportPdf({
    int? classId,
    bool isHomeroom = false,
  }) async {
    try {
      emit(ExportViolationPdfInProgress());

      final hasPermission = await Utils.hasStoragePermissionGiven();
      if (!hasPermission) {
        emit(ExportViolationPdfFailure(
            "Izin akses penyimpanan diperlukan untuk mengunduh laporan PDF."));
        return;
      }

      final filePath = await _violationRepository.downloadViolationPdf(
        classId: classId,
        isHomeroom: isHomeroom,
      );

      emit(ExportViolationPdfSuccess(filePath: filePath));
    } catch (e) {
      emit(ExportViolationPdfFailure(
          ErrorMessageUtils.getReadableErrorMessage(e)));
    }
  }

  void reset() {
    emit(ExportViolationPdfInitial());
  }
}
