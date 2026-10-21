import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

/// Viewer PDF dengan pinch-to-zoom dan geser per halaman.
///
/// `PdfPreview` bawaan hanya bisa di-zoom setelah double-tap dan hanya
/// menampilkan satu halaman, sehingga kurang nyaman untuk membaca rekap.
/// Di sini halaman dirasterisasi sekali lalu ditampilkan sebagai gambar
/// di dalam [InteractiveViewer].
class ZoomablePdfViewer extends StatefulWidget {
  final Uint8List bytes;
  final Color accentColor;

  const ZoomablePdfViewer({
    super.key,
    required this.bytes,
    required this.accentColor,
  });

  @override
  State<ZoomablePdfViewer> createState() => _ZoomablePdfViewerState();
}

class _ZoomablePdfViewerState extends State<ZoomablePdfViewer> {
  static const double _rasterDpi = 150;

  List<Uint8List>? _pages;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadPages();
  }

  Future<void> _loadPages() async {
    setState(() => _error = null);

    try {
      final info = await Printing.info();
      if (!info.canRaster) {
        throw UnsupportedError('Pratinjau gambar PDF tidak didukung');
      }

      final pages = <Uint8List>[];
      await for (final page in Printing.raster(widget.bytes, dpi: _rasterDpi)) {
        pages.add(await page.toPng());
      }

      if (!mounted) return;
      if (pages.isEmpty) {
        throw StateError('Dokumen PDF tidak memiliki halaman');
      }

      setState(() => _pages = pages);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Perangkat yang tidak mendukung rasterisasi tetap bisa melihat PDF
    // lewat PdfPreview bawaan (tanpa zoom bebas).
    if (_error != null) {
      return PdfPreview(
        build: (_) async => widget.bytes,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        useActions: false,
        allowPrinting: false,
        allowSharing: false,
        loadingWidget: Center(
          child: CircularProgressIndicator(color: widget.accentColor),
        ),
      );
    }

    final pages = _pages;
    if (pages == null) {
      return Center(
        child: CircularProgressIndicator(color: widget.accentColor),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final pageWidth = (constraints.maxWidth - 24).clamp(200.0, 1200.0);

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: pages.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _ZoomablePdfPage(
            imageBytes: pages[index],
            width: pageWidth,
          ),
        );
      },
    );
  }
}

class _ZoomablePdfPage extends StatefulWidget {
  final Uint8List imageBytes;
  final double width;

  const _ZoomablePdfPage({
    required this.imageBytes,
    required this.width,
  });

  @override
  State<_ZoomablePdfPage> createState() => _ZoomablePdfPageState();
}

class _ZoomablePdfPageState extends State<_ZoomablePdfPage> {
  static const double _doubleTapScale = 2.5;

  final TransformationController _controller = TransformationController();
  Offset _doubleTapPosition = Offset.zero;
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleTransformChanged);
  }

  void _handleTransformChanged() {
    final isZoomed = _controller.value.getMaxScaleOnAxis() > 1.01;
    if (isZoomed != _isZoomed) {
      setState(() => _isZoomed = isZoomed);
    }
  }

  void _handleDoubleTap() {
    if (_isZoomed) {
      _controller.value = Matrix4.identity();
      return;
    }

    final position = _doubleTapPosition;
    _controller.value = Matrix4.identity()
      ..translateByDouble(
        -position.dx * (_doubleTapScale - 1),
        -position.dy * (_doubleTapScale - 1),
        0,
        1,
      )
      ..scaleByDouble(_doubleTapScale, _doubleTapScale, _doubleTapScale, 1);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTransformChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: (details) =>
          _doubleTapPosition = details.localPosition,
      onDoubleTap: _handleDoubleTap,
      child: Material(
        color: Colors.white,
        elevation: 2,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InteractiveViewer(
          transformationController: _controller,
          minScale: 1,
          maxScale: 5,
          // Biarkan scroll antar halaman berjalan normal saat belum di-zoom.
          panEnabled: _isZoomed,
          child: Image.memory(
            widget.imageBytes,
            width: widget.width,
            fit: BoxFit.fitWidth,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
    );
  }
}
