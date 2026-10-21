import 'package:eschool_saas_staff/cubits/violation/exportViolationPdfCubit.dart';
import 'package:eschool_saas_staff/utils/system/violationPdfUtils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';

/// Pratinjau PDF di dalam aplikasi.
///
/// File tidak disimpan otomatis. Tombol unduh memakai dialog penyimpanan
/// sistem sehingga user tetap memegang kendali penuh.
class ViolationPdfPreviewScreen extends StatefulWidget {
  final ViolationPdfDocument document;

  const ViolationPdfPreviewScreen({super.key, required this.document});

  @override
  State<ViolationPdfPreviewScreen> createState() =>
      _ViolationPdfPreviewScreenState();
}

class _ViolationPdfPreviewScreenState extends State<ViolationPdfPreviewScreen> {
  bool _isSaving = false;

  Future<void> _print() async {
    try {
      await Printing.layoutPdf(
        name: widget.document.fileName,
        onLayout: (_) async => widget.document.bytes,
      );
    } catch (e) {
      if (!mounted) return;
      _showMessage('Gagal membuka dialog cetak: $e');
    }
  }

  Future<void> _download() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final savedPath = await saveViolationPdfToDevice(
      bytes: widget.document.bytes,
      fileName: widget.document.fileName,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (savedPath != null) {
      _showMessage('Rekap PDF berhasil disimpan', isSuccess: true);
    }
  }

  void _showMessage(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isSuccess ? Colors.green : Colors.redAccent,
        ),
      );
  }

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
              widget.document.request.scopeLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Cetak',
            onPressed: _print,
            icon: const Icon(Icons.print_outlined),
          ),
          IconButton(
            tooltip: 'Unduh PDF',
            onPressed: _isSaving ? null : _download,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.download_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: isDark ? Colors.white10 : const Color(0xFFF5EBE0),
            child: Row(
              children: [
                Icon(
                  Icons.visibility_outlined,
                  size: 16,
                  color: isDark ? Colors.white70 : const Color(0xFF8B1F41),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mode pratinjau — file belum disimpan. '
                    'Logo sekolah dan ruang TTD sudah disertakan oleh server. '
                    'Gunakan tombol unduh untuk menyimpan ke perangkat.',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: PdfPreview(
              build: (_) async => widget.document.bytes,
              pdfFileName: widget.document.fileName,
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
              useActions: false,
              allowPrinting: false,
              allowSharing: false,
              loadingWidget: Center(
                child: CircularProgressIndicator(color: primaryColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
