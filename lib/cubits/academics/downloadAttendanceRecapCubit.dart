import 'dart:io';
import 'package:dio/dio.dart';
import 'package:eschool_saas_staff/utils/system/api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:path_provider/path_provider.dart';

abstract class DownloadAttendanceRecapState {}

class DownloadAttendanceRecapInitial extends DownloadAttendanceRecapState {}

class DownloadAttendanceRecapInProgress extends DownloadAttendanceRecapState {}

class DownloadAttendanceRecapSuccess extends DownloadAttendanceRecapState {
  final String downloadedFilePath;
  DownloadAttendanceRecapSuccess({required this.downloadedFilePath});
}

class DownloadAttendanceRecapFailure extends DownloadAttendanceRecapState {
  final String errorMessage;
  DownloadAttendanceRecapFailure(this.errorMessage);
}

class DownloadAttendanceRecapCubit extends Cubit<DownloadAttendanceRecapState> {
  DownloadAttendanceRecapCubit() : super(DownloadAttendanceRecapInitial());

  /// Memastikan URL /recap-download selalu membawa `download=true` sehingga
  /// backend mengembalikan stream binary PDF (application/pdf),
  /// bukan halaman HTML preview.
  String _ensureDownloadParam(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    if (!uri.path.contains('recap-download')) return url;
    final params = Map<String, String>.from(uri.queryParameters);
    final dl = (params['download'] ?? '').toLowerCase();
    if (dl == 'true' || dl == '1') return url;
    params['download'] = 'true';
    return uri.replace(queryParameters: params).toString();
  }

  void downloadRecap({
    required String url,
    required String fileName,
    bool isPreview = false,
  }) async {
    try {
      emit(DownloadAttendanceRecapInProgress());

      String savePath;
      if (isPreview) {
        // Untuk preview: simpan di temporary directory (cache), tidak masuk ke penyimpanan file publik
        final tempDir = await getTemporaryDirectory();
        savePath = "${tempDir.path}/$fileName.pdf";
      } else {
        // Untuk download: cek izin dan simpan di folder Download publik
        if (!await Utils.hasStoragePermissionGiven()) {
          throw Exception("Izin penyimpanan diperlukan untuk mengunduh berkas");
        }
        final directoryPath = await Utils.getPublicDownloadsDirectory();
        savePath = "$directoryPath/$fileName.pdf";
      }

      // Wajib: endpoint tanpa download=true membalas HTML, bukan PDF.
      final effectiveUrl = _ensureDownloadParam(url);

      final dio = Dio();
      final requestHeaders = Api.headers(useAuthToken: true)
        // Minta PDF secara eksplisit; jangan paksa Accept: application/json
        ..['Accept'] = 'application/pdf, */*';
      final response = await dio.get(
        effectiveUrl,
        options: Options(
          headers: requestHeaders,
          responseType: ResponseType.bytes, // Ambil raw bytes agar bisa dicek
          followRedirects: true,
        ),
      );

      // Cek apakah ini beneran PDF atau malah halaman error HTML
      final contentType = response.headers.value('content-type') ?? '';
      final List<int> dataBytes = response.data is List<int>
          ? response.data as List<int>
          : (response.data is String
              ? (response.data as String).codeUnits
              : []);

      final bool isPdfMagicBytes = dataBytes.length >= 4 &&
          dataBytes[0] == 0x25 &&
          dataBytes[1] == 0x50 &&
          dataBytes[2] == 0x44 &&
          dataBytes[3] == 0x46; // %PDF

      if (!contentType.contains('application/pdf') && !isPdfMagicBytes) {
        final errorMsg = dataBytes.length > 4096
            ? String.fromCharCodes(dataBytes.sublist(0, 4096))
            : String.fromCharCodes(dataBytes);
        final lowered = errorMsg.toLowerCase();
        if (lowered.contains("terjadi kesalahan")) {
          throw Exception(
              "Server masih error: Terjadi kesalahan saat memproses data.");
        }
        if (lowered.contains("unauthenticated") ||
            lowered.contains("sesi habis") ||
            lowered.contains("token") && lowered.contains("login") ||
            lowered.contains("silakan login")) {
          throw Exception(
              "Sesi habis / token tidak valid. Silakan login ulang lalu coba unduh lagi.");
        }
        if (lowered.contains("kelas tidak ditemukan") ||
            lowered.contains("class not found")) {
          throw Exception(
              "Kelas tidak ditemukan di server. Periksa kelas/bulan yang dipilih.");
        }
        if (errorMsg.contains("<html") ||
            errorMsg.contains("<!DOCTYPE html>")) {
          throw Exception(
              "Gagal memuat PDF: server mengembalikan halaman web (kemungkinan tanpa download=true atau sesi kedaluwarsa). Buka via Review/WebView atau login ulang.");
        }
        throw Exception(
            "Server tidak mengirimkan file PDF (Content-Type: $contentType)");
      }

      final File file = File(savePath);
      await file.writeAsBytes(dataBytes);

      if (await file.exists() && await file.length() > 0) {
        emit(DownloadAttendanceRecapSuccess(downloadedFilePath: savePath));
      } else {
        throw Exception("File gagal disimpan");
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        emit(DownloadAttendanceRecapFailure(
            "Autentikasi gagal (401). Server menolak sesi/token login Anda untuk unduh rekap."));
      } else if (e.response?.statusCode == 403) {
        emit(DownloadAttendanceRecapFailure(
            "Anda tidak memiliki izin (403) untuk mengakses rekap absensi ini."));
      } else if (e.response?.statusCode == 404) {
        emit(DownloadAttendanceRecapFailure(
            "Data atau file rekap tidak ditemukan di server (404)."));
      } else if (e.response?.statusCode == 500) {
        emit(DownloadAttendanceRecapFailure(
            "Terjadi kesalahan pada server (500) saat mengunduh rekap."));
      } else {
        emit(DownloadAttendanceRecapFailure(
            e.message ?? "Gagal terhubung ke server saat mengunduh rekap."));
      }
    } catch (e) {
      emit(DownloadAttendanceRecapFailure(e.toString()));
    }
  }
}

