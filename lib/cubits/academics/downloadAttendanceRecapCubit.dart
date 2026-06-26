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

  void downloadRecap({required String url, required String fileName}) async {
    try {
      emit(DownloadAttendanceRecapInProgress());

      final directory = await getApplicationDocumentsDirectory();
      final String savePath = "${directory.path}/$fileName.pdf";
      
      final dio = Dio();
      final response = await dio.get(
        url,
        options: Options(
          headers: Api.headers(useAuthToken: true),
          responseType: ResponseType.bytes, // Ambil raw bytes agar bisa dicek
        ),
      );

      // Cek apakah ini beneran PDF atau malah halaman error HTML
      final contentType = response.headers.value('content-type') ?? '';
      if (!contentType.contains('application/pdf')) {
        // Jika bukan PDF, berarti ini halaman error. Kita coba baca pesannya.
        final errorMsg = String.fromCharCodes(response.data);
        if (errorMsg.contains("Terjadi kesalahan")) {
           throw Exception("Server masih error: Terjadi kesalahan saat memproses data.");
        }
        throw Exception("Server tidak mengirimkan file PDF (Content-Type: $contentType)");
      }

      final File file = File(savePath);
      await file.writeAsBytes(response.data);

      if (await file.exists() && await file.length() > 0) {
        emit(DownloadAttendanceRecapSuccess(downloadedFilePath: savePath));
      } else {
        throw Exception("File gagal disimpan");
      }
    } catch (e) {
      emit(DownloadAttendanceRecapFailure(e.toString()));
    }
  }
}
