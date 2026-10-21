import 'package:cached_network_image/cached_network_image.dart';
import 'package:eschool_saas_staff/cubits/violation/studentViolationDetailCubit.dart';
import 'package:eschool_saas_staff/data/models/violation/studentAvatarHelper.dart';
import 'package:eschool_saas_staff/data/models/violation/studentViolationDetail.dart';
import 'package:eschool_saas_staff/data/models/violation/violationSanctionHelper.dart';
import 'package:eschool_saas_staff/ui/screens/violation/widgets/imagePreviewDialog.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customCircularProgressIndicator.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customErrorWidget.dart';
import 'package:eschool_saas_staff/utils/system/snackBarUtils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class StudentViolationDetailScreen extends StatefulWidget {
  final int studentId;
  final String? studentName;
  final bool isKesiswaan;

  const StudentViolationDetailScreen({
    super.key,
    required this.studentId,
    this.studentName,
    this.isKesiswaan = false,
  });

  static Widget getRouteInstance() {
    final args = Get.arguments as Map<String, dynamic>?;
    final id = args?['studentId'] as int? ?? 0;
    final name = args?['studentName'] as String?;
    final isKesiswaan = args?['isKesiswaan'] as bool? ?? false;

    return BlocProvider(
      create: (_) =>
          StudentViolationDetailCubit()..getStudentDetail(id),
      child: StudentViolationDetailScreen(
        studentId: id,
        studentName: name,
        isKesiswaan: isKesiswaan,
      ),
    );
  }

  @override
  State<StudentViolationDetailScreen> createState() =>
      _StudentViolationDetailScreenState();
}

class _StudentViolationDetailScreenState
    extends State<StudentViolationDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _appBarAnimationController;
  // True bila ada perubahan data (misal hapus riwayat) — dikirim sebagai
  // route result agar halaman pemanggil bisa refresh otomatis.
  bool _dataChanged = false;

  @override
  void initState() {
    super.initState();
    _appBarAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _appBarAnimationController.dispose();
    super.dispose();
  }
  void _confirmDeleteViolation(ViolationRecord record, int studentId) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Hapus Catatan Pelanggaran?",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        content: Text(
          "Apakah Anda yakin ingin menghapus catatan pelanggaran \"${record.violationName}\"? Tindakan ini akan mengurangi akumulasi poin siswa.",
          style: GoogleFonts.poppins(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              "Batal",
              style: GoogleFonts.poppins(
                  color: isDark ? Colors.white60 : Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final cubit = context.read<StudentViolationDetailCubit>();
              final success =
                  await cubit.deleteViolationItem(record.id, studentId);
              if (success) {
                if (mounted) {
                  setState(() => _dataChanged = true);
                  SnackBarUtils.showSnackBar(
                    context: context,
                    message: "Catatan pelanggaran berhasil dihapus",
                    backgroundColor: Colors.green,
                  );
                }
              } else {
                if (mounted) {
                  final currentState = cubit.state;
                  final backendMsg =
                      currentState is StudentViolationDetailFetchSuccess
                          ? currentState.deleteErrorMessage
                          : null;
                  SnackBarUtils.showSnackBar(
                    context: context,
                    message: backendMsg != null && backendMsg.trim().isNotEmpty
                        ? backendMsg
                        : "Gagal menghapus catatan pelanggaran",
                    backgroundColor: Colors.redAccent,
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              "Hapus",
              style: GoogleFonts.poppins(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final bool isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).scaffoldBackgroundColor
          : Colors.grey.shade50,
      appBar: CustomModernAppBar(
        title: widget.studentName != null
            ? widget.studentName!
            : "Detail Pelanggaran",
        subtitle: "Riwayat & Akumulasi Poin",
        icon: Icons.person_rounded,
        fabAnimationController: _appBarAnimationController,
        primaryColor: const Color(0xFF8B1F41),
        lightColor: const Color(0xFFAC3B5C),
        onBackPressed: () => Get.back(result: _dataChanged),
        height: 85,
      ),
      body: BlocBuilder<StudentViolationDetailCubit, StudentViolationDetailState>(
        builder: (context, state) {
          if (state is StudentViolationDetailFetchInProgress) {
            return const Center(child: CustomCircularProgressIndicator());
          }

          if (state is StudentViolationDetailFetchFailure) {
            return CustomErrorWidget(
              message: state.errorMessage,
              onRetry: () => context
                  .read<StudentViolationDetailCubit>()
                  .getStudentDetail(widget.studentId),
            );
          }

          if (state is StudentViolationDetailFetchSuccess) {
            final detail = state.detail;
            // Level aktif DINAMIS dari server (samakan web). Visual hanya
            // untuk warna/icon; penentu level = rentang poin + nama/action.
            final active = detail.activeSanction;
            final sanction = detail.sanctionLevels.isNotEmpty
                ? ViolationSanctionHelper.visualForConfig(
                    active, detail.sanctionLevels)
                : ViolationSanctionHelper.getSanctionLevel(
                    detail.totalPoints,
                    customStatusName: detail.displaySanctionName,
                  );
            final levelName = detail.displaySanctionName;
            final actionType = detail.displayActionType;
            final sanctionDesc = detail.displaySanctionDescription;

            // Lengkapi foto web via cache student-list bila response
            // student-detail belum membawa image (kasus walas).
            if (detail.displayAvatarUrl == null) {
              StudentAvatarHelper.loadAvatarForStudent(
                studentId: detail.studentId,
                studentName: detail.studentName,
                classId: detail.classId,
                onLoaded: () {
                  if (mounted) setState(() {});
                },
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                // Bersihkan cache avatar agar foto/poin terbaru dari
                // backend/web ikut terambil saat pull-to-refresh.
                StudentAvatarHelper.clearCache();
                await context
                    .read<StudentViolationDetailCubit>()
                    .getStudentDetail(widget.studentId, isRefresh: true);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Profil Siswa & Kartu Sanksi
                    _buildStudentProfileCard(
                      detail,
                      sanction,
                      primaryColor,
                      isDark,
                      levelName: levelName,
                      actionType: actionType,
                      sanctionDesc: sanctionDesc,
                    ),

                    const SizedBox(height: 24),

                    // 2. Header Riwayat
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Riwayat Pelanggaran (${detail.totalViolations > 0 ? detail.totalViolations : detail.violations.length})",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        if (state.isDeleting)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CustomCircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 3. Daftar Catatan Pelanggaran
                    if (detail.violations.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Theme.of(context).cardColor
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: isDark
                                  ? Colors.white12
                                  : Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.verified_user_outlined,
                                size: 56, color: Colors.green.shade400),
                            const SizedBox(height: 12),
                            Text(
                              "Tidak Ada Catatan Pelanggaran",
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color:
                                    isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Siswa ini memiliki catatan kedisiplinan yang bersih.",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white60
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: detail.violations.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final record = detail.violations[index];
                          return _buildViolationCard(
                            context: context,
                            record: record,
                            studentId: detail.studentId,
                            isDark: isDark,
                            isDeletingThis: state.isDeleting &&
                                state.deletingViolationId == record.id,
                          );
                        },
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildStudentProfileCard(
    StudentViolationDetail detail,
    SanctionLevel sanction,
    Color primaryColor,
    bool isDark, {
    String? levelName,
    String? actionType,
    String? sanctionDesc,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                // Avatar — sama seperti list/web: ikon orang jika tidak ada foto.
                // Jangan tampilkan huruf inisial.
                Builder(
                  builder: (context) {
                    final avatar = detail.displayAvatarUrl;
                    final fullAvatar =
                        (avatar != null && avatar.trim().isNotEmpty)
                            ? StudentAvatarHelper.formatImageUrl(avatar.trim())
                            : null;

                    Widget defaultAvatar() => SizedBox(
                          width: 60,
                          height: 60,
                          child: Icon(
                            Icons.person,
                            color: isDark ? Colors.white70 : Colors.black,
                            size: 44,
                          ),
                        );

                    if (fullAvatar != null) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: CachedNetworkImage(
                          imageUrl: fullAvatar,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => defaultAvatar(),
                          errorWidget: (context, url, error) =>
                              defaultAvatar(),
                        ),
                      );
                    }

                    return defaultAvatar();
                  },
                ),
                const SizedBox(width: 14),

                // Name & Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detail.studentName,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${detail.className ?? 'Kelas -'} ${detail.rollNumber != null ? '• Absen ${detail.rollNumber}' : ''}",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: isDark
                              ? Colors.white60
                              : Colors.grey.shade700,
                        ),
                      ),
                      if (detail.identityText != null)
                        Text(
                          detail.identityText!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white38
                                : Colors.grey.shade500,
                          ),
                        ),
                    ],
                  ),
                ),

                // Total Points Box
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: sanction.backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: sanction.primaryColor.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "${detail.totalPoints}",
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: sanction.textColor,
                        ),
                      ),
                      Text(
                        "Poin",
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: sanction.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sanction Status Banner (samakan web: level + tindakan + deskripsi)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: sanction.backgroundColor,
              borderRadius: detail.sanctionLevels.isNotEmpty
                  ? BorderRadius.zero
                  : const BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(sanction.icon, color: sanction.primaryColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Status Sanksi: ${levelName ?? sanction.title}",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: sanction.textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Daftar rentang level dinamis dari server (null max -> "≥ X Poin")
          if (detail.sanctionLevels.isNotEmpty)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? Theme.of(context).cardColor.withValues(alpha: 0.6)
                    : Colors.grey.shade50,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Ketentuan Level (dari server)",
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...detail.sanctionLevels.map((lvl) {
                    final isActive = detail.activeSanction?.name == lvl.name &&
                        detail.activeSanction?.minPoints == lvl.minPoints;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Icon(
                            isActive
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_off_rounded,
                            size: 14,
                            color: isActive
                                ? sanction.primaryColor
                                : Colors.grey.shade400,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              "${lvl.name} • ${lvl.displayRange}${lvl.actionType.trim().isNotEmpty ? ' • ${lvl.actionType}' : ''}",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: isActive
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isActive
                                    ? sanction.textColor
                                    : (isDark
                                        ? Colors.white70
                                        : Colors.grey.shade700),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildViolationCard({
    required BuildContext context,
    required ViolationRecord record,
    required int studentId,
    required bool isDark,
    required bool isDeletingThis,
  }) {
    final formattedDate = record.formattedIncidentDate;
    final cardColor = isDark ? Theme.of(context).cardColor : Colors.white;
    final borderColor = isDark ? Colors.white12 : Colors.grey.shade200;
    final muted = isDark ? Colors.white60 : Colors.grey.shade600;
    final titleColor = isDark ? Colors.white : Colors.black87;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "+${record.points} Poin",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.red.shade700,
                ),
              ),
              const Spacer(),
              if (widget.isKesiswaan) ...[
                if (isDeletingThis)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CustomCircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  InkWell(
                    onTap: () =>
                        _confirmDeleteViolation(record, studentId),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.delete_outline_rounded,
                          color: Colors.red.shade300, size: 18),
                    ),
                  ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            record.violationName,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: titleColor,
              height: 1.35,
            ),
          ),
          if (record.detailText != null &&
              record.detailText!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              record.detailText!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: muted,
                height: 1.45,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 13, color: muted),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  formattedDate +
                      (record.reportedByName != null &&
                              record.reportedByName!.trim().isNotEmpty
                          ? "  •  ${record.reportedByName}"
                          : ""),
                  style: GoogleFonts.poppins(fontSize: 11, color: muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (record.photoUrl != null &&
                  record.photoUrl!.trim().isNotEmpty)
                InkWell(
                  onTap: () => ImagePreviewDialog.show(
                    context,
                    imageUrl: record.photoUrl!,
                    title: "Bukti: ${record.violationName}",
                  ),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.attach_file_rounded,
                            size: 15, color: muted),
                        const SizedBox(width: 2),
                        Text(
                          "Bukti",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
