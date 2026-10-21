import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:eschool_saas_staff/data/models/violation/studentViolationDetail.dart';
import 'package:eschool_saas_staff/data/models/violation/studentViolationItem.dart';
import 'package:eschool_saas_staff/data/models/violation/violationRoleCheck.dart';
import 'package:eschool_saas_staff/data/models/violation/violationType.dart';
import 'package:eschool_saas_staff/utils/system/api.dart';
import 'package:eschool_saas_staff/utils/system/logger.dart';
import 'package:eschool_saas_staff/utils/system/violationPdfUtils.dart';

class ViolationRepository {
  /// 1. Cek Hak Akses Role Guru (Kesiswaan & Wali Kelas)
  Future<ViolationRoleCheck> checkRoles() async {
    try {
      final response = await Api.get(
        url: Api.teacherViolationRolesCheck,
        useAuthToken: true,
      );

      final data = response['data'] is Map ? response['data'] : response;
      return ViolationRoleCheck.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      AppLogger.error('ViolationRepository.checkRoles', 'Error', error: e);
      rethrow;
    }
  }

  /// 2. Daftar Seluruh Siswa Bermasalah (Khusus Kesiswaan - Poin > 0)
  Future<({List<StudentViolationItem> students, int total, int currentPage, int lastPage})>
      getAllStudentsViolations({
    int? classSectionId, // class_section_id untuk filter per-rombel
    String? sortBy, // highest_points / lowest_points / alphabetical / latest
    String? search,
    int? page,
    int? perPage,
  }) async {
    try {
      final Map<String, dynamic> query = {
        if (classSectionId != null && classSectionId > 0) ...{
          'class_section_id': classSectionId,
          'class_id': classSectionId,
        },
        if (sortBy != null && sortBy.isNotEmpty) 'sort_by': sortBy,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (page != null) 'page': page,
        if (perPage != null) 'per_page': perPage,
      };

      final response = await Api.get(
        url: Api.teacherViolationAllStudents,
        useAuthToken: true,
        queryParameters: query,
      );

      dynamic rawList;
      int total = 0;
      int currentPage = 1;
      int lastPage = 1;

      if (response['data'] is Map) {
        final dataMap = response['data'] as Map;
        rawList = dataMap['data'] ?? dataMap['students'] ?? [];
        total = int.tryParse(dataMap['total']?.toString() ?? '') ?? 0;
        currentPage = int.tryParse(dataMap['current_page']?.toString() ?? '') ?? 1;
        lastPage = int.tryParse(dataMap['last_page']?.toString() ?? '') ?? 1;
      } else if (response['data'] is List) {
        rawList = response['data'];
        total = (rawList as List).length;
      } else {
        rawList = [];
      }

      final List<StudentViolationItem> students = (rawList as List)
          .map((e) => StudentViolationItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      return (
        students: students,
        total: total,
        currentPage: currentPage,
        lastPage: lastPage,
      );
    } catch (e) {
      AppLogger.error('ViolationRepository.getAllStudentsViolations', 'Error', error: e);
      rethrow;
    }
  }

  /// 3. Daftar Siswa Kelas Perwalian (Khusus Wali Kelas)
  Future<List<StudentViolationItem>> getHomeroomStudentsViolations({
    int? classSectionId, // class_section_id untuk filter per-rombel
    String? filter, // all / with_points / clean
    String? sortBy, // attendance_number / alphabetical / highest_points
  }) async {
    try {
      final Map<String, dynamic> query = {
        if (classSectionId != null && classSectionId > 0) ...{
          'class_section_id': classSectionId,
          'class_id': classSectionId,
        },
        if (filter != null && filter.isNotEmpty) 'filter': filter,
        if (sortBy != null && sortBy.isNotEmpty) 'sort_by': sortBy,
      };

      final response = await Api.get(
        url: Api.teacherViolationHomeroomStudents,
        useAuthToken: true,
        queryParameters: query,
      );

      dynamic rawList;
      if (response['data'] is Map) {
        final dataMap = response['data'] as Map;
        rawList = dataMap['data'] ?? dataMap['students'] ?? [];
      } else if (response['data'] is List) {
        rawList = response['data'];
      } else {
        rawList = [];
      }

      return (rawList as List)
          .map((e) => StudentViolationItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      AppLogger.error('ViolationRepository.getHomeroomStudentsViolations', 'Error', error: e);
      rethrow;
    }
  }

  /// 4. Master Data Jenis Pelanggaran (Untuk Dropdown Form)
  Future<List<ViolationType>> getViolationTypes() async {
    try {
      final response = await Api.get(
        url: Api.teacherViolationTypes,
        useAuthToken: true,
      );

      dynamic rawList;
      if (response['data'] is List) {
        rawList = response['data'];
      } else if (response['data'] is Map && response['data']['data'] is List) {
        rawList = response['data']['data'];
      } else if (response['data'] is Map && response['data']['types'] is List) {
        rawList = response['data']['types'];
      } else if (response['data'] is Map && response['data']['violation_types'] is List) {
        rawList = response['data']['violation_types'];
      } else if (response['types'] is List) {
        rawList = response['types'];
      } else if (response['violation_types'] is List) {
        rawList = response['violation_types'];
      } else {
        rawList = [];
      }

      return (rawList as List)
          .map((e) => ViolationType.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      AppLogger.error('ViolationRepository.getViolationTypes', 'Error', error: e);
      rethrow;
    }
  }

  /// 5. Form Input Pelanggaran (Hanya Kesiswaan)
  Future<Map<String, dynamic>> giveViolationPoints({
    required int studentId,
    required int violationTypeId,
    required String incidentDate, // YYYY-MM-DD
    String? notes,
    File? photo,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'student_id': studentId,
        'violation_type_id': violationTypeId,
        'occurred_at': incidentDate,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      };

      if (photo != null) {
        final fileName = photo.path.split(Platform.pathSeparator).last;
        body['photo'] = await MultipartFile.fromFile(
          photo.path,
          filename: fileName,
        );
      }

      final response = await Api.post(
        url: Api.teacherViolationGivePoints,
        body: body,
        useAuthToken: true,
      );

      return response;
    } catch (e) {
      AppLogger.error('ViolationRepository.giveViolationPoints', 'Error', error: e);
      rethrow;
    }
  }

  /// 6. Detail/Ringkasan Pelanggaran Siswa (samakan web).
  /// Strategi: coba alias `teacher/violations/summary?student_id=` dulu
  /// (kontrak web), fallback ke `teacher/violations/student-detail/{id}`
  /// yang sudah live di dev. Keduanya diparsing toleran via
  /// [StudentViolationDetail.fromJson] (wrapper root/data, key alias).
  Future<StudentViolationDetail> getStudentViolationSummary(int studentId) async {
    try {
      final response = await Api.get(
        url: Api.teacherViolationSummary(studentId),
        useAuthToken: true,
      );
      final data = response['data'] is Map ? response['data'] : response;
      return StudentViolationDetail.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      AppLogger.debug('ViolationRepository.getStudentViolationSummary',
          'Fallback ke student-detail', data: {'studentId': studentId});
      final response = await Api.get(
        url: Api.teacherViolationStudentDetail(studentId),
        useAuthToken: true,
      );
      final data = response['data'] is Map ? response['data'] : response;
      return StudentViolationDetail.fromJson(Map<String, dynamic>.from(data));
    }
  }

  /// 6b. Detail Pelanggaran Siswa (kompat: delegasi ke summary+fallback).
  Future<StudentViolationDetail> getStudentViolationDetail(int studentId) async {
    return getStudentViolationSummary(studentId);
  }

  /// 7. Hapus Catatan Pelanggaran (Kesiswaan Only)
  /// Pastikan benar-benar terhapus di backend (bukan hanya di UI lokal).
  /// - Melempar [ApiException] jika backend mengembalikan error / gagal.
  Future<void> deleteViolation(int violationId) async {
    try {
      if (violationId <= 0) {
        throw ApiException('ID pelanggaran tidak valid');
      }
      final response = await Api.delete(
        url: Api.teacherViolationDelete(violationId),
        useAuthToken: true,
      );
      // Backend kadang mengembalikan 200 dengan flag error=true.
      // Anggap gagal jika flag tersebut muncul agar UI tidak mengira sukses.
      if (response['error'] == true) {
        throw ApiException(
          response['message']?.toString() ?? 'Gagal menghapus di server',
        );
      }
      AppLogger.debug('ViolationRepository.deleteViolation', 'Deleted', data: {
        'violationId': violationId,
        'response': response,
      });
    } catch (e) {
      AppLogger.error('ViolationRepository.deleteViolation', 'Error', error: e);
      rethrow;
    }
  }

  /// 8. Ambil berkas PDF rekapitulasi pelanggaran.
  ///
  /// Endpoint baru:
  /// - `teacher/violations/homeroom-pdf` (Wali Kelas)
  /// - `teacher/violations/all-students-pdf` (Kesiswaan)
  ///
  /// Jika endpoint baru belum tersedia (404), fallback ke endpoint lama
  /// `homeroom/export-pdf` / `export-pdf` agar fitur tetap berjalan
  /// sebelum backend production di-deploy.
  Future<({Uint8List bytes, String fileName})> fetchViolationRecapPdf({
    required ViolationPdfRequest request,
  }) async {
    try {
      final primaryUrl = request.isHomeroom
          ? Api.teacherViolationHomeroomPdf
          : Api.teacherViolationAllStudentsPdf;

      Map<String, dynamic> response;
      try {
        response = await Api.get(
          url: primaryUrl,
          useAuthToken: true,
          queryParameters: request.queryParameters,
        );
      } on ApiException catch (e) {
        if (!_isEndpointNotFound(e)) rethrow;

        final legacyUrl = request.isHomeroom
            ? Api.teacherViolationHomeroomExportPdf
            : Api.teacherViolationExportPdf;

        AppLogger.warn(
          'ViolationRepository.fetchViolationRecapPdf',
          'Endpoint baru belum tersedia, memakai endpoint lama',
          data: {
            'primaryUrl': primaryUrl,
            'legacyUrl': legacyUrl,
            'message': e.errorMessage,
          },
        );

        response = await Api.get(
          url: legacyUrl,
          useAuthToken: true,
          queryParameters: request.legacyQueryParameters,
        );
      }

      final bytes = await _extractPdfBytes(response);
      return (bytes: bytes, fileName: request.buildFileName());
    } catch (e) {
      AppLogger.error('ViolationRepository.fetchViolationRecapPdf', 'Error',
          error: e);
      rethrow;
    }
  }

  Future<Uint8List> _extractPdfBytes(Map<String, dynamic> response) async {
    final bytes = await Api.fetchDocumentBytes(response);
    final isPdf = bytes.length >= 4 &&
        bytes[0] == 0x25 && // %
        bytes[1] == 0x50 && // P
        bytes[2] == 0x44 && // D
        bytes[3] == 0x46; // F

    if (!isPdf) {
      throw ApiException(
        'Server tidak mengirimkan berkas PDF yang valid. Silakan coba lagi.',
      );
    }

    return bytes;
  }

  bool _isEndpointNotFound(ApiException error) {
    final message = error.errorMessage.toLowerCase();
    return message.contains('tidak ditemukan') ||
        message.contains('not found') ||
        message.contains('404');
  }
}
