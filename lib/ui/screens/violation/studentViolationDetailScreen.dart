import 'package:cached_network_image/cached_network_image.dart';
import 'package:eschool_saas_staff/app/routes.dart';
import 'package:eschool_saas_staff/cubits/violation/studentViolationDetailCubit.dart';
import 'package:eschool_saas_staff/data/models/violation/studentAvatarHelper.dart';
import 'package:eschool_saas_staff/data/models/violation/studentViolationDetail.dart';
import 'package:eschool_saas_staff/data/models/violation/violationSanctionHelper.dart';
import 'package:eschool_saas_staff/ui/screens/violation/widgets/imagePreviewDialog.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customCircularProgressIndicator.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customErrorWidget.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/snackBarUtils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

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
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              "Batal",
              style: GoogleFonts.poppins(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await context
                  .read<StudentViolationDetailCubit>()
                  .deleteViolationItem(record.id, studentId);
              if (success) {
                if (mounted) {
                  SnackBarUtils.showSnackBar(
                    context: context,
                    message: "Catatan pelanggaran berhasil dihapus",
                    backgroundColor: Colors.green,
                  );
                }
              } else {
                if (mounted) {
                  SnackBarUtils.showSnackBar(
                    context: context,
                    message: "Gagal menghapus catatan pelanggaran",
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
        onBackPressed: () => Get.back(),
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
            final sanction = ViolationSanctionHelper.getSanctionLevel(
              detail.totalPoints,
              customStatusName: detail.sanctionStatus,
            );

            return RefreshIndicator(
              onRefresh: () async {
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
                    _buildStudentProfileCard(detail, sanction, primaryColor),

                    const SizedBox(height: 24),

                    // 2. Header Riwayat
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Riwayat Pelanggaran (${detail.violations.length})",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
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
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Siswa ini memiliki catatan kedisiplinan yang bersih.",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey.shade600,
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
                            record: record,
                            studentId: detail.studentId,
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
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
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
                // Avatar
                Builder(
                  builder: (context) {
                    final avatar = detail.displayAvatarUrl;
                    final fullAvatar =
                        (avatar != null && avatar.trim().isNotEmpty)
                            ? StudentAvatarHelper.formatImageUrl(avatar.trim())
                            : null;

                    if (fullAvatar != null) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: CachedNetworkImage(
                          imageUrl: fullAvatar,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => CircleAvatar(
                            radius: 30,
                            backgroundColor:
                                primaryColor.withValues(alpha: 0.1),
                            child: Text(
                              detail.studentName.isNotEmpty
                                  ? detail.studentName[0].toUpperCase()
                                  : 'S',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => CircleAvatar(
                            radius: 30,
                            backgroundColor:
                                primaryColor.withValues(alpha: 0.1),
                            child: Text(
                              detail.studentName.isNotEmpty
                                  ? detail.studentName[0].toUpperCase()
                                  : 'S',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    return CircleAvatar(
                      radius: 30,
                      backgroundColor: primaryColor.withValues(alpha: 0.1),
                      child: Text(
                        detail.studentName.isNotEmpty
                            ? detail.studentName[0].toUpperCase()
                            : 'S',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    );
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
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${detail.className ?? 'Kelas -'} ${detail.rollNumber != null ? '• Absen ${detail.rollNumber}' : ''}",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      if (detail.nisn != null && detail.nisn!.isNotEmpty)
                        Text(
                          "NISN: ${detail.nisn}",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade500,
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

          // Sanction Status Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: sanction.backgroundColor,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(sanction.icon, color: sanction.primaryColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Status Sanksi: ${sanction.title}",
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
        ],
      ),
    );
  }

  Widget _buildViolationCard({
    required ViolationRecord record,
    required int studentId,
    required bool isDeletingThis,
  }) {
    final catColor = ViolationSanctionHelper.getCategoryColor(record.category);
    final formattedDate = record.formattedIncidentDate;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Left Accent Indicator Stripe matching category
              Container(
                width: 5,
                color: catColor,
              ),

              // 2. Card Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Category Badge ("Sedang"), Points (+4 Poin), and Delete
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Category Badge: "Sedang" / "Ringan" / "Berat"
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: catColor.withValues(alpha: 0.3),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: catColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  record.category,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: catColor,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Right side: Points pill & delete button
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.red.shade200,
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  "+${record.points} Poin",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ),
                              if (widget.isKesiswaan) ...[
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: isDeletingThis
                                      ? null
                                      : () => _confirmDeleteViolation(
                                          record, studentId),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: isDeletingThis
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child:
                                                CustomCircularProgressIndicator(
                                                    strokeWidth: 2),
                                          )
                                        : Icon(Icons.delete_outline_rounded,
                                            color: Colors.red.shade400,
                                            size: 18),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Violation Name Title
                      Text(
                        record.violationName,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          height: 1.35,
                        ),
                      ),

                      // Notes / Chronology (if available)
                      if (record.notes != null &&
                          record.notes!.trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.amber.shade200,
                              width: 0.8,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.sticky_note_2_rounded,
                                    size: 15,
                                    color: Colors.amber.shade700,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Catatan / Kronologi",
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.amber.shade800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                record.notes!,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey.shade800,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),

                      // Bottom Row: Date + Photo Thumbnail side by side
                      Row(
                        children: [
                          // Date Pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 14,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  formattedDate,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Photo Thumbnail (if available)
                          if (record.photoUrl != null &&
                              record.photoUrl!.trim().isNotEmpty) ...[
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => ImagePreviewDialog.show(
                                context,
                                imageUrl: record.photoUrl!,
                                title: "Bukti: ${record.violationName}",
                              ),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.blue.shade200,
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withValues(alpha: 0.08),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(7),
                                  child: CachedNetworkImage(
                                    imageUrl: record.photoUrl!.startsWith('http')
                                        ? record.photoUrl!
                                        : "$storageUrl${record.photoUrl}",
                                    width: 34,
                                    height: 34,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => Container(
                                      width: 34,
                                      height: 34,
                                      color: Colors.grey.shade200,
                                      child: Icon(Icons.image_rounded,
                                          size: 16, color: Colors.grey.shade400),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      // Reporter Name (if available)
                      if (record.reportedByName != null &&
                          record.reportedByName!.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.person_outline_rounded,
                                size: 13, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(
                              "Dicatat oleh: ${record.reportedByName}",
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
