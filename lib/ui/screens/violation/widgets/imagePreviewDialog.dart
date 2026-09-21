import 'package:cached_network_image/cached_network_image.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customCircularProgressIndicator.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:flutter/material.dart';

class ImagePreviewDialog extends StatelessWidget {
  final String imageUrl;
  final String? title;

  const ImagePreviewDialog({
    super.key,
    required this.imageUrl,
    this.title,
  });

  static void show(BuildContext context, {required String imageUrl, String? title}) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (context) => ImagePreviewDialog(
        imageUrl: imageUrl,
        title: title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String fullUrl =
        imageUrl.startsWith('http') ? imageUrl : "$storageUrl$imageUrl";

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (title != null)
                Expanded(
                  child: Text(
                    title!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              else
                const SizedBox.shrink(),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Zoomable Image
          Flexible(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                color: Colors.black,
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: CachedNetworkImage(
                    imageUrl: fullUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Container(
                      height: 250,
                      alignment: Alignment.center,
                      child: const CustomCircularProgressIndicator(
                        indicatorColor: Colors.white,
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 200,
                      alignment: Alignment.center,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image_rounded,
                              color: Colors.white60, size: 48),
                          SizedBox(height: 8),
                          Text(
                            "Gagal memuat gambar bukti",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Cubit atau geser untuk memperbesar",
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
