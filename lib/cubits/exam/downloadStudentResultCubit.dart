import 'dart:convert';
import 'dart:io';

import 'package:eschool_saas_staff/data/repositories/exam/examRepository.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';

abstract class DownloadStudentResultState {}

class DownloadStudentResultInitial extends DownloadStudentResultState {}

class DownloadStudentResultInProgress extends DownloadStudentResultState {}

class DownloadStudentResultSuccess extends DownloadStudentResultState {
  final String downloadedFilePath;

  DownloadStudentResultSuccess({required this.downloadedFilePath});
}

class DownloadStudentResultFailure extends DownloadStudentResultState {
  final String errorMessage;

  DownloadStudentResultFailure(this.errorMessage);
}

class DownloadStudentResultCubit extends Cubit<DownloadStudentResultState> {
  final ExamRepository _examRepository = ExamRepository();

  DownloadStudentResultCubit() : super(DownloadStudentResultInitial());

  void downloadStudentResult(
      {required int childId, required int examId}) async {
    try {
      emit(DownloadStudentResultInProgress());

      // Check permissions
      if (!await Utils.hasStoragePermissionGiven()) {
        throw Exception("Izin penyimpanan diperlukan untuk mengunduh berkas");
      }

      final directoryPath = await Utils.getPublicDownloadsDirectory();
      final String filePath = "$directoryPath/Results/$childId-$examId.pdf";

      final File file = File(filePath);

      final receiptContent = await _examRepository.downloadResult(
          studentId: childId, examId: examId);
      await file.create(recursive: true);

      // Clean the base64 string - remove any potential headers or whitespace
      String cleanedBase64 = receiptContent.trim();
      if (cleanedBase64.startsWith('data:application/pdf;base64,')) {
        cleanedBase64 =
            cleanedBase64.substring('data:application/pdf;base64,'.length);
      } else if (cleanedBase64.startsWith('data:')) {
        final commaIndex = cleanedBase64.indexOf(',');
        if (commaIndex != -1) {
          cleanedBase64 = cleanedBase64.substring(commaIndex + 1);
        }
      }
      cleanedBase64 = cleanedBase64.replaceAll(RegExp(r'\s+'), '');

      await file.writeAsBytes(base64Decode(cleanedBase64));
      emit(DownloadStudentResultSuccess(downloadedFilePath: filePath));
    } catch (e) {
      emit(DownloadStudentResultFailure(defaultErrorMessageKey));
    }
  }
}
