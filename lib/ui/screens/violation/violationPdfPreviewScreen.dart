import 'package:eschool_saas_staff/cubits/violation/exportViolationPdfCubit.dart';
import 'package:eschool_saas_staff/ui/screens/violation/widgets/zoomablePdfViewer.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Pratinjau PDF di dalam aplikasi.
///
/// File tidak disimpan otomatis. Penyimpanan dilakukan dari bottom sheet
/// rekap ("Unduh PDF") memakai dialog penyimpanan sistem.
class ViolationPdfPreviewScreen extends StatelessWidget {
  final ViolationPdfDocument document;

  const ViolationPdfPreviewScreen({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: isDark
          ? Theme.of(context).scaffoldBackgroundColor
          : Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pratinjau Rekap',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Text(
              document.request.scopeLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
      body: ZoomablePdfViewer(
        bytes: document.bytes,
        accentColor: primaryColor,
      ),
    );
  }
}
