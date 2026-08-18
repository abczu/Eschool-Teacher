import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import 'dart:math' as math;

/// Utility class for file compression operations
/// Handles image and document compression with quality preservation
class FileCompressionUtils {
  /// Default quality settings for different file sizes
  static const int _mediumQuality = 80;

  /// Maximum file sizes in bytes
  static const int _smallFileThreshold = 1024 * 1024; // 1MB
  static const int _mediumFileThreshold = 5 * 1024 * 1024; // 5MB
  static const int _largeFileThreshold = 10 * 1024 * 1024; // 10MB

  /// Supported image formats
  static const List<String> _supportedImageFormats = [
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
    '.bmp',
    '.gif',
    '.tiff',
    '.heic',
    '.heif'
  ];

  /// Supported document formats
  static const List<String> _supportedDocumentFormats = [
    '.pdf',
    '.doc',
    '.docx',
    '.txt'
  ];

  /// Compress any file (image or document) based on its type and size
  ///
  /// Parameters:
  /// - [file]: The file to compress
  /// - [maxSizeInMB]: Maximum target size in MB (default: 2MB)
  /// - [customQuality]: Custom quality override (0-100)
  /// - [forceCompress]: Force compression even if file is under size limit
  ///
  /// Returns: Compressed file or original file if compression not needed/possible
  static Future<File> compressFile({
    required File file,
    double maxSizeInMB = 2.0,
    int? customQuality,
    bool forceCompress = false,
  }) async {
    try {
      // Check if file exists
      if (!await file.exists()) {
        throw Exception('File does not exist');
      }

      final fileSize = await file.length();
      final maxSizeInBytes = (maxSizeInMB * 1024 * 1024).toInt();
      final fileName = path.basename(file.path);
      final fileExtension = path.extension(fileName).toLowerCase();

      // Check if should skip compression
      bool shouldSkipCompression = false;

      // For images, always compress unless it's very small
      if (_supportedImageFormats.contains(fileExtension)) {
        // Only skip if file is very small (less than 100KB) and not forced
        shouldSkipCompression = !forceCompress && fileSize < 100 * 1024;
      } else {
        // For non-images, skip if under size limit and not forced
        shouldSkipCompression = !forceCompress && fileSize <= maxSizeInBytes;
      }

      if (shouldSkipCompression) {
        if (kDebugMode) {
          debugPrint(
              'File skipped compression: ${_formatFileSize(fileSize)} (${fileSize < 100 * 1024 ? "very small" : "within limit"})');
        }
        return file;
      }

      if (kDebugMode) {
        debugPrint(
            'Compressing file: $fileName (${_formatFileSize(fileSize)})');
      }

      // Determine file type and compress accordingly
      if (_supportedImageFormats.contains(fileExtension)) {
        // Langsung gunakan dart:image library untuk menghindari plugin issues
        return await _compressImageWithDartLibrary(
          file: file,
          maxSizeInBytes: maxSizeInBytes,
          customQuality: customQuality,
        );
      } else if (_supportedDocumentFormats.contains(fileExtension)) {
        return await _compressDocument(
          file: file,
          maxSizeInBytes: maxSizeInBytes,
        );
      } else {
        if (kDebugMode) {
          debugPrint('Unsupported file format: $fileExtension');
        }
        return file; // Return original file if format not supported
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error compressing file: $e');
      }
      return file; // Return original file on error
    }
  }

  /// Compress image files using dart:image library (more reliable)
  static Future<File> _compressImageWithDartLibrary({
    required File file,
    required int maxSizeInBytes,
    int? customQuality,
  }) async {
    try {
      final fileSize = await file.length();
      // Use higher quality for smaller files, but still compress
      int quality = customQuality ?? _calculateOptimalQuality(fileSize);

      // Generate output path
      final fileName = path.basenameWithoutExtension(file.path);
      final fileExtension = path.extension(file.path).toLowerCase();
      final outputExt = (fileExtension == '.heic' || fileExtension == '.heif')
          ? '.jpg'
          : fileExtension;
      final directory = path.dirname(file.path);
      final outputPath =
          path.join(directory, '${fileName}_compressed$outputExt');

      File? compressedFile;
      int attempts = 0;
      const maxAttempts = 3;

      // Try compression with smart dimension and quality adjustment
      int maxWidth = 1920; // Start with high resolution
      int maxHeight = 1080;

      while (attempts < maxAttempts) {
        final xFile = await FlutterImageCompress.compressAndGetFile(
          file.absolute.path,
          outputPath,
          quality: quality,
          minWidth: maxWidth > 1200 ? 1200 : 800,
          minHeight: maxHeight > 800 ? 800 : 600,
          keepExif: false,
          rotate: 0,
        );

        compressedFile = xFile != null ? File(xFile.path) : null;

        if (compressedFile != null) {
          final compressedSize = await compressedFile.length();

          if (kDebugMode) {
            debugPrint(
                'Compression attempt ${attempts + 1}: ${_formatFileSize(compressedSize)} (quality: $quality, maxRes: ${maxWidth}x$maxHeight)');
          }

          // Check if compressed size meets target or if we achieved good compression
          if (compressedSize <= maxSizeInBytes ||
              compressedSize < fileSize * 0.7) {
            if (kDebugMode) {
              debugPrint(
                  'Image compression successful: ${_formatFileSize(fileSize)} → ${_formatFileSize(compressedSize)}');
            }
            return compressedFile;
          }
        }

        // Progressive reduction strategy: first reduce dimensions, then quality
        if (attempts == 0) {
          // First attempt: reduce dimensions but keep quality high
          maxWidth = (maxWidth * 0.8).round();
          maxHeight = (maxHeight * 0.8).round();
        } else {
          // Later attempts: reduce quality more gradually
          quality = (quality * 0.9).round();
          if (quality < 75) quality = 75; // Don't go below 75% quality
        }

        attempts++;

        // Clean up failed attempt
        if (compressedFile != null && await compressedFile.exists()) {
          await compressedFile.delete();
        }
      }

      // If all attempts failed, try alternative compression method
      return await _alternativeImageCompression(file, maxSizeInBytes);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error in image compression: $e');
      }
      return file;
    }
  }

  /// Alternative image compression using dart:image library
  static Future<File> _alternativeImageCompression(
      File file, int maxSizeInBytes) async {
    try {
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) return file;

      // Calculate new dimensions
      int width = image.width;
      int height = image.height;

      // Reduce dimensions if file is too large
      // Fix: Check if file needs resizing based on size ratio
      if (bytes.length > maxSizeInBytes) {
        // Calculate scale factor (sqrt of size ratio serves as good approximation for dimension scaling)
        double ratio = maxSizeInBytes / bytes.length;
        double scale = math.sqrt(ratio) * 0.9; // 0.9 safety factor

        width = (width * scale).round();
        height = (height * scale).round();

        // Enforce minimum dimensions to avoid becoming too small (unless original was already small)
        if (width < 400 && image.width > 400) width = 400;
        if (height < 300 && image.height > 300) height = 300;
      }

      // Resize and compress
      final resized = img.copyResize(image, width: width, height: height);
      final compressedBytes = img.encodeJpg(resized, quality: _mediumQuality);

      // Save compressed file
      final fileName = path.basenameWithoutExtension(file.path);
      final directory = path.dirname(file.path);
      final outputPath = path.join(directory, '${fileName}_compressed.jpg');

      final compressedFile = File(outputPath);
      await compressedFile.writeAsBytes(compressedBytes);

      if (kDebugMode) {
        final originalSize = await file.length();
        final compressedSize = await compressedFile.length();
        debugPrint(
            'Alternative compression: ${_formatFileSize(originalSize)} → ${_formatFileSize(compressedSize)}');
      }

      return compressedFile;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error in alternative compression: $e');
      }
      return file;
    }
  }

  /// Compress document files (currently basic implementation)
  static Future<File> _compressDocument({
    required File file,
    required int maxSizeInBytes,
  }) async {
    try {
      // For now, return original file as document compression requires specialized libraries
      // This can be extended with PDF compression libraries like pdf_compressor
      if (kDebugMode) {
        debugPrint(
            'Document compression not yet implemented for ${path.extension(file.path)}');
      }
      return file;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error in document compression: $e');
      }
      return file;
    }
  }

  /// Calculate optimal quality for compression while maintaining good visual quality
  static int _calculateOptimalQuality(int fileSize) {
    // Always use high quality for images to maintain visual fidelity
    // We'll rely on dimension reduction and format optimization for size reduction
    if (fileSize <= _smallFileThreshold) {
      return 92; // Very high quality for small files
    } else if (fileSize <= _mediumFileThreshold) {
      return 88; // High quality for medium files
    } else if (fileSize <= _largeFileThreshold) {
      return 85; // Good quality for large files
    } else {
      return 82; // Still good quality for very large files
    }
  }

  /// Format file size for display
  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Check if file type is supported for compression
  static bool isCompressionSupported(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return _supportedImageFormats.contains(extension) ||
        _supportedDocumentFormats.contains(extension);
  }

  /// Get file size in MB
  static Future<double> getFileSizeInMB(File file) async {
    final bytes = await file.length();
    return bytes / (1024 * 1024);
  }

  /// Batch compress multiple files
  static Future<List<File>> compressMultipleFiles({
    required List<File> files,
    double maxSizeInMB = 2.0,
    int? customQuality,
  }) async {
    List<File> compressedFiles = [];

    for (File file in files) {
      try {
        final compressedFile = await compressFile(
          file: file,
          maxSizeInMB: maxSizeInMB,
          customQuality: customQuality,
        );
        compressedFiles.add(compressedFile);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error compressing file ${file.path}: $e');
        }
        compressedFiles.add(file); // Add original file if compression fails
      }
    }

    return compressedFiles;
  }
}
