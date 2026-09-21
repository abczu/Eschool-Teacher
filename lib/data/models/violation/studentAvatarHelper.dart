import 'package:flutter/foundation.dart';
import 'package:eschool_saas_staff/data/models/student/studentDetails.dart';
import 'package:eschool_saas_staff/data/models/violation/studentViolationItem.dart';
import 'package:eschool_saas_staff/data/repositories/student/studentRepository.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';

class StudentAvatarHelper {
  static final Map<int, String> _studentIdToImage = {};
  static final Map<String, String> _studentNameToImage = {};
  static final Set<int> _loadedClassSectionIds = {};
  static final Set<int> _loadingClassSectionIds = {};

  /// Extract valid image URL from StudentDetails
  static String? extractImage(StudentDetails s) {
    if (s.image != null && s.image!.trim().isNotEmpty) {
      return s.image!.trim();
    }
    if (s.profileUrl != null && s.profileUrl!.trim().isNotEmpty) {
      return s.profileUrl!.trim();
    }
    return null;
  }

  /// Format full URL if needed (handles relative paths with storageUrl)
  static String formatImageUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    return '$storageUrl$url';
  }

  /// Cache students images from StudentDetails list
  static void cacheStudents(List<StudentDetails> students, {int? classSectionId}) {
    for (final s in students) {
      final img = extractImage(s);
      if (img == null || img.isEmpty) continue;

      if (s.student?.id != null) {
        _studentIdToImage[s.student!.id!] = img;
      }
      if (s.id != null) {
        _studentIdToImage[s.id!] = img;
      }
      if (s.student?.userId != null) {
        _studentIdToImage[s.student!.userId!] = img;
      }

      final fullName = s.cleanFullName.toLowerCase().trim();
      if (fullName.isNotEmpty) {
        _studentNameToImage[fullName] = img;
        if (classSectionId != null && classSectionId > 0) {
          _studentNameToImage['${classSectionId}_$fullName'] = img;
        }
      }
    }
  }

  /// Get avatar URL from cache
  static String? getAvatarUrl({
    int? studentId,
    String? studentName,
    int? classId,
  }) {
    if (studentId != null && _studentIdToImage.containsKey(studentId)) {
      return _studentIdToImage[studentId];
    }
    if (studentName != null && studentName.trim().isNotEmpty) {
      final lowerName = studentName.trim().toLowerCase();
      if (classId != null && classId > 0) {
        final classKey = '${classId}_$lowerName';
        if (_studentNameToImage.containsKey(classKey)) {
          return _studentNameToImage[classKey];
        }
      }
      if (_studentNameToImage.containsKey(lowerName)) {
        return _studentNameToImage[lowerName];
      }
    }
    return null;
  }

  /// Background loader: loads students for classes of the given violation items
  static Future<void> loadAvatarsForStudents(
    List<StudentViolationItem> items, {
    VoidCallback? onLoaded,
  }) async {
    final List<int> classIdsToFetch = [];
    for (final item in items) {
      // If avatar is already cached, continue
      if (getAvatarUrl(
            studentId: item.studentId,
            studentName: item.studentName,
            classId: item.classId,
          ) !=
          null) {
        continue;
      }

      final cId = item.classId;
      if (cId != null &&
          cId > 0 &&
          !_loadedClassSectionIds.contains(cId) &&
          !_loadingClassSectionIds.contains(cId)) {
        if (!classIdsToFetch.contains(cId)) {
          classIdsToFetch.add(cId);
        }
      }
    }

    if (classIdsToFetch.isEmpty) return;

    bool hasNewAvatars = false;
    for (final cId in classIdsToFetch) {
      _loadingClassSectionIds.add(cId);
      try {
        final students = await StudentRepository().getAllStudents(
          classSectionId: cId,
        );
        cacheStudents(students, classSectionId: cId);
        _loadedClassSectionIds.add(cId);
        hasNewAvatars = true;
      } catch (e) {
        debugPrint('[StudentAvatarHelper] Failed to load students for class $cId: $e');
      } finally {
        _loadingClassSectionIds.remove(cId);
      }
    }

    if (hasNewAvatars && onLoaded != null) {
      onLoaded();
    }
  }
}
