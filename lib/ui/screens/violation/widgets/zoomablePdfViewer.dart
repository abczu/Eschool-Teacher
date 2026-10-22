import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

/// Viewer PDF satu halaman dengan kontrol zoom in/out dan geser bebas.
///
/// `PdfPreview` bawaan hanya bisa di-zoom setelah double-tap serta tidak
/// menyediakan tombol zoom, sehingga kurang nyaman untuk membaca rekap.
/// Di sini halaman dirasterisasi sekali, lalu ditampilkan di dalam
/// [InteractiveViewer] dengan toolbar zoom + navigasi halaman.
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

class _PdfPageImage {
  final Uint8List bytes;

  /// Rasio tinggi terhadap lebar halaman (height / width).
  final double aspectRatio;

  const _PdfPageImage({required this.bytes, required this.aspectRatio});
}

class _ZoomablePdfViewerState extends State<ZoomablePdfViewer> {
  static const double _rasterDpi = 200;
  static const double _minScale = 1;
  static const double _maxScale = 4;
  static const double _zoomStep = 1.25;
  static const double _doubleTapScale = 2.5;

  final TransformationController _controller = TransformationController();

  List<_PdfPageImage>? _pages;
  Object? _error;

  int _pageIndex = 0;
  double _scale = 1;
  int _zoomPercent = 100;

  Size _viewportSize = Size.zero;
  Size _canvasSize = Size.zero;
  Offset _doubleTapPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleTransformChanged);
    _loadPages();
  }

  Future<void> _loadPages() async {
    setState(() => _error = null);

    try {
      final info = await Printing.info();
      if (!info.canRaster) {
        throw UnsupportedError('Pratinjau gambar PDF tidak didukung');
      }

      final pages = <_PdfPageImage>[];
      await for (final page in Printing.raster(widget.bytes, dpi: _rasterDpi)) {
        final bytes = await page.toPng();
        final ratio =
            page.width > 0 ? page.height / page.width : 1.4142857142857144;
        pages.add(_PdfPageImage(bytes: bytes, aspectRatio: ratio));
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

  void _handleTransformChanged() {
    final scale = _controller.value.getMaxScaleOnAxis();
    _scale = scale;
    final percent = (scale * 100).round();
    if (percent != _zoomPercent) {
      setState(() => _zoomPercent = percent);
    }
  }

  Size _pageSizeFor(_PdfPageImage page) {
    final pageWidth = (_viewportSize.width - 24).clamp(200.0, 1200.0);
    return Size(pageWidth, pageWidth * page.aspectRatio);
  }

  /// Menerapkan zoom ke [targetScale] dengan titik fokus [focalPoint]
  /// (koordinat viewport). Default fokus ada di tengah layar.
  void _zoomTo(double targetScale, {Offset? focalPoint}) {
    if (_viewportSize.isEmpty) return;

    final current = _controller.value.getMaxScaleOnAxis();
    final target = targetScale.clamp(_minScale, _maxScale);
    if ((target - current).abs() < 0.001) return;
    if (target <= _minScale + 0.001) {
      _resetZoom();
      return;
    }

    final focal =
        focalPoint ?? Offset(_viewportSize.width / 2, _viewportSize.height / 2);
    final scenePoint = _controller.toScene(focal);
    final factor = target / current;

    final matrix = _controller.value.clone()
      ..translateByDouble(scenePoint.dx, scenePoint.dy, 0, 1)
      ..scaleByDouble(factor, factor, factor, 1)
      ..translateByDouble(-scenePoint.dx, -scenePoint.dy, 0, 1);

    _clampToBounds(matrix);
    _controller.value = matrix;
  }

  /// Menjaga agar kanvas tidak terlempar keluar layar saat zoom dari tombol.
  void _clampToBounds(Matrix4 matrix) {
    if (_canvasSize.isEmpty || _viewportSize.isEmpty) return;

    final scale = matrix.getMaxScaleOnAxis();
    final scaledWidth = _canvasSize.width * scale;
    final scaledHeight = _canvasSize.height * scale;

    double clampAxis(double translation, double viewport, double scaled) {
      if (scaled <= viewport) return (viewport - scaled) / 2;
      return translation.clamp(viewport - scaled, 0.0);
    }

    matrix.storage[12] = clampAxis(
      matrix.storage[12],
      _viewportSize.width,
      scaledWidth,
    );
    matrix.storage[13] = clampAxis(
      matrix.storage[13],
      _viewportSize.height,
      scaledHeight,
    );
  }

  void _zoomIn() => _zoomTo(_scale * _zoomStep);

  void _zoomOut() => _zoomTo(_scale / _zoomStep);

  void _resetZoom() {
    if (_controller.value == Matrix4.identity()) return;
    _controller.value = Matrix4.identity();
  }

  void _handleDoubleTap() {
    if (_scale > _minScale + 0.001) {
      _resetZoom();
      return;
    }
    _zoomTo(_doubleTapScale, focalPoint: _doubleTapPosition);
  }

  void _goToPage(int index) {
    final pages = _pages;
    if (pages == null || index < 0 || index >= pages.length) return;
    if (index == _pageIndex) return;

    setState(() => _pageIndex = index);
    _resetZoom();
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTransformChanged);
    _controller.dispose();
    super.dispose();
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
        _viewportSize = Size(constraints.maxWidth, constraints.maxHeight);

        return Column(
          children: [
            Expanded(child: _buildPageView(pages[_pageIndex])),
            _buildToolbar(pages.length),
          ],
        );
      },
    );
  }

  Widget _buildPageView(_PdfPageImage page) {
    final viewport = _viewportSize;
    final pageSize = _pageSizeFor(page);
    final canvasSize = Size(
      math.max(viewport.width, pageSize.width),
      math.max(viewport.height, pageSize.height),
    );
    _canvasSize = canvasSize;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onDoubleTapDown: (details) => _doubleTapPosition = details.localPosition,
      onDoubleTap: _handleDoubleTap,
      child: InteractiveViewer(
        transformationController: _controller,
        // Kanvas dibuat eksplisit agar halaman yang lebih panjang dari layar
        // tetap bisa digeser sampai bagian paling bawah.
        constrained: false,
        panEnabled: true,
        scaleEnabled: true,
        minScale: _minScale,
        maxScale: _maxScale,
        boundaryMargin: EdgeInsets.zero,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: canvasSize.width,
          height: canvasSize.height,
          child: Center(
            child: Container(
              width: pageSize.width,
              height: pageSize.height,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black54 : Colors.black26,
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Image.memory(
                page.bytes,
                fit: BoxFit.contain,
                gaplessPlayback: true,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar(int pageCount) {
    final colorScheme = Theme.of(context).colorScheme;
    final canZoomOut = _scale > _minScale + 0.001;
    final canZoomIn = _scale < _maxScale - 0.001;
    final canGoPrevious = _pageIndex > 0;
    final canGoNext = _pageIndex < pageCount - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Material(
            color: colorScheme.surface,
            elevation: 6,
            borderRadius: BorderRadius.circular(22),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _toolbarButton(
                    icon: Icons.zoom_out,
                    tooltip: 'Perkecil',
                    onPressed: canZoomOut ? _zoomOut : null,
                    color: colorScheme.primary,
                  ),
                  Tooltip(
                    message: 'Reset ke 100%',
                    child: InkWell(
                      onTap: _resetZoom,
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 58,
                        height: 40,
                        child: Center(
                          child: Text(
                            '$_zoomPercent%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  _toolbarButton(
                    icon: Icons.zoom_in,
                    tooltip: 'Perbesar',
                    onPressed: canZoomIn ? _zoomIn : null,
                    color: colorScheme.primary,
                  ),
                  if (pageCount > 1) ...[
                    Container(
                      width: 1,
                      height: 24,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                    ),
                    _toolbarButton(
                      icon: Icons.chevron_left,
                      tooltip: 'Halaman sebelumnya',
                      onPressed: canGoPrevious
                          ? () => _goToPage(_pageIndex - 1)
                          : null,
                      color: colorScheme.primary,
                    ),
                    SizedBox(
                      width: 46,
                      child: Text(
                        '${_pageIndex + 1} / $pageCount',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    _toolbarButton(
                      icon: Icons.chevron_right,
                      tooltip: 'Halaman berikutnya',
                      onPressed:
                          canGoNext ? () => _goToPage(_pageIndex + 1) : null,
                      color: colorScheme.primary,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _toolbarButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 22),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      color: color,
    );
  }
}
