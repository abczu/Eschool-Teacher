import 'dart:convert';
import 'dart:io';

import 'package:eschool_saas_staff/data/repositories/fee/feeRepository.dart';
import 'package:eschool_saas_staff/utils/system/api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/foundation.dart';

abstract class DownloadStudentFeeReceiptState {}

class DownloadStudentFeeReceiptInitial extends DownloadStudentFeeReceiptState {}

class DownloadStudentFeeReceiptInProgress
    extends DownloadStudentFeeReceiptState {}

class DownloadStudentFeeReceiptSuccess extends DownloadStudentFeeReceiptState {
  final String downloadedFilePath;

  DownloadStudentFeeReceiptSuccess({required this.downloadedFilePath});
}

class DownloadStudentFeeReceiptFailure extends DownloadStudentFeeReceiptState {
  final String errorMessage;

  DownloadStudentFeeReceiptFailure(this.errorMessage);
}

class DownloadStudentFeeReceiptCubit
    extends Cubit<DownloadStudentFeeReceiptState> {
  final FeeRepository _feeRepository = FeeRepository();

  DownloadStudentFeeReceiptCubit() : super(DownloadStudentFeeReceiptInitial());

  void downloadStudentFeeReceipt({
    required List<int> paymentHistoryIds,
    required String studentName,
  }) async {
    try {
      emit(DownloadStudentFeeReceiptInProgress());

      debugPrint('===== STARTING RECEIPT DOWNLOAD PROCESS =====');
      debugPrint('Payment History IDs to process: $paymentHistoryIds');
      debugPrint('Student Name: $studentName');

      // Validate input
      if (paymentHistoryIds.isEmpty) {
        debugPrint('Error: Empty payment history IDs list');
        throw ApiException("No payment records selected");
      }

      // Generate unique filename incorporating timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = await Utils.getSharableDirectory();
      final filePath = "$path/Student-Fees/$studentName-receipt-$timestamp.pdf";
      debugPrint('Target File Path: $filePath');

      // Create directory if it doesn't exist
      final directory = File(filePath).parent;
      if (!await directory.exists()) {
        debugPrint('Creating directory: ${directory.path}');
        await directory.create(recursive: true);
      }

      // Download receipt
      debugPrint('Requesting PDF generation from server...');
      final slipContent = await _feeRepository.downloadStudentFeeReceipt(
        paymentHistoryIds: paymentHistoryIds,
      );

      if (slipContent.isEmpty) {
        debugPrint('Error: Received empty PDF content from server');
        throw ApiException("No receipt data available");
      }

      debugPrint(
          'Successfully received PDF content. Length: ${slipContent.length} bytes');

      try {
        // Clean the base64 string - remove any potential headers or whitespace
        String cleanedBase64 = slipContent.trim();
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

        // Decode base64 to validate it's proper PDF data
        final bytes = base64Decode(cleanedBase64);
        debugPrint('Successfully decoded base64 data. Size: ${bytes.length} bytes');

        // VALIDATION: Check for PDF Magic Bytes (%PDF-)
        if (bytes.length < 4 || 
            bytes[0] != 0x25 || bytes[1] != 0x50 || bytes[2] != 0x44 || bytes[3] != 0x46) {
          debugPrint('ERROR: Decoded data does not start with PDF magic bytes (%PDF-)');
          // Print first 50 bytes for debugging
          final preview = bytes.take(50).toList();
          debugPrint('First 50 bytes: $preview');
          throw ApiException("Data yang diterima bukan format PDF yang valid");
        }

        // Write PDF file
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        debugPrint('Successfully wrote PDF file to: $filePath');

        emit(DownloadStudentFeeReceiptSuccess(downloadedFilePath: filePath));
      } catch (e) {
        debugPrint('Error processing PDF data: $e');
        if (e is ApiException) rethrow;
        throw ApiException("Gagal memproses data struk: ${e.toString()}");
      }
    } catch (e) {
      debugPrint('===== ERROR DOWNLOADING PDF RECEIPT =====');
      debugPrint('Error type: ${e.runtimeType}');
      debugPrint('Error message: ${e.toString()}');

      // Generate appropriate error message based on error type
      String errorMessage;
      if (e is ApiException) {
        if (e.toString().contains("validation.array")) {
          errorMessage = "Format pembayaran tidak valid";
        } else if (e.toString().contains("No payment records")) {
          errorMessage = "Tidak ada riwayat pembayaran";
        } else if (e.toString().contains("Could not determine school")) {
          errorMessage = "Data sekolah tidak ditemukan";
        } else if (e.toString().contains("All payments must be")) {
          errorMessage = "Semua pembayaran harus dari siswa yang sama";
        } else {
          errorMessage = e.toString();
        }
      } else {
        errorMessage = "Terjadi kesalahan saat mengunduh struk";
      }

      emit(DownloadStudentFeeReceiptFailure(errorMessage));
    }
  }
}
