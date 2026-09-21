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
  static const SanctionLevel levelBaik = SanctionLevel(
    title: "Baik",
    primaryColor: Color(0xFF2E7D32),
    backgroundColor: Color(0xFFE8F5E9),
    textColor: Color(0xFF1B5E20),
    icon: Icons.check_circle_outline_rounded,
  );

  static const SanctionLevel levelPeringatanLisan = SanctionLevel(
    title: "Peringatan Lisan",
    primaryColor: Color(0xFFF57F17),
    backgroundColor: Color(0xFFFFF8E1),
    textColor: Color(0xFFE65100),
    icon: Icons.warning_amber_rounded,
  );

  static const SanctionLevel levelSp1 = SanctionLevel(
    title: "Surat Peringatan 1 (SP 1)",
    primaryColor: Color(0xFFE65100),
    backgroundColor: Color(0xFFFFF3E0),
    textColor: Color(0xFFBF360C),
    icon: Icons.report_problem_rounded,
  );

  static const SanctionLevel levelSp2 = SanctionLevel(
    title: "Surat Peringatan 2 (SP 2)",
    primaryColor: Color(0xFFD32F2F),
    backgroundColor: Color(0xFFFFEBEE),
    textColor: Color(0xFFB71C1C),
    icon: Icons.error_outline_rounded,
  );

  static const SanctionLevel levelSp3 = SanctionLevel(
    title: "SP 3 (Panggilan Orang Tua & Kepala Sekolah)",
    primaryColor: Color(0xFF880E4F),
    backgroundColor: Color(0xFFFCE4EC),
    textColor: Color(0xFF4A148C),
    icon: Icons.dangerous_rounded,
  );

  /// Menghitung level sanksi berdasarkan akumulasi poin
  static SanctionLevel getSanctionLevel(int points, {String? customStatusName}) {
    if (customStatusName != null && customStatusName.isNotEmpty) {
      final lower = customStatusName.toLowerCase();
      if (lower.contains('sp 3') || lower.contains('sp3')) {
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
