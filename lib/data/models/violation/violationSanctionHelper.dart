import 'package:eschool_saas_staff/data/models/violation/violationSanctionLevel.dart';
import 'package:flutter/material.dart';

class SanctionLevel {
  final String title;
  final Color primaryColor;
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;

  const SanctionLevel({
    required this.title,
    required this.primaryColor,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
  });
}

class ViolationSanctionHelper {
  // Judul disamakan web: Aman + Level 1-4 (bukan Baik/SP1/...).
  // Level AKTIF tetap ditentukan config dinamis; judul ini hanya label
  // fallback untuk list yang belum membawa `sanction_levels`.
  static const SanctionLevel levelBaik = SanctionLevel(
    title: "Aman",
    primaryColor: Color(0xFF2E7D32),
    backgroundColor: Color(0xFFE8F5E9),
    textColor: Color(0xFF1B5E20),
    icon: Icons.check_circle_outline_rounded,
  );

  static const SanctionLevel levelPeringatanLisan = SanctionLevel(
    title: "Level 1",
    primaryColor: Color(0xFFF57F17),
    backgroundColor: Color(0xFFFFF8E1),
    textColor: Color(0xFFE65100),
    icon: Icons.warning_amber_rounded,
  );

  static const SanctionLevel levelSp1 = SanctionLevel(
    title: "Level 2",
    primaryColor: Color(0xFFE65100),
    backgroundColor: Color(0xFFFFF3E0),
    textColor: Color(0xFFBF360C),
    icon: Icons.report_problem_rounded,
  );

  static const SanctionLevel levelSp2 = SanctionLevel(
    title: "Level 3",
    primaryColor: Color(0xFFD32F2F),
    backgroundColor: Color(0xFFFFEBEE),
    textColor: Color(0xFFB71C1C),
    icon: Icons.error_outline_rounded,
  );

  static const SanctionLevel levelSp3 = SanctionLevel(
    title: "Level 4",
    primaryColor: Color(0xFF880E4F),
    backgroundColor: Color(0xFFFCE4EC),
    textColor: Color(0xFF4A148C),
    icon: Icons.dangerous_rounded,
  );

  /// LEGACY fallback untuk list tanpa `sanction_levels` (misal list siswa).
  /// Sumber kebenaran untuk detail adalah config DINAMIS via [visualForConfig].
  /// Jangan tentukan level dari warna — hanya rentang poin + nama/action.
  static SanctionLevel getSanctionLevel(int points, {String? customStatusName}) {
    if (customStatusName != null && customStatusName.isNotEmpty) {
      final lower = customStatusName.toLowerCase();
      // Nama gaya web didahulukan agar warna badge list selaras detail.
      if (lower.contains('level 4')) {
        return levelSp3;
      } else if (lower.contains('level 3')) {
        return levelSp2;
      } else if (lower.contains('level 2')) {
        return levelSp1;
      } else if (lower.contains('level 1')) {
        return levelPeringatanLisan;
      } else if (lower.contains('sp 3') || lower.contains('sp3')) {
        return levelSp3;
      } else if (lower.contains('sp 2') || lower.contains('sp2')) {
        return levelSp2;
      } else if (lower.contains('sp 1') || lower.contains('sp1')) {
        return levelSp1;
      } else if (lower.contains('lisan') || lower.contains('peringatan')) {
        return levelPeringatanLisan;
      } else if (lower.contains('baik') || lower.contains('aman')) {
        return levelBaik;
      }
    }

    if (points >= 75) {
      return levelSp3;
    } else if (points >= 50) {
      return levelSp2;
    } else if (points >= 25) {
      return levelSp1;
    } else if (points >= 10) {
      return levelPeringatanLisan;
    } else {
      return levelBaik;
    }
  }

  /// Teks badge status untuk kartu list (samakan web: Aman, Level 1-4).
  /// Prioritas: nama dari server (dinormalisasi Baik -> Aman),
  /// lalu 0 poin -> Aman, sisanya label visual fallback.
  static String listBadgeLabel({
    required int points,
    String? sanctionName,
    required String fallbackTitle,
  }) {
    final raw = (sanctionName ?? '').trim();
    if (raw.isNotEmpty) {
      if (raw.toLowerCase() == 'baik') return 'Aman';
      return raw;
    }
    if (points <= 0) return 'Aman';
    return fallbackTitle;
  }

  /// Visual dari config DINAMIS (samakan web).
  /// Level aktif sudah ditentukan via [SanctionLevelConfig.activeSanctionFor];
  /// fungsi ini hanya memetakan ke warna/icon (bukan penentu level).
  /// Pemetaan web: L1=Ringan/Peringatan, L2=Sedang/Panggil OT,
  /// L3=Berat/Skorsing, L4=Sangat Berat/Dikeluarkan.
  static SanctionLevel visualForConfig(
    SanctionLevelConfig? active,
    List<SanctionLevelConfig> all,
  ) {
    if (active == null) return levelBaik;
    final name = active.name.toLowerCase();
    final action = active.actionType.toLowerCase();
    final desc = active.description.toLowerCase();
    bool has(List<String> keys) =>
        keys.any((k) => name.contains(k) || action.contains(k) || desc.contains(k));

    if (has(['sp 3', 'sp3', 'sangat berat', 'dikeluarkan'])) return levelSp3;
    if (has(['sp 2', 'sp2', 'skorsing']) || has(['berat']) && has(['level 3', ' 3'])) {
      return levelSp2;
    }
    if (has(['sp 1', 'sp1', 'panggil orang tua']) ||
        (has(['sedang']) && !has(['berat'])) ||
        has(['level 2', ' sp1'])) {
      // Bedakan SP1 vs SP2: skorsing sudah ditangani di atas.
      if (has(['sp 2', 'sp2', 'skorsing'])) return levelSp2;
      // Level 3 berat tanpa kata skorsing tetap SP2.
      if (has(['level 3']) || has(['berat']) && !has(['ringan', 'sedang'])) {
        return levelSp2;
      }
      return levelSp1;
    }
    if (has(['level 4', 'sp 3', 'sp3'])) return levelSp3;
    if (has(['level 3'])) return levelSp2;
    if (has(['level 2'])) return levelSp1;
    if (has(['level 1', 'ringan', 'peringatan', 'teguran', 'lisan'])) {
      return levelPeringatanLisan;
    }
    // Fallback urutan config (min ASC): 0->Peringatan, 1->SP1, 2->SP2, 3+->SP3.
    final sorted = List<SanctionLevelConfig>.from(all)
      ..sort((a, b) => a.minPoints.compareTo(b.minPoints));
    final idx = sorted.indexWhere((e) => e.id == active.id && e.name == active.name);
    final order = idx >= 0 ? idx : sorted.indexOf(active);
    if (order <= 0) {
      // Jika hanya 1 level dan poin masuk, tetap peringatan kecuali Aman.
      return active.minPoints <= 0 && (active.maxPoints ?? 0) >= 0 && order == 0
          ? levelPeringatanLisan
          : levelPeringatanLisan;
    }
    if (order == 1) return levelSp1;
    if (order == 2) return levelSp2;
    return levelSp3;
  }

  /// Warna kategori pelanggaran: Ringan, Sedang, Berat
  static Color getCategoryColor(String? category) {
    final cat = (category ?? '').toLowerCase();
    if (cat.contains('berat')) {
      return const Color(0xFFD32F2F);
    } else if (cat.contains('sedang')) {
      return const Color(0xFFF57F17);
    } else {
      return const Color(0xFF1976D2);
    }
  }
}
