import 'package:eschool_saas_staff/data/models/student/student.dart';
import 'package:eschool_saas_staff/data/models/student/studentDetails.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Student.fromJson', () {
    test('membaca nis dan nisn dari response', () {
      final student = Student.fromJson({
        'id': 1,
        'admission_no': '2026/202708701415',
        'nis': '2027087014',
        'nisn': '0071234567',
        'roll_number': 5,
      });

      expect(student.nis, '2027087014');
      expect(student.nisn, '0071234567');
      expect(student.admissionNo, '2026/202708701415');
    });

    test('null saat field tidak dikirim', () {
      final student = Student.fromJson({'id': 1});

      expect(student.nis, isNull);
      expect(student.nisn, isNull);
    });
  });

  group('StudentDetails.studentIdentityText', () {
    test('prioritas NISN (nested student)', () {
      final details = StudentDetails.fromJson({
        'name': 'Abdul Setiawan',
        'student': {
          'admission_no': '2026/202708701415',
          'nis': '2027087014',
          'nisn': '0071234567',
        },
      });

      expect(details.studentIdentityText, 'NISN: 0071234567');
    });

    test('fallback ke NIS saat NISN kosong', () {
      final details = StudentDetails.fromJson({
        'name': 'Abdul Setiawan',
        'student': {
          'admission_no': '2026/202708701415',
          'nis': '2027087014',
          'nisn': '',
        },
      });

      expect(details.studentIdentityText, 'NIS: 2027087014');
    });

    test('fallback ke No. Pendaftaran saat NISN dan NIS kosong', () {
      final details = StudentDetails.fromJson({
        'name': 'Abdul Setiawan',
        'student': {
          'admission_no': '2026/202708701415',
          'nis': null,
          'nisn': null,
        },
      });

      expect(
        details.studentIdentityText,
        'No. Pendaftaran: 2026/202708701415',
      );
    });

    test('membaca nis/nisn dari root response bila tidak nested', () {
      final details = StudentDetails.fromJson({
        'name': 'Abdul Setiawan',
        'nis': '2027087014',
        'nisn': '0071234567',
      });

      expect(details.studentIdentityText, 'NISN: 0071234567');
    });

    test('nilai pencarian memuat NISN, NIS, dan No. Pendaftaran', () {
      final details = StudentDetails.fromJson({
        'name': 'Abdul Setiawan',
        'student': {
          'admission_no': '2026/202708701415',
          'nis': '2027087014',
          'nisn': '0071234567',
        },
      });

      expect(
        details.identitySearchValues,
        containsAll([
          '0071234567',
          '2027087014',
          '2026/202708701415',
        ]),
      );
    });
  });
}
