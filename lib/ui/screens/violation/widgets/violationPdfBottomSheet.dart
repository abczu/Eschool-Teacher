import 'package:eschool_saas_staff/cubits/teacherAcademics/gradeLevelCubit.dart';
import 'package:eschool_saas_staff/cubits/violation/exportViolationPdfCubit.dart';
import 'package:eschool_saas_staff/data/models/academic/gradeLevel.dart';
import 'package:eschool_saas_staff/ui/screens/violation/violationPdfPreviewScreen.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customCircularProgressIndicator.dart';
import 'package:eschool_saas_staff/utils/system/violationPdfUtils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bottom sheet untuk memilih aksi rekap PDF:
/// - Pratinjau: tampilkan PDF di aplikasi tanpa menyimpan.
/// - Unduh: simpan PDF ke perangkat lewat dialog penyimpanan sistem.
class ViolationPdfBottomSheet extends StatefulWidget {
  final bool isHomeroom;
  final int? classSectionId;
  final String? homeroomFilter;
  final String scopeLabel;
  final String? activeFilterLabel;

  const ViolationPdfBottomSheet({
    super.key,
    required this.isHomeroom,
    required this.scopeLabel,
    this.classSectionId,
    this.homeroomFilter,
    this.activeFilterLabel,
  });

  static Future<void> show(
    BuildContext context, {
    required bool isHomeroom,
    required int? classSectionId,
    String? homeroomFilter,
    required String scopeLabel,
    String? activeFilterLabel,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<ExportViolationPdfCubit>()),
          BlocProvider.value(value: context.read<GradeLevelCubit>()),
        ],
        child: ViolationPdfBottomSheet(
          isHomeroom: isHomeroom,
          classSectionId: classSectionId,
          homeroomFilter: homeroomFilter,
          scopeLabel: scopeLabel,
          activeFilterLabel: activeFilterLabel,
        ),
      ),
    );
  }

  @override
  State<ViolationPdfBottomSheet> createState() =>
      _ViolationPdfBottomSheetState();
}

class _ViolationPdfBottomSheetState extends State<ViolationPdfBottomSheet> {
  int? _selectedGradeLevelId;
  bool _isSaving = false;

  bool get _isKesiswaan => !widget.isHomeroom;

  String? _selectedGradeName(List<GradeLevel> gradeLevels) {
    if (_selectedGradeLevelId == null) return null;
    for (final grade in gradeLevels) {
      if (grade.id == _selectedGradeLevelId) return grade.name;
    }
    return null;
  }

  String _previewScopeLabel(List<GradeLevel> gradeLevels) {
    final gradeName = _selectedGradeName(gradeLevels);
    if (gradeName == null || gradeName.trim().isEmpty) {
      return widget.scopeLabel;
    }
    return '${widget.scopeLabel} - Tingkat $gradeName';
  }

  ViolationPdfRequest _buildRequest(List<GradeLevel> gradeLevels) {
    return ViolationPdfRequest(
      isHomeroom: widget.isHomeroom,
      classSectionId: widget.classSectionId,
      gradeLevelId: _isKesiswaan ? _selectedGradeLevelId : null,
      homeroomFilter: widget.isHomeroom ? widget.homeroomFilter : null,
      scopeLabel: _previewScopeLabel(gradeLevels),
    );
  }

  Future<void> _handleAction(
    ViolationPdfAction action,
    List<GradeLevel> gradeLevels,
  ) async {
    if (_isSaving) return;

    final cubit = context.read<ExportViolationPdfCubit>();
    final document = await cubit.exportPdf(
      request: _buildRequest(gradeLevels),
      action: action,
    );

    if (!mounted || document == null) return;

    if (action == ViolationPdfAction.preview) {
      final navigator = Navigator.of(context);
      navigator.pop();
      navigator.push(
        MaterialPageRoute(
          builder: (_) => ViolationPdfPreviewScreen(document: document),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final savedPath = await saveViolationPdfToDevice(
      bytes: document.bytes,
      fileName: document.fileName,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (savedPath == null) {
      // Dialog penyimpanan dibatalkan: kembali ke pilihan awal.
      cubit.reset();
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    navigator.pop();
    messenger
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Rekap PDF berhasil disimpan: ${document.fileName}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Lihat',
            textColor: Colors.white,
            onPressed: () {
              navigator.push(
                MaterialPageRoute(
                  builder: (_) => ViolationPdfPreviewScreen(document: document),
                ),
              );
            },
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? theme.cardColor : Colors.white;
    final titleColor = isDark ? Colors.white : Colors.black87;
    final mutedColor = isDark ? Colors.white60 : Colors.grey.shade600;
    final primaryColor = theme.colorScheme.primary;

    final gradeState = context.watch<GradeLevelCubit>().state;
    final gradeLevels = gradeState is GradeLevelFetchSuccess
        ? gradeState.gradeLevels
        : const <GradeLevel>[];

    return BlocBuilder<ExportViolationPdfCubit, ExportViolationPdfState>(
      builder: (context, state) {
        final isInProgress = state is ExportViolationPdfInProgress;

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildHeader(
                    titleColor: titleColor,
                    mutedColor: mutedColor,
                    primaryColor: primaryColor,
                    isDark: isDark,
                    isInProgress: isInProgress,
                  ),
                  const SizedBox(height: 18),
                  if (isInProgress)
                    _buildLoading(state, primaryColor, titleColor, mutedColor)
                  else ...[
                    if (_isKesiswaan) ...[
                      if (gradeState is GradeLevelFetchInProgress)
                        _buildGradeLoading(mutedColor)
                      else if (gradeState is GradeLevelFetchFailure)
                        _buildGradeError(mutedColor, primaryColor)
                      else if (gradeLevels.isNotEmpty)
                        _buildGradeSelector(
                          gradeLevels: gradeLevels,
                          isDark: isDark,
                          titleColor: titleColor,
                          mutedColor: mutedColor,
                          primaryColor: primaryColor,
                        ),
                    ],
                    const SizedBox(height: 16),
                    if (state is ExportViolationPdfFailure)
                      _buildError(state.errorMessage, isDark),
                    _buildActions(
                      gradeLevels: gradeLevels,
                      primaryColor: primaryColor,
                      mutedColor: mutedColor,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader({
    required Color titleColor,
    required Color mutedColor,
    required Color primaryColor,
    required bool isDark,
    required bool isInProgress,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.picture_as_pdf_outlined,
            color: primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rekap Pelanggaran',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                ),
              ),
              Text(
                _isKesiswaan
                    ? 'Laporan siswa berpoin se-sekolah'
                    : 'Laporan kelas perwalian',
                style: GoogleFonts.poppins(fontSize: 12, color: mutedColor),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Tutup',
          onPressed: isInProgress ? null : () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.close_rounded,
            color: isDark ? Colors.white54 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildGradeLoading(Color mutedColor) {
    return Row(
      children: [
        const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 8),
        Text(
          'Memuat daftar tingkat...',
          style: GoogleFonts.poppins(fontSize: 12, color: mutedColor),
        ),
      ],
    );
  }

  Widget _buildGradeError(Color mutedColor, Color primaryColor) {
    return Row(
      children: [
        Icon(Icons.info_outline_rounded, size: 15, color: mutedColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Daftar tingkat gagal dimuat.',
            style: GoogleFonts.poppins(fontSize: 12, color: mutedColor),
          ),
        ),
        TextButton(
          onPressed: () => context.read<GradeLevelCubit>().getGradeLevels(),
          style: TextButton.styleFrom(
            foregroundColor: primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: const Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Coba lagi',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGradeSelector({
    required List<GradeLevel> gradeLevels,
    required bool isDark,
    required Color titleColor,
    required Color mutedColor,
    required Color primaryColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Tingkat',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: titleColor,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '(khusus laporan PDF)',
              style: GoogleFonts.poppins(fontSize: 11, color: mutedColor),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildChoiceChip(
              label: 'Semua Tingkat',
              selected: _selectedGradeLevelId == null,
              onSelected: () => setState(() => _selectedGradeLevelId = null),
              primaryColor: primaryColor,
              isDark: isDark,
            ),
            ...gradeLevels.map((grade) {
              final gradeName = (grade.name ?? '').trim();
              if (grade.id == null || gradeName.isEmpty) {
                return const SizedBox.shrink();
              }
              return _buildChoiceChip(
                label: gradeName,
                selected: _selectedGradeLevelId == grade.id,
                onSelected: () =>
                    setState(() => _selectedGradeLevelId = grade.id),
                primaryColor: primaryColor,
                isDark: isDark,
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
    required Color primaryColor,
    required bool isDark,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      labelStyle: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        color: selected
            ? Colors.white
            : (isDark ? Colors.white70 : Colors.black87),
      ),
      selectedColor: primaryColor,
      backgroundColor: isDark ? Colors.white10 : Colors.grey.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: selected
              ? primaryColor
              : (isDark ? Colors.white24 : Colors.grey.shade300),
        ),
      ),
      showCheckmark: false,
    );
  }

  Widget _buildError(String message, bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: isDark ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.redAccent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.red.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions({
    required List<GradeLevel> gradeLevels,
    required Color primaryColor,
    required Color mutedColor,
  }) {
    final isEnabled = !_isSaving;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: isEnabled
                ? () => _handleAction(
                      ViolationPdfAction.preview,
                      gradeLevels,
                    )
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              disabledBackgroundColor: primaryColor.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.visibility_outlined,
                color: Colors.white, size: 20),
            label: Text(
              'Pratinjau PDF',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: isEnabled
                ? () => _handleAction(
                      ViolationPdfAction.download,
                      gradeLevels,
                    )
                : null,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: _isSaving
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: primaryColor,
                    ),
                  )
                : Icon(Icons.download_rounded, color: primaryColor, size: 20),
            label: Text(
              _isSaving ? 'Menyimpan...' : 'Unduh PDF',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Pratinjau hanya menampilkan dokumen. Unduh akan menyimpan file '
          'ke perangkat Anda.',
          style: GoogleFonts.poppins(fontSize: 11, color: mutedColor),
        ),
      ],
    );
  }

  Widget _buildLoading(
    ExportViolationPdfInProgress state,
    Color primaryColor,
    Color titleColor,
    Color mutedColor,
  ) {
    final isPreview = state.action == ViolationPdfAction.preview;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          CustomCircularProgressIndicator(
            widthAndHeight: 30,
            strokeWidth: 3,
            indicatorColor: primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            isPreview ? 'Menyiapkan pratinjau...' : 'Menyiapkan dokumen PDF...',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Laporan sedang dibuat oleh server. Mohon tunggu sebentar.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 12, color: mutedColor),
          ),
        ],
      ),
    );
  }
}
