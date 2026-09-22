import 'dart:io';
import 'package:dio/dio.dart';
import 'package:eschool_saas_staff/data/models/violation/studentViolationDetail.dart';
import 'package:eschool_saas_staff/data/models/violation/studentViolationItem.dart';
import 'package:eschool_saas_staff/data/models/violation/violationRoleCheck.dart';
import 'package:eschool_saas_staff/data/models/violation/violationType.dart';
import 'package:eschool_saas_staff/utils/system/api.dart';
import 'package:eschool_saas_staff/utils/system/logger.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';

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

  /// 6. Detail Pelanggaran Siswa
  Future<StudentViolationDetail> getStudentViolationDetail(int studentId) async {
    try {
      final response = await Api.get(
        url: Api.teacherViolationStudentDetail(studentId),
        useAuthToken: true,
      );

      final data = response['data'] is Map ? response['data'] : response;
      return StudentViolationDetail.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      AppLogger.error('ViolationRepository.getStudentViolationDetail', 'Error', error: e);
      rethrow;
    }
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

  /// 8. Download PDF Rekapitulasi Pelanggaran
  Future<String> downloadViolationPdf({
    int? classId,
    bool isHomeroom = false,
  }) async {
    try {
      final url = isHomeroom
          ? Api.teacherViolationHomeroomExportPdf
          : Api.teacherViolationExportPdf;

      final Map<String, dynamic> query = {
        if (classId != null && classId > 0) 'class_id': classId,
      };

      final response = await Api.get(
        url: url,
        useAuthToken: true,
        queryParameters: query,
      );

      final bytes = await Api.fetchDocumentBytes(response);

      final directoryPath = await Utils.getPublicDownloadsDirectory();
      final prefix = isHomeroom ? 'rekap_kelas' : 'rekap_sekolah';
      final fileName =
          "${prefix}_pelanggaran_${DateTime.now().millisecondsSinceEpoch}.pdf";
      final filePath = "$directoryPath/Violations/$fileName";

      final file = File(filePath);
      await file.create(recursive: true);
      await file.writeAsBytes(bytes);

      return filePath;
    } catch (e) {
      AppLogger.error('ViolationRepository.downloadViolationPdf', 'Error', error: e);
      rethrow;
    }
  }
}
