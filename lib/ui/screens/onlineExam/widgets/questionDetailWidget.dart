import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:eschool_saas_staff/data/models/exam/question.dart' as q;
import 'package:eschool_saas_staff/utils/system/questionUtils.dart';
import 'package:eschool_saas_staff/ui/screens/teacherAcademics/painters/bankQuestionPainters.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';

/// A self-contained widget that renders the detail view of a [q.Question] /
/// [q.QuestionVersion].  State-specific behaviours (image preview, edit
/// navigation) are pushed up via callbacks so that the widget remains purely
/// presentational.
class QuestionDetailWidget extends StatelessWidget {
  final q.Question question;
  final q.QuestionVersion version;

  /// Whether this is the latest version of the question.
  /// When [true] the Edit button is shown.
  final bool isLatestVersion;

  /// Called when the user taps the Edit button.
  final VoidCallback? onEdit;

  /// Custom image widget builder.  Receives the question id and should return
  /// the appropriate image widget (cached / pre-loaded by the parent screen).
  final Widget Function(int questionId)? imageWidgetBuilder;

  const QuestionDetailWidget({
    super.key,
    required this.question,
    required this.version,
    this.isLatestVersion = false,
    this.onEdit,
    this.imageWidgetBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final typeColor = QuestionUtils.getTypeColor(version.type);
    return Stack(
      children: [
        // Base background below the gradient header
        Positioned(
          top: 160,
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Theme.of(context).scaffoldBackgroundColor : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            ),
          ),
        ),

        // Gradient header
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 580,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  typeColor,
                  Color.lerp(typeColor, Colors.black, 0.3)!,
                ],
                stops: const [0.4, 1.0],
              ),
            ),
            child: Stack(
              children: [
                CustomPaint(
                  painter: UltraModernPatternPainter(
                    primaryColor: Colors.white.withValues(alpha: 0.12),
                    secondaryColor: Colors.white.withValues(alpha: 0.06),
                  ),
                  size: Size.infinite,
                ),
                Positioned(
                  top: -20,
                  right: -20,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.3),
                          Colors.white.withValues(alpha: 0),
                        ],
                        stops: const [0.1, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 40,
                  right: 40,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0),
                          Colors.white.withValues(alpha: 0.5),
                          Colors.white.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Main scrollable content
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: type badge, title, points
              _buildHeader(context, typeColor),

              // Themed body
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Theme.of(context).scaffoldBackgroundColor : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  children: [
                    _buildQuestionSection(context, typeColor),
                    _buildOptionsSection(context, typeColor),
                    _buildNoteSection(context),
                    if (version.image != null && version.image!.isNotEmpty)
                      _buildImageSection(context, typeColor),
                    _buildActionButtons(context, typeColor),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ──────────────────────────── Header ────────────────────────────

  Widget _buildHeader(BuildContext context, Color typeColor) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  QuestionUtils.getTypeIcon(version.type),
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  QuestionUtils.getTypeName(version.type),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Title
          Text(
            version.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.4,
              letterSpacing: 0.3,
            ),
          ),

          const SizedBox(height: 16),

          // Points badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Theme.of(context).cardColor : Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                const SizedBox(width: 6),
                Text(
                  '${version.defaultPoint} poin',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.grey[800],
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────── Question text ─────────────────────────

  Widget _buildQuestionSection(BuildContext context, Color typeColor) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        // Section title bar
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [Theme.of(context).cardColor, Theme.of(context).cardColor]
                  : [Colors.white, Colors.grey.shade50],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            border: Border(
                bottom: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.grey.shade100)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.help_outline_rounded,
                    color: typeColor, size: 20),
              ),
              const SizedBox(width: 16),
              Text(
                "Pertanyaan",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),

        // Question body
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          decoration: BoxDecoration(
              color: isDark ? Theme.of(context).scaffoldBackgroundColor : Colors.grey.shade50),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Theme.of(context).cardColor : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200, width: 1),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: version.question.trim().isEmpty
                ? _emptyState(
                    context,
                    Icons.help_outline,
                    "Pertanyaan belum diisi",
                    "Isi pertanyaan untuk memberikan soal yang jelas kepada siswa",
                  )
                : Text(
                    QuestionUtils.parseHtmlString(version.question),
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.grey.shade800,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────── Options ───────────────────────────

  Widget _buildOptionsSection(BuildContext context, Color typeColor) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      color: isDark ? Theme.of(context).scaffoldBackgroundColor : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.check_circle_outline,
                    color: typeColor, size: 20),
              ),
              const SizedBox(width: 16),
              Text(
                "Opsi Jawaban",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          version.options.isEmpty
              ? _emptyState(
                  context,
                  Icons.check_circle_outline,
                  "Belum ada opsi jawaban",
                  "Tambahkan minimal 2 opsi jawaban untuk soal pilihan ganda",
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: version.options.length,
                  itemBuilder: (context, index) =>
                      _buildOptionItem(context, index, typeColor),
                ),
        ],
      ),
    );
  }

  Widget _buildOptionItem(BuildContext context, int index, Color typeColor) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final option = version.options[index];
    final isCorrect = option.percentage == 100;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCorrect
              ? Colors.green.shade300
              : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200),
          width: 1.5,
        ),
        color: isCorrect
            ? (isDark ? Colors.green.withValues(alpha: 0.15) : Colors.green.shade50)
            : (isDark ? Theme.of(context).cardColor : Colors.white),
        boxShadow: [
          BoxShadow(
            color: isCorrect
                ? Colors.green.withValues(alpha: 0.1)
                : (isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.03)),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Letter circle
                Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.only(top: 2, right: 16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCorrect
                        ? Colors.green.withValues(alpha: 0.2)
                        : (isDark ? Colors.white.withValues(alpha: 0.05) : typeColor.withValues(alpha: 0.1)),
                    border: Border.all(
                      color: isCorrect
                          ? Colors.green
                          : (isDark ? Colors.white30 : typeColor),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      String.fromCharCode(65 + index),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isCorrect
                            ? Colors.green
                            : (isDark ? const Color(0xFFE53935) : typeColor),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

                // Option text
                Expanded(
                  child: option.text.trim().isEmpty
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Opsi ${String.fromCharCode(65 + index)} belum diisi",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white38 : Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Isi teks untuk opsi jawaban ini",
                              style: TextStyle(
                                  fontSize: 13, color: isDark ? Colors.white24 : Colors.grey.shade500),
                            ),
                          ],
                        )
                      : Text(
                          QuestionUtils.parseHtmlString(option.text),
                          style: TextStyle(
                            fontSize: 15,
                            color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.grey.shade800,
                            height: 1.4,
                          ),
                        ),
                ),

                // Correct badge
                if (isCorrect)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    margin: const EdgeInsets.only(left: 10),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "BENAR",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),

                // Partial credit badge
                if (!isCorrect && option.percentage > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    margin: const EdgeInsets.only(left: 10),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${option.percentage}%",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Feedback footer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
              border: Border(
                  top: BorderSide(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Feedback:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                option.feedback.trim().isEmpty
                    ? Text(
                        "Belum ada feedback untuk opsi ini. Tambahkan penjelasan mengapa jawaban ini benar/salah.",
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white38 : Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                      )
                    : Text(
                        option.feedback,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────── Note ─────────────────────────────

  Widget _buildNoteSection(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      color: isDark ? Theme.of(context).scaffoldBackgroundColor : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.notes, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 16),
              Text(
                "Catatan Soal",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: version.note.trim().isEmpty
                  ? (isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.shade50)
                  : (isDark ? Colors.blue.withValues(alpha: 0.15) : Colors.blue.shade50),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: version.note.trim().isEmpty
                    ? (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200)
                    : (isDark ? Colors.blue.withValues(alpha: 0.3) : Colors.blue.shade100),
                width: 1,
              ),
            ),
            child: version.note.trim().isEmpty
                ? _emptyState(
                    context,
                    Icons.note_add_outlined,
                    "Belum ada catatan",
                    "Tambahkan catatan untuk memberikan informasi tambahan tentang soal ini",
                  )
                : Text(
                    version.note,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.grey.shade800,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────── Image ────────────────────────────

  Widget _buildImage(String urlOrBase64) {
    if (urlOrBase64.trim().isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: Text(
            "Gambar kosong",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // 1. Check if it is a remote/relative URL
    final bool isUrl = urlOrBase64.startsWith('http') || urlOrBase64.startsWith('/') || urlOrBase64.contains('.');
    if (isUrl) {
      final String finalUrl = urlOrBase64.startsWith('http')
          ? urlOrBase64
          : "$storageUrl$urlOrBase64";
      return Image.network(
        finalUrl,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                "Gagal memuat gambar",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        },
      );
    }

    // 2. Otherwise assume it's base64
    try {
      final decodedImage = base64Decode(urlOrBase64);
      return Image.memory(
        decodedImage,
        fit: BoxFit.contain,
      );
    } catch (e) {
      // Fallback: maybe it's just a file path that is relative
      final String finalUrl = "$storageUrl$urlOrBase64";
      return Image.network(
        finalUrl,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                "Format gambar tidak valid",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        },
      );
    }
  }

  Widget _buildImageSection(BuildContext context, Color typeColor) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      color: isDark ? Theme.of(context).scaffoldBackgroundColor : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.image_outlined, color: typeColor, size: 20),
              ),
              const SizedBox(width: 16),
              Text(
                "Gambar Soal",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? Theme.of(context).cardColor : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200, width: 1),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: version.image != null && version.image!.isNotEmpty
                  ? _buildImage(version.image!)
                  : imageWidgetBuilder != null
                      ? imageWidgetBuilder!(question.id)
                      : const SizedBox(
                          height: 100,
                          child: Center(
                            child: Text(
                              "Tidak ada gambar",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Buttons ────────────────────────────

  Widget _buildActionButtons(BuildContext context, Color typeColor) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        border: isDark
            ? Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08)))
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Tutup",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
            ),
          ),
          if (isLatestVersion && onEdit != null) ...[
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: typeColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: onEdit,
                child: const Text(
                  "Edit",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────── Empty state helper ──────────────────────

  Widget _emptyState(BuildContext context, IconData icon, String title, String subtitle) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Icon(icon, size: 40, color: isDark ? Colors.white38 : Colors.grey.shade400),
        const SizedBox(height: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white70 : Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white54 : Colors.grey.shade500,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
