import 'package:eschool_saas_staff/data/models/violation/studentViolationDetail.dart';
import 'package:eschool_saas_staff/data/models/violation/violationSanctionHelper.dart';
import 'package:eschool_saas_staff/data/models/violation/violationSanctionLevel.dart';
import 'package:flutter_test/flutter_test.dart';

List<SanctionLevelConfig> webLevels() => [
      const SanctionLevelConfig(
          id: 1,
          name: 'Level 1',
          minPoints: 0,
          maxPoints: 10,
          actionType: 'Peringatan',
          description: 'Pelanggaran Ringan'),
      const SanctionLevelConfig(
          id: 2,
          name: 'Level 2',
          minPoints: 11,
          maxPoints: 25,
          actionType: 'Panggil Orang Tua',
          description: 'Pelanggaran Sedang'),
      const SanctionLevelConfig(
          id: 3,
          name: 'Level 3',
          minPoints: 26,
          maxPoints: 50,
          actionType: 'Skorsing',
          description: 'Pelanggaran Berat'),
      const SanctionLevelConfig(
          id: 4,
          name: 'Level 4',
          minPoints: 51,
          maxPoints: 100,
          actionType: 'Dikeluarkan',
          description: 'Pelanggaran Sangat Berat'),
    ];

List<SanctionLevelConfig> customLevels() => [
      const SanctionLevelConfig(
          id: 1, name: 'Level 1', minPoints: 10, maxPoints: 29,
          actionType: 'Teguran', description: 'Ringan'),
      const SanctionLevelConfig(
          id: 2, name: 'Level 2', minPoints: 30, maxPoints: 54,
          actionType: 'SP1', description: 'Sedang'),
      const SanctionLevelConfig(
          id: 3, name: 'Level 3', minPoints: 55, maxPoints: 84,
          actionType: 'SP2', description: 'Berat'),
      const SanctionLevelConfig(
          id: 4, name: 'Level 4', minPoints: 85, maxPoints: null,
          actionType: 'SP3', description: 'Sangat Berat'),
    ];

void main() {
  test('4 poin dengan config web -> Level 1', () {
    final active = SanctionLevelConfig.activeSanctionFor(
        webLevels(), 4, 'Level 1', 'Peringatan');
    expect(active?.name, 'Level 1');
  });

  test('35 poin dengan config custom -> Level 2 / SP1 setara', () {
    final active =
        SanctionLevelConfig.activeSanctionFor(customLevels(), 35, null, null);
    expect(active?.name, 'Level 2');
    expect(active?.actionType, 'SP1');
  });

  test('max null contains(500) = true dan display >= X', () {
    const lvl = SanctionLevelConfig(
        id: 4, name: 'Level 4', minPoints: 85, maxPoints: null);
    expect(lvl.contains(500), isTrue);
    expect(lvl.displayRange, '≥ 85 Poin');
  });

  test('levels kosong tidak crash, tampil Aman', () {
    final active =
        SanctionLevelConfig.activeSanctionFor([], 10, null, null);
    expect(active, isNull);
    final detail = StudentViolationDetail(
      studentId: 1,
      studentName: 'Aman',
      totalPoints: 0,
      totalViolations: 0,
    );
    expect(detail.displaySanctionName, 'Aman');
    expect(detail.activeSanction, isNull);
  });

  test('parsing kontrak web toleran + ringkasan benar', () {
    final json = {
      'student_id': 7,
      'student_name': 'Rizal Kusuma',
      'total_points': 4,
      'sanction_level': 'Level 1',
      'sanction_description': 'Pelanggaran Ringan',
      'action_type': 'Peringatan',
      'sanction_levels': [
        {
          'id': 1,
          'nama': 'Level 1',
          'poin_minimum': 0,
          'poin_maksimum': 10,
          'jenis_tindakan': 'Peringatan',
          'deskripsi': 'Pelanggaran Ringan'
        },
      ],
      'violations': [
        {
          'id': 14,
          'violation_name': 'Terlambat',
          'points': 4,
          'occurred_at': '2026-09-24',
          'description': 'Terlambat 15 menit',
          'notes': 'fallback',
          'photo_url': null,
          'reporter_name': 'Ahmad'
        }
      ],
    };
    final detail = StudentViolationDetail.fromJson(json);
    expect(detail.totalPoints, 4);
    expect(detail.totalViolations, 1);
    expect(detail.sanctionLevels.length, 1);
    expect(detail.activeSanction?.name, 'Level 1');
    expect(detail.displayActionType, 'Peringatan');
    expect(detail.violations.first.detailText, 'Terlambat 15 menit');
    // notes fallback saat description kosong
    final rec2 = ViolationRecord.fromJson({
      'id': 15,
      'violation_name': 'X',
      'points': 2,
      'notes': 'hanya notes',
    });
    expect(rec2.detailText, 'hanya notes');
  });

  test('fallback nama/action saat di luar range', () {
    final levels = webLevels();
    final byName =
        SanctionLevelConfig.activeSanctionFor(levels, 999, 'Level 2', null);
    // 999 tidak contains 51-100, fallback nama persis -> Level 2
    expect(byName?.name, 'Level 2');
    final byAction = SanctionLevelConfig.activeSanctionFor(
        levels, 999, 'Tidak Ada', 'Skorsing');
    expect(byAction?.name, 'Level 3');
  });

  test('judul legacy sudah gaya web (Aman, Level 1-4)', () {
    expect(ViolationSanctionHelper.levelBaik.title, 'Aman');
    expect(ViolationSanctionHelper.levelPeringatanLisan.title, 'Level 1');
    expect(ViolationSanctionHelper.levelSp1.title, 'Level 2');
    expect(ViolationSanctionHelper.levelSp2.title, 'Level 3');
    expect(ViolationSanctionHelper.levelSp3.title, 'Level 4');
    // 0 poin tanpa nama server -> Aman (bukan Baik)
    final s = ViolationSanctionHelper.getSanctionLevel(0);
    expect(s.title, 'Aman');
  });

  test('matcher mengenali nama Level dari server untuk warna', () {
    expect(
        ViolationSanctionHelper.getSanctionLevel(0, customStatusName: 'Level 3')
            .title,
        'Level 3');
    expect(
        ViolationSanctionHelper.getSanctionLevel(0, customStatusName: 'Level 1')
            .title,
        'Level 1');
  });

  test('label badge list: server > 0 poin > fallback', () {
    String label({required int p, String? n, String fallback = 'Level 2'}) =>
        ViolationSanctionHelper.listBadgeLabel(
            points: p, sanctionName: n, fallbackTitle: fallback);
    expect(label(p: 0), 'Aman');
    expect(label(p: 0, n: 'Baik'), 'Aman');
    expect(label(p: 4, n: 'Level 1'), 'Level 1');
    expect(label(p: 60, fallback: 'Level 3'), 'Level 3');
  });
}
