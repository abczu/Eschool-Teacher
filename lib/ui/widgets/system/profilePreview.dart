import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ProfileImagePreview extends StatelessWidget {
  final String imageUrl;
  final String heroTag;

  const ProfileImagePreview({
    super.key,
    required this.imageUrl,
    required this.heroTag,
  });

  static void show(BuildContext context, String imageUrl, String heroTag) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      useSafeArea: false,
      builder: (context) => ProfileImagePreview(
        imageUrl: imageUrl,
        heroTag: heroTag,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Background Blur
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(color: Colors.black.withValues(alpha: 0.2)),
              ),
            ),

            // Main Content (Only Image)
            Center(
              child: GestureDetector(
                onTap: () {}, // Prevent closing when tapping the image
                child: Hero(
                  tag: heroTag,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    height: MediaQuery.of(context).size.width * 0.85,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: imageUrl.isEmpty
                        ? const Icon(Icons.person,
                            size: 150, color: Colors.grey)
                        : CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error),
                          ),
                  ),
                ),
              ),
            ),

            // Close Button
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 20,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
