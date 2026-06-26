import 'dart:convert';
import 'dart:io';

import 'package:eschool_saas_staff/data/repositories/payroll/payRollRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/foundation.dart';

abstract class DownloadPayRollSlipState {}

class DownloadPayRollSlipInitial extends DownloadPayRollSlipState {}

class DownloadPayRollSlipInProgress extends DownloadPayRollSlipState {}

class DownloadPayRollSlipSuccess extends DownloadPayRollSlipState {
  final String downloadedFilePath;

  DownloadPayRollSlipSuccess({required this.downloadedFilePath});
}

class DownloadPayRollSlipFailure extends DownloadPayRollSlipState {
  final String errorMessage;

  DownloadPayRollSlipFailure(this.errorMessage);
}

class DownloadPayRollSlipCubit extends Cubit<DownloadPayRollSlipState> {
  final PayRollRepository _payRollRepository = PayRollRepository();

  DownloadPayRollSlipCubit() : super(DownloadPayRollSlipInitial());

  void downloadPayRollSlip(
      {required int payRollId, required String payRollSlipTitle}) async {
    try {
      emit(DownloadPayRollSlipInProgress());

      debugPrint("=== DOWNLOAD PAYROLL PROCESS STARTED ===");
      debugPrint("Payroll ID: $payRollId");
      debugPrint("Payroll Title: $payRollSlipTitle");

      String filePath = "";
      final path = await Utils.getSharableDirectory();
      filePath = "$path/Salary-Slips/$payRollSlipTitle-$payRollId.pdf";

      debugPrint("Target file path: $filePath");

      final File file = File(filePath);

      debugPrint("Requesting slip content from repository...");
      final slipContent =
          await _payRollRepository.downloadPayRollSlip(payRollId: payRollId);

      debugPrint("Slip content received. Base64 data length: ${slipContent.length}");

      // Validate the content is not empty
      if (slipContent.isEmpty) {
        throw Exception("Received empty PDF content from server");
      }

      try {
        // Try standard approach first
        await _downloadWithStandardApproach(file, slipContent);
        debugPrint("Standard approach successful!");
      } catch (standardError) {
        debugPrint("Standard approach failed: $standardError");
        debugPrint("Trying alternative strategies...");

        try {
          await _downloadWithAlternativeStrategies(
              payRollId, payRollSlipTitle, filePath);
          debugPrint("Alternative strategy successful!");
        } catch (alternativeError) {
          debugPrint("All strategies failed. Error: $alternativeError");
          throw Exception("Gagal memproses file PDF. Format data tidak valid.");
        }
      }

      // Verify file was written correctly
      if (!await file.exists() || await file.length() == 0) {
        throw Exception("File PDF gagal disimpan dengan benar");
      }

      debugPrint("File successfully written to: $filePath");
      emit(DownloadPayRollSlipSuccess(downloadedFilePath: filePath));
    } catch (e) {
      debugPrint("=== DOWNLOAD PAYROLL ERROR ===");
      debugPrint("Error: ${e.toString()}");

      String errorMessage = "Gagal mengunduh slip gaji";
      if (e.toString().contains("format") || e.toString().contains("decode")) {
        errorMessage += ": Format file tidak valid";
      } else if (e.toString().contains("network") ||
          e.toString().contains("connection")) {
        errorMessage += ": Masalah koneksi internet";
      } else if (e.toString().contains("permission")) {
        errorMessage += ": Tidak ada izin akses file";
      } else {
        errorMessage += ": ${e.toString()}";
      }

      emit(DownloadPayRollSlipFailure(errorMessage));
    }
  }

  // Standard approach method
  Future<void> _downloadWithStandardApproach(
      File file, String slipContent) async {
    // Clean the base64 string - remove any potential headers or whitespace
    String cleanedBase64 = slipContent.trim();

    // Remove common base64 data URL prefixes if present
    if (cleanedBase64.startsWith('data:application/pdf;base64,')) {
      cleanedBase64 =
          cleanedBase64.substring('data:application/pdf;base64,'.length);
    } else if (cleanedBase64.startsWith('data:')) {
      // Remove any other data URL prefix
      final commaIndex = cleanedBase64.indexOf(',');
      if (commaIndex != -1) {
        cleanedBase64 = cleanedBase64.substring(commaIndex + 1);
      }
    }

    // Remove any remaining whitespace or newlines
    cleanedBase64 = cleanedBase64.replaceAll(RegExp(r'\s+'), '');

    debugPrint("Cleaned base64 data length: ${cleanedBase64.length}");

    // Validate base64 format
    if (!_isValidBase64(cleanedBase64)) {
      throw Exception("Invalid base64 format received from server");
    }

    await file.create(recursive: true);
    final bytes = base64Decode(cleanedBase64);
    debugPrint("Successfully decoded base64 data. Size: ${bytes.length} bytes");

    // Validate PDF header
    if (bytes.length < 5 || !_isPdfFile(bytes)) {
      throw Exception("Decoded data is not a valid PDF file");
    }

    await file.writeAsBytes(bytes);
  }

  // Alternative download method with multiple decoding strategies
  Future<void> _downloadWithAlternativeStrategies(
      int payRollId, String payRollSlipTitle, String filePath) async {
    final File file = File(filePath);
    final slipContent =
        await _payRollRepository.downloadPayRollSlip(payRollId: payRollId);

    debugPrint("Trying alternative decoding strategies for PDF...");

    // Strategy 1: Direct base64 decode (current approach)
    try {
      debugPrint("Strategy 1: Direct base64 decode");
      final bytes = base64Decode(slipContent.trim());
      if (_isPdfFile(bytes)) {
        await file.create(recursive: true);
        await file.writeAsBytes(bytes);
        debugPrint("Strategy 1 successful!");
        return;
      }
    } catch (e) {
      debugPrint("Strategy 1 failed: $e");
    }

    // Strategy 2: Decode with padding fix
    try {
      debugPrint("Strategy 2: Base64 decode with padding fix");
      String paddedContent = slipContent.trim();
      while (paddedContent.length % 4 != 0) {
        paddedContent += '=';
      }
      final bytes = base64Decode(paddedContent);
      if (_isPdfFile(bytes)) {
        await file.create(recursive: true);
        await file.writeAsBytes(bytes);
        debugPrint("Strategy 2 successful!");
        return;
      }
    } catch (e) {
      debugPrint("Strategy 2 failed: $e");
    }

    // Strategy 3: URL decode then base64 decode
    try {
      debugPrint("Strategy 3: URL decode then base64 decode");
      final urlDecoded = Uri.decodeComponent(slipContent);
      final bytes = base64Decode(urlDecoded.trim());
      if (_isPdfFile(bytes)) {
        await file.create(recursive: true);
        await file.writeAsBytes(bytes);
        debugPrint("Strategy 3 successful!");
        return;
      }
    } catch (e) {
      debugPrint("Strategy 3 failed: $e");
    }

    // Strategy 4: Assume raw bytes (not base64 encoded)
    try {
      debugPrint("Strategy 4: Treat as raw bytes");
      final bytes = slipContent.codeUnits;
      if (_isPdfFile(bytes)) {
        await file.create(recursive: true);
        await file.writeAsBytes(bytes);
        debugPrint("Strategy 4 successful!");
        return;
      }
    } catch (e) {
      debugPrint("Strategy 4 failed: $e");
    }

    throw Exception(
        "All decoding strategies failed. The PDF data format is not recognized.");
  }

  // Helper method to validate base64 format
  bool _isValidBase64(String str) {
    try {
      // Base64 string length should be divisible by 4
      if (str.length % 4 != 0) return false;

      // Base64 regex pattern
      final base64Pattern = RegExp(r'^[A-Za-z0-9+/]*={0,2}$');
      return base64Pattern.hasMatch(str);
    } catch (e) {
      return false;
    }
  }

  // Helper method to check if bytes represent a PDF file
  bool _isPdfFile(List<int> bytes) {
    if (bytes.length < 5) return false;

    // Check for PDF header (%PDF-)
    final header = String.fromCharCodes(bytes.take(5));
    return header == '%PDF-';
  }
}
