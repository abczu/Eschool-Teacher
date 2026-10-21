import 'package:eschool_saas_staff/data/models/violation/studentViolationItem.dart';
import 'package:eschool_saas_staff/utils/system/violationPdfUtils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ViolationPdfRequest.queryParameters', () {
    test('homeroom tanpa kelas mengirim class_section_id=all', () {
      const request = ViolationPdfRequest(
        isHomeroom: true,
        scopeLabel: 'Kelas Perwalian',
      );

      expect(request.queryParameters, {
        'class_section_id': 'all',
        'filter': 'all',
        'include_signature': true,
        'signature_role': 'homeroom_teacher',
      });
    });

    test('homeroom dengan kelas mengirim id dan filter default', () {
      const request = ViolationPdfRequest(
        isHomeroom: true,
        classSectionId: 12,
        gradeLevelId: 10,
        scopeLabel: 'X RPL A',
      );

      expect(request.queryParameters, {
        'class_section_id': 12,
        'filter': 'all',
        'include_signature': true,
        'signature_role': 'homeroom_teacher',
      });
    });

    test('homeroom dengan filter status mengirim filter', () {
      const request = ViolationPdfRequest(
        isHomeroom: true,
        classSectionId: 12,
        homeroomFilter: 'with_points',
        scopeLabel: 'X RPL A',
      );

      expect(request.queryParameters, {
        'class_section_id': 12,
        'filter': 'with_points',
        'include_signature': true,
        'signature_role': 'homeroom_teacher',
      });
    });

    test('homeroom filter "all" tetap dikirim eksplisit', () {
      const request = ViolationPdfRequest(
        isHomeroom: true,
        classSectionId: 12,
        homeroomFilter: 'all',
        scopeLabel: 'X RPL A',
      );

      expect(request.queryParameters, {
        'class_section_id': 12,
        'filter': 'all',
        'include_signature': true,
        'signature_role': 'homeroom_teacher',
      });
    });

    test('kesiswaan tanpa filter mengirim "all"', () {
      const request = ViolationPdfRequest(
        isHomeroom: false,
        scopeLabel: 'Seluruh Sekolah',
      );

      expect(request.queryParameters, {
        'class_section_id': 'all',
        'grade_level_id': 'all',
        'include_signature': true,
        'signature_role': 'student_affairs',
      });
    });

    test('kesiswaan dengan kelas dan tingkat mengirim id', () {
      const request = ViolationPdfRequest(
        isHomeroom: false,
        classSectionId: 7,
        gradeLevelId: 10,
        scopeLabel: 'X RPL A',
      );

      expect(request.queryParameters, {
        'class_section_id': 7,
        'grade_level_id': 10,
        'include_signature': true,
        'signature_role': 'student_affairs',
      });
    });

    test('includeSignature=false diteruskan ke query', () {
      const request = ViolationPdfRequest(
        isHomeroom: false,
        scopeLabel: 'Seluruh Sekolah',
        includeSignature: false,
      );

      expect(request.queryParameters['include_signature'], isFalse);
    });

    test('legacy query memakai class_id', () {
      const request = ViolationPdfRequest(
        isHomeroom: false,
        classSectionId: 7,
        gradeLevelId: 10,
        scopeLabel: 'X RPL A',
      );

      expect(request.legacyQueryParameters, {'class_id': 7});
    });
  });

  group('ViolationPdfRequest.buildFileName', () {
    test('membuat nama file aman dan berstempel waktu', () {
      const request = ViolationPdfRequest(
        isHomeroom: false,
        scopeLabel: 'Kelas X RPL - A',
      );

      final fileName = request.buildFileName(
        now: DateTime(2026, 10, 21, 9, 5),
      );

      expect(
        fileName,
        'Rekap_Pelanggaran_Kelas-X-RPL-A_20261021_0905.pdf',
      );
    });

    test('membuang karakter terlarang pada nama file', () {
      const request = ViolationPdfRequest(
        isHomeroom: true,
        scopeLabel: 'X/IPS:1*?"<>|',
      );

      final fileName = request.buildFileName(
        now: DateTime(2026, 1, 2, 3, 4),
      );

      expect(fileName, contains('XIPS1'));
      expect(fileName, isNot(contains('/')));
      expect(fileName, isNot(contains(':')));
      expect(fileName, isNot(contains('*')));
      expect(fileName, isNot(contains('?')));
      expect(fileName, isNot(contains('"')));
      expect(fileName, isNot(contains('<')));
      expect(fileName, isNot(contains('>')));
      expect(fileName, isNot(contains('|')));
    });

    test('label kosong memakai fallback Sekolah', () {
      const request = ViolationPdfRequest(
        isHomeroom: false,
        scopeLabel: '   ',
      );

      final fileName = request.buildFileName(
        now: DateTime(2026, 10, 21, 9, 5),
      );

      expect(fileName, 'Rekap_Pelanggaran_Sekolah_20261021_0905.pdf');
    });
  });

  group('canExportViolationPdf', () {
    test('menyembunyikan tombol saat role belum selesai dimuat', () {
      expect(
        canExportViolationPdf(
          isHomeroomTab: true,
          isHomeroom: true,
          isKesiswaan: true,
          isRoleResolved: false,
        ),
        isFalse,
      );
    });

    test('guru tanpa role tidak melihat tombol', () {
      expect(
        canExportViolationPdf(
          isHomeroomTab: false,
          isHomeroom: false,
          isKesiswaan: false,
          isRoleResolved: true,
        ),
        isFalse,
      );
    });

    test('wali kelas melihat tombol di tab kelas perwalian', () {
      expect(
        canExportViolationPdf(
          isHomeroomTab: true,
          isHomeroom: true,
          isKesiswaan: false,
          isRoleResolved: true,
        ),
        isTrue,
      );
    });

    test('wali kelas tidak melihat tombol di tab kesiswaan', () {
      expect(
        canExportViolationPdf(
          isHomeroomTab: false,
          isHomeroom: true,
          isKesiswaan: false,
          isRoleResolved: true,
        ),
        isFalse,
      );
    });

    test('kesiswaan melihat tombol di tab siswa full', () {
      expect(
        canExportViolationPdf(
          isHomeroomTab: false,
          isHomeroom: false,
          isKesiswaan: true,
          isRoleResolved: true,
        ),
        isTrue,
      );
    });
  });

  group('StudentViolationItem identitas', () {
    test('memprioritaskan NISN', () {
      final item = StudentViolationItem(
        studentId: 1,
        studentName: 'Siswa',
        nisn: '111',
        nis: '222',
        admissionNo: '333',
      );

      expect(item.studentIdentityText, 'NISN: 111');
      expect(item.identitySearchValues, ['111', '222', '333']);
    });

    test('fallback ke NIS lalu No. Pendaftaran', () {
      final withNis = StudentViolationItem(
        studentId: 1,
        studentName: 'Siswa',
        nis: '222',
        admissionNo: '333',
      );
      final withAdmissionNo = StudentViolationItem(
        studentId: 2,
        studentName: 'Siswa',
        admissionNo: '333',
      );
      final empty = StudentViolationItem(
        studentId: 3,
        studentName: 'Siswa',
      );

      expect(withNis.studentIdentityText, 'NIS: 222');
      expect(withAdmissionNo.studentIdentityText, 'No. Pendaftaran: 333');
      expect(empty.studentIdentityText, 'No. Pendaftaran: -');
    });

    test('mengabaikan nilai identitas kosong', () {
      final item = StudentViolationItem(
        studentId: 1,
        studentName: 'Siswa',
        nisn: '   ',
        nis: '',
        admissionNo: '333',
      );

      expect(item.resolvedNisn, isNull);
      expect(item.resolvedNis, isNull);
      expect(item.studentIdentityText, 'No. Pendaftaran: 333');
    });
  });
}
