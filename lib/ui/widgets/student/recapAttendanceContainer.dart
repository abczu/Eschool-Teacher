import 'package:eschool_saas_staff/data/models/academic/classSection.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:flutter/foundation.dart';

class RecapAttendanceContainer extends StatelessWidget {
  final List<ClassSection> classSections;
  final Function(ClassSection, int) onDownload;
  final Function(ClassSection, int) onPreview;
  final int selectedYear;
  final int? selectedMonth;
  final String? email;
  final int? schoolId; // Tambahkan parameter schoolId

  const RecapAttendanceContainer({
    super.key,
    required this.classSections,
    required this.onDownload,
    required this.onPreview,
    required this.selectedYear,
    this.selectedMonth,
    this.email,
    this.schoolId,
  });


  // Add this new method to show PKL notification
  void _showPKLNotification(BuildContext context, String className) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange[700],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Kelas Sedang PKL',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            '$className sedang melaksanakan PKL (Praktik Kerja Lapangan). '
            'Rekap absensi tidak tersedia selama periode PKL.',
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Tutup',
                style: TextStyle(
                  color: Colors.orange[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final availableMonths = selectedYear < now.year
        ? 12
        : selectedYear > now.year
            ? 0
            : now.month;

    final cardBg = isDark ? Theme.of(context).cardColor : AppColorPalette.warmBeige;
    final titleColor = isDark ? Colors.white : AppColorPalette.primaryMaroon;
    final subtitleColor = isDark ? Colors.white70 : AppColorPalette.secondaryMaroon;
    final iconColor = isDark ? const Color(0xFFE53935) : AppColorPalette.primaryMaroon.withValues(alpha: 0.5);

    if (availableMonths == 0) {
      return FadeIn(
        duration: const Duration(milliseconds: 800),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 64,
                  color: iconColor,
                ),
                const SizedBox(height: 20),
                Text(
                  'Data Rekap Belum Tersedia',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tahun $selectedYear',
                  style: TextStyle(
                    fontSize: 18,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show message if no month is selected
    if (selectedMonth == null) {
      return FadeIn(
        duration: const Duration(milliseconds: 800),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.event_busy_outlined,
                  size: 64,
                  color: iconColor,
                ),
                const SizedBox(height: 20),
                Text(
                  'Pilih Bulan dan Tahun',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Silakan pilih bulan dan tahun untuk melihat rekap absensi',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Check if selected month is available
    if (selectedMonth! > availableMonths) {
      return FadeIn(
        duration: const Duration(milliseconds: 800),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 64,
                  color: Colors.orange[700],
                ),
                const SizedBox(height: 20),
                Text(
                  'Data Belum Tersedia',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rekap absensi untuk ${_getMonthName(selectedMonth!)} $selectedYear belum tersedia',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      color: isDark ? Colors.transparent : AppColorPalette.warmBeige.withValues(alpha: 0.5),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          // Show only the selected month
          FadeInUp(
            duration: const Duration(milliseconds: 400),
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: isDark ? Theme.of(context).cardColor : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildMonthHeader(
                      selectedMonth! - 1), // Convert to 0-based index
                  _buildClassList(selectedMonth! - 1,
                      context), // Convert to 0-based index
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthHeader(int monthIndex) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColorPalette.primaryMaroon,
            AppColorPalette.secondaryMaroon,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getMonthName(monthIndex + 1),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$selectedYear',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.9),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassList(int monthIndex, BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kelas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColorPalette.primaryMaroon,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          Divider(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColorPalette.lightMaroon,
            thickness: 1,
            height: 32,
          ),
          // Menampilkan daftar kelas yang kosong
          if (classSections.isEmpty)
            _buildNoClassesMessage(context)
          // Menampilkan semua kelas yang tersedia
          else
            ...classSections
                .map((section) => _buildClassItem(section, monthIndex, context)),
        ],
      ),
    );
  }

  // Widget untuk menampilkan pesan ketika tidak ada kelas
  Widget _buildNoClassesMessage(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 40,
              color: Colors.orange[700],
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada kelas ditemukan',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassItem(
      ClassSection section, int monthIndex, BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return SlideInRight(
      duration: const Duration(milliseconds: 400),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? (section.pkl == 1 ? Colors.grey.shade900.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.05))
              : (section.pkl == 1 ? Colors.grey.shade100 : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? (section.pkl == 1 ? Colors.grey.shade800 : Colors.white.withValues(alpha: 0.08))
                : (section.pkl == 1 ? Colors.grey.shade300 : Colors.grey.shade200),
            width: 1,
          ),
        ),
        // Gunakan Column untuk memisahkan nama kelas dan tombol aksi
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bagian nama kelas
            Row(
              children: [
                Icon(
                  section.pkl == 1
                      ? Icons.business_center_rounded
                      : Icons.school_rounded,
                  color: isDark
                      ? (section.pkl == 1 ? Colors.grey.shade500 : const Color(0xFFE53935))
                      : (section.pkl == 1 ? Colors.grey : AppColorPalette.secondaryMaroon),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    section.name ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark
                          ? (section.pkl == 1 ? Colors.grey.shade400 : Colors.white)
                          : (section.pkl == 1 ? Colors.grey.shade700 : AppColorPalette.primaryMaroon),
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),

            // Separator
            const SizedBox(height: 16),

            // Bagian tombol aksi dalam row terpisah
            Align(
              alignment: Alignment.centerRight,
              child: _buildActionButtons(section, monthIndex, context),
            ),

            // Info NIS/NISN: jika masih kosong di preview, data master belum diisi admin.
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: isDark ? Colors.white38 : Colors.grey.shade500,
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'NIS/NISN kosong? Lengkapi data master via admin sekolah.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Update the existing _buildActionButtons method with new styling
  Widget _buildActionButtons(
      ClassSection section, int monthIndex, BuildContext context) {
    final bool isPKL = section.pkl == 1;

    return Wrap(
      spacing: 8, // Jarak horizontal antara tombol
      runSpacing: 8, // Jarak vertikal jika tombol wrap ke baris baru
      children: [
        _ActionButton(
          icon:
              isPKL ? Icons.business_center_rounded : Icons.visibility_rounded,
          label: 'Preview',
          onPressed: () {
            debugPrint('[RecapContainer] Preview tapped for ${section.name}, month=${monthIndex + 1}, isPKL=$isPKL');
            if (isPKL) {
              _showPKLNotification(context, section.name ?? 'Kelas ini');
            } else {
              onPreview(section, monthIndex + 1);
            }
          },
          isPrimary: true,
          isPKL: isPKL,
        ),
        _ActionButton(
          icon: isPKL ? Icons.business_center_rounded : Icons.download_rounded,
          label: 'Unduh',
          onPressed: () {
            debugPrint('[RecapContainer] Unduh tapped for ${section.name}, month=${monthIndex + 1}, isPKL=$isPKL');
            if (isPKL) {
              _showPKLNotification(context, section.name ?? 'Kelas ini');
            } else {
              onDownload(section, monthIndex + 1);
            }
          },
          isPrimary: false,
          isPKL: isPKL,
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    return months[month - 1];
  }
}

/// Tombol aksi yang menggunakan GestureDetector untuk deteksi tap yang lebih andal
/// dibanding Material + InkWell yang bisa gagal di dalam ScrollView
class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isPKL;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.isPrimary,
    required this.isPKL,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final buttonBg = widget.isPKL
        ? (isDark ? Colors.grey.shade800 : Colors.grey.shade300)
        : (widget.isPrimary ? AppColorPalette.primaryMaroon : AppColorPalette.secondaryMaroon);
    final textIconColor = widget.isPKL
        ? (isDark ? Colors.grey.shade500 : Colors.grey.shade600)
        : Colors.white;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedOpacity(
          opacity: _isPressed ? 0.8 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: buttonBg,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: widget.isPKL
                      ? Colors.grey.withValues(alpha: isDark ? 0.05 : 0.2)
                      : AppColorPalette.primaryMaroon.withValues(alpha: isDark ? 0.1 : 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 20,
                  color: textIconColor,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: TextStyle(
                    color: textIconColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
