import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

/// Aksi yang dipilih user saat membuat rekap PDF.
enum ViolationPdfAction {
  /// Tampilkan pratinjau di dalam aplikasi tanpa menyimpan file.
  preview,

  /// Simpan file PDF ke perangkat user.
  download,
}

/// Parameter permintaan rekap pelanggaran yang dikirim ke backend.
class ViolationPdfRequest {
  /// true = rekap kelas perwalian (Wali Kelas).
  /// false = rekap seluruh siswa berpoin (Kesiswaan).
  final bool isHomeroom;
  final int? classSectionId;
  final int? gradeLevelId;

  /// Filter status daftar wali kelas: all / with_points / clean.
  final String? homeroomFilter;

  /// Label cakupan yang dipakai untuk informasi di UI dan nama file.
  final String scopeLabel;

  /// Minta backend menyertakan blok tanda tangan pada PDF.
  final bool includeSignature;

  const ViolationPdfRequest({
    required this.isHomeroom,
    this.classSectionId,
    this.gradeLevelId,
    this.homeroomFilter,
    required this.scopeLabel,
    this.includeSignature = true,
  });

  bool get _hasClass => classSectionId != null && classSectionId! > 0;

  bool get _hasGrade => gradeLevelId != null && gradeLevelId! > 0;

  /// Peran penanda tangan yang dikirim ke backend.
  String get signatureRole =>
      isHomeroom ? 'homeroom_teacher' : 'student_affairs';

  /// Nilai filter yang aman untuk backend. `null` dianggap "all".
  String get _normalizedHomeroomFilter {
    switch ((homeroomFilter ?? 'all').trim().toLowerCase()) {
      case 'with_points':
        return 'with_points';
      case 'clean':
        return 'clean';
      default:
        return 'all';
    }
  }

  /// Query untuk endpoint baru:
  /// - homeroom-pdf: `class_section_id` (id / "all") + `filter` status.
  /// - all-students-pdf: `class_section_id` + `grade_level_id` ("all" default).
  ///
  /// `class_section_id=all` dipakai Wali Kelas multi-kelas agar backend
  /// menggabungkan seluruh kelas perwalian dalam satu laporan.
  Map<String, dynamic> get queryParameters {
    final signatureParameters = <String, dynamic>{
      'include_signature': includeSignature,
      'signature_role': signatureRole,
    };

    if (isHomeroom) {
      return {
        'class_section_id': _hasClass ? classSectionId : 'all',
        'filter': _normalizedHomeroomFilter,
        ...signatureParameters,
      };
    }

    return {
      'class_section_id': _hasClass ? classSectionId : 'all',
      'grade_level_id': _hasGrade ? gradeLevelId : 'all',
      ...signatureParameters,
    };
  }

  /// Query untuk endpoint lama (fallback sebelum backend production siap).
  Map<String, dynamic> get legacyQueryParameters {
    return {
      if (_hasClass) 'class_id': classSectionId,
    };
  }

  /// Kunci pembeda request, dipakai untuk mendeteksi filter yang berubah.
  String get scopeKey =>
      '${isHomeroom ? 'homeroom' : 'all'}_${classSectionId ?? 'all'}_${gradeLevelId ?? 'all'}_${homeroomFilter ?? 'all'}';

  /// Nama file rekap yang aman dipakai di Android/iOS.
  String buildFileName({DateTime? now}) {
    final timestamp = DateFormat('yyyyMMdd_HHmm').format(now ?? DateTime.now());
    return 'Rekap_Pelanggaran_${sanitizePdfSegment(scopeLabel)}_$timestamp.pdf';
  }
}

/// Membersihkan label agar aman dipakai sebagai bagian nama file.
String sanitizePdfSegment(String value) {
  final cleaned = value
      .trim()
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
      .replaceAll(RegExp(r'\s+'), '-')
      .replaceAll(RegExp(r'-{2,}'), '-');
  return cleaned.isEmpty ? 'Sekolah' : cleaned;
}

/// Menentukan apakah tombol rekap PDF boleh tampil.
///
/// [isHomeroomTab] = tab yang aktif adalah "Kelas Saya".
/// [isRoleResolved] = role dari backend sudah berhasil dimuat.
bool canExportViolationPdf({
  required bool isHomeroomTab,
  required bool isHomeroom,
  required bool isKesiswaan,
  required bool isRoleResolved,
}) {
  if (!isRoleResolved) return false;
  return isHomeroomTab ? isHomeroom : isKesiswaan;
}

/// Menyimpan PDF ke perangkat lewat dialog penyimpanan sistem (SAF di Android).
///
/// Mengembalikan path/URI tujuan, atau `null` jika user membatalkan.
Future<String?> saveViolationPdfToDevice({
  required Uint8List bytes,
  required String fileName,
}) async {
  try {
    return await FilePicker.platform.saveFile(
      dialogTitle: 'Simpan Rekap PDF',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      bytes: bytes,
    );
  } catch (_) {
    // Sebagian perangkat (iOS) tidak mendukung allowedExtensions custom.
    try {
      return await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan Rekap PDF',
        fileName: fileName,
        type: FileType.any,
        bytes: bytes,
      );
    } catch (_) {
      return null;
    }
  }
}
