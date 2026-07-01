import 'dart:typed_data';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;

class CustomImageCropper extends StatefulWidget {
  final Uint8List image;
  const CustomImageCropper({super.key, required this.image});

  @override
  State<CustomImageCropper> createState() => _CustomImageCropperState();
}

class _CustomImageCropperState extends State<CustomImageCropper> {
  final _controller = CropController();
  late Uint8List _currentImageBytes;

  @override
  void initState() {
    super.initState();
    _currentImageBytes = widget.image;
  }

  void _rotateImage() {
    // Decode image bytes
    final decodedImage = img.decodeImage(_currentImageBytes);
    if (decodedImage != null) {
      // Rotate 90 degrees counter-clockwise
      final rotatedImage = img.copyRotate(decodedImage, angle: -90);
      // Encode back to bytes
      setState(() {
        _currentImageBytes = Uint8List.fromList(img.encodeJpg(rotatedImage));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Crop(
                key: ValueKey(_currentImageBytes), // Penting agar widget refresh saat gambar diputar
                image: _currentImageBytes,
                controller: _controller,
                onCropped: (image) {
                  Navigator.pop(context, image);
                },
                aspectRatio: 1 / 1,
                withCircleUi: false,
                baseColor: Colors.black,
                maskColor: Colors.black.withValues(alpha: 0.5),
                cornerDotBuilder: (size, edgeAlignment) =>
                    const SizedBox.shrink(),
                interactive: true,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
              color: Colors.black,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Batal',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _rotateImage,
                    icon: const Icon(
                      Icons.rotate_left,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _controller.crop();
                    },
                    child: Text(
                      'Selesai',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
