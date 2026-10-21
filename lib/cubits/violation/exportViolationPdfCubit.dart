import 'dart:typed_data';

import 'package:eschool_saas_staff/data/repositories/violation/violationRepository.dart';
import 'package:eschool_saas_staff/utils/system/errorMessageUtils.dart';
import 'package:eschool_saas_staff/utils/system/violationPdfUtils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class ExportViolationPdfState {}

class ExportViolationPdfInitial extends ExportViolationPdfState {}

class ExportViolationPdfInProgress extends ExportViolationPdfState {
  final ViolationPdfAction action;

  ExportViolationPdfInProgress({required this.action});
}

/// Dokumen PDF yang sudah diterima dari backend (di memori).
class ViolationPdfDocument {
  final Uint8List bytes;
  final String fileName;
  final ViolationPdfRequest request;

  const ViolationPdfDocument({
    required this.bytes,
    required this.fileName,
    required this.request,
  });

  int get sizeInBytes => bytes.lengthInBytes;

  String get readableSize {
    const kb = 1024;
    const mb = kb * 1024;

    if (sizeInBytes >= mb) {
      return '${(sizeInBytes / mb).toStringAsFixed(1)} MB';
    }
    if (sizeInBytes >= kb) {
      return '${(sizeInBytes / kb).toStringAsFixed(0)} KB';
    }
    return '$sizeInBytes B';
  }
}

class ExportViolationPdfSuccess extends ExportViolationPdfState {
  final ViolationPdfDocument document;

  ExportViolationPdfSuccess({required this.document});
}

class ExportViolationPdfFailure extends ExportViolationPdfState {
  final String errorMessage;

  ExportViolationPdfFailure(this.errorMessage);
}

class ExportViolationPdfCubit extends Cubit<ExportViolationPdfState> {
  final ViolationRepository _violationRepository = ViolationRepository();

  ExportViolationPdfCubit() : super(ExportViolationPdfInitial());

  /// Membuat rekap PDF. Mengembalikan dokumen jika berhasil,
  /// atau `null` jika gagal (detail error ada di state).
  Future<ViolationPdfDocument?> exportPdf({
    required ViolationPdfRequest request,
    required ViolationPdfAction action,
  }) async {
    try {
      emit(ExportViolationPdfInProgress(action: action));

      final result = await _violationRepository.fetchViolationRecapPdf(
        request: request,
      );

      final document = ViolationPdfDocument(
        bytes: result.bytes,
        fileName: result.fileName,
        request: request,
      );

      if (isClosed) return null;
      emit(ExportViolationPdfSuccess(document: document));
      return document;
    } catch (e) {
      if (isClosed) return null;
      emit(ExportViolationPdfFailure(
        ErrorMessageUtils.getReadableErrorMessage(e),
      ));
      return null;
    }
  }

  void reset() {
    if (!isClosed) emit(ExportViolationPdfInitial());
  }
}
