import 'dart:io';
import 'package:dio/dio.dart';
import 'package:eschool_saas_staff/data/models/academic/studyMaterial.dart';
import 'package:eschool_saas_staff/data/repositories/academics/studyMaterialRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';

abstract class DownloadFileState {}

class DownloadFileInitial extends DownloadFileState {}

class DownloadFileInProgress extends DownloadFileState {
  final double uploadedPercentage;

  DownloadFileInProgress(this.uploadedPercentage);
}

class DownloadFileSuccess extends DownloadFileState {
  final String downloadedFileUrl;

  DownloadFileSuccess(this.downloadedFileUrl);
}

class DownloadFileProcessCanceled extends DownloadFileState {}

class DownloadFileFailure extends DownloadFileState {
  final String errorMessage;

  DownloadFileFailure(this.errorMessage);
}

class DownloadFileCubit extends Cubit<DownloadFileState> {
  final StudyMaterialRepository _studyMaterialRepository =
      StudyMaterialRepository();
  final CancelToken _cancelToken = CancelToken();

  DownloadFileCubit() : super(DownloadFileInitial());

  void _downloadedFilePercentage(double percentage) {
    emit(DownloadFileInProgress(percentage));
  }

  Future<void> downloadFile({
    required StudyMaterial studyMaterial,
  }) async {
    emit(DownloadFileInProgress(0.0));
    try {
      // Check permissions
      if (!await Utils.hasStoragePermissionGiven()) {
        throw Exception("Izin penyimpanan diperlukan untuk mengunduh berkas");
      }

      // Simpan file sementara
      final Directory tempDir = await getTemporaryDirectory();
      final tempFileSavePath =
          "${tempDir.path}/${studyMaterial.fileName}.${studyMaterial.fileExtension}";

      if (await File(tempFileSavePath).exists()) {
        debugPrint("File temp sudah ada: $tempFileSavePath");
        final fileSize = await File(tempFileSavePath).length();
        if (fileSize > 0) {
          String downloadFilePath = await Utils.getPublicDownloadsDirectory();

          downloadFilePath =
              "$downloadFilePath/${studyMaterial.fileName}.${studyMaterial.fileExtension}";

          await writeFileFromTempStorage(
            sourcePath: tempFileSavePath,
            destinationPath: downloadFilePath,
          );

          emit(DownloadFileSuccess(downloadFilePath));
          return;
        } else {
          debugPrint("File temp kosong, menghapus dan mengunduh ulang");
          await File(tempFileSavePath).delete();
        }
      }

      debugPrint("Mulai mengunduh file dari: ${studyMaterial.fileUrl}");
      await _studyMaterialRepository.downloadStudyMaterialFile(
        cancelToken: _cancelToken,
        savePath: tempFileSavePath,
        updateDownloadedPercentage: _downloadedFilePercentage,
        url: studyMaterial.fileUrl,
      );

      // Selalu simpan ke memori eksternal untuk Android
      String downloadFilePath = await Utils.getPublicDownloadsDirectory();

      downloadFilePath =
          "$downloadFilePath/${studyMaterial.fileName}.${studyMaterial.fileExtension}";

      await writeFileFromTempStorage(
        sourcePath: tempFileSavePath,
        destinationPath: downloadFilePath,
      );

      emit(DownloadFileSuccess(downloadFilePath));
    } catch (e) {
      if (_cancelToken.isCancelled) {
        debugPrint("Proses unduhan dibatalkan");
        emit(DownloadFileProcessCanceled());
      } else {
        debugPrint("Error saat mengunduh file: $e");
        emit(DownloadFileFailure(e.toString())); // Gunakan pesan error spesifik
      }
    }
  }

  Future<void> writeFileFromTempStorage({
    required String sourcePath,
    required String destinationPath,
  }) async {
    try {
      final tempFile = File(sourcePath);
      if (!await tempFile.exists()) {
        throw Exception("File sementara tidak ditemukan di: $sourcePath");
      }
      debugPrint("File temp ditemukan, ukuran: ${await tempFile.length()} bytes");

      final byteData = await tempFile.readAsBytes();
      final downloadedFile = File(destinationPath);

      final directory = downloadedFile.parent;
      if (!await directory.exists()) {
        await directory.create(recursive: true);
        debugPrint("Direktori tujuan dibuat: ${directory.path}");
      }

      await downloadedFile.writeAsBytes(
        byteData.buffer
            .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
      );
      debugPrint("File berhasil ditulis ke: $destinationPath");
    } catch (e) {
      debugPrint("Error saat menulis file dari temp: $e");
      rethrow;
    }
  }

  void cancelDownloadProcess() {
    debugPrint("Membatalkan proses unduhan");
    _cancelToken.cancel();
  }

  Future<int> _getAndroidVersion() async {
    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      return androidInfo.version.sdkInt;
    } catch (e) {
      debugPrint("Gagal mendapatkan versi Android: $e");
      return 0;
    }
  }
}

// class StudyMaterialRepository {
//   final Dio _dio = Dio();

//   Future<void> downloadStudyMaterialFile({
//     required String url,
//     required String savePath,
//     required Function(double) updateDownloadedPercentage,
//     required CancelToken cancelToken,
//   }) async {
//     int attempts = 0;
//     const maxAttempts = 3;

//     while (attempts < maxAttempts) {
//       try {
//         debugPrint("Mencoba mengunduh dari $url (Percobaan ${attempts + 1}/$maxAttempts)");
//         await _dio.download(
//           url,
//           savePath,
//           cancelToken: cancelToken,
//           onReceiveProgress: (received, total) {
//             if (total != -1) {
//               updateDownloadedPercentage((received / total) * 100);
//             }
//           },
//         );
//         debugPrint("Unduhan berhasil ke: $savePath");
//         break;
//       } catch (e) {
//         attempts++;
//         if (attempts == maxAttempts) {
//           debugPrint("Gagal setelah $maxAttempts percobaan: $e");
//           rethrow;
//         }
//         debugPrint("Gagal mengunduh, mencoba lagi setelah 1 detik: $e");
//         await Future.delayed(const Duration(seconds: 1));
//       }
//     }
//   }
// }
