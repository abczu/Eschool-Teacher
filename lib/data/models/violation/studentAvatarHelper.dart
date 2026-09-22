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

  /// Bersihkan cache avatar agar pull-to-refresh mengambil foto terbaru
  /// dari web (misal foto siswa baru diganti via backend/web).
  static void clearCache() {
    _studentIdToImage.clear();
    _studentNameToImage.clear();
    _loadedClassSectionIds.clear();
    _loadingClassSectionIds.clear();
  }

  /// Extract valid image URL from StudentDetails (sumber foto web).
  static String? extractImage(StudentDetails s) {
    final normalized = normalizeAvatarUrl(s.image) ??
        normalizeAvatarUrl(s.profileUrl);
    if (normalized != null) return normalized;
    // Baca juga via toJson untuk key photo/avatar/profile_url bila ada.
    try {
      final map = (s as dynamic).toJson() as Map<String, dynamic>;
      for (final k in ['photo', 'photo_url', 'avatar', 'profile_url']) {
        final v = normalizeAvatarUrl(map[k]);
        if (v != null) return v;
      }
    } catch (_) {}
    return null;
  }

  /// Normalisasi URL avatar: tolak kosong / "null" / default placeholder.
  static String? normalizeAvatarUrl(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    final lower = s.toLowerCase();
    if (lower == 'null' || lower == 'nil' || lower == '-') return null;
    if (lower.endsWith('default.png') || lower.endsWith('default.jpg')) {
      return null;
    }
    return s;
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

  /// Background loader: loads students for classes of the given violation items.
  /// [fallbackClassId] dipakai untuk item walas yang `classId`-nya null
  /// (response homeroom flat tanpa class_section) — ambil dari
  /// `roleCheck.homeroomClasses[0]` / `_selectedClassId` di caller.
  /// Maksimal 1 fetch per classId, bukan N+1 per siswa.
  static Future<void> loadAvatarsForStudents(
    List<StudentViolationItem> items, {
    int? fallbackClassId,
    VoidCallback? onLoaded,
  }) async {
    final List<int> classIdsToFetch = [];
    void considerClassId(int? cId) {
      if (cId != null &&
          cId > 0 &&
          !_loadedClassSectionIds.contains(cId) &&
          !_loadingClassSectionIds.contains(cId) &&
          !classIdsToFetch.contains(cId)) {
        classIdsToFetch.add(cId);
      }
    }

    for (final item in items) {
      // If avatar is already cached, continue
      if (getAvatarUrl(
            studentId: item.studentId,
            studentName: item.studentName,
            classId: item.classId ?? fallbackClassId,
          ) !=
          null) {
        continue;
      }

      final cId = item.classId;
      if (cId != null && cId > 0) {
        considerClassId(cId);
      } else {
        // Item walas tanpa classId: fallback ke kelas perwalian agar
        // foto web (student-list) tetap bisa diambil, bukan skip diam.
        considerClassId(fallbackClassId);
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

  /// Loader untuk 1 siswa (dipakai halaman detail).
  /// Mengecek cache dulu; jika belum ada, fetch 1x per kelas lalu panggil [onLoaded]
  /// agar UI rebuild dan foto web muncul.
  static Future<void> loadAvatarForStudent({
    required int studentId,
    String? studentName,
    int? classId,
    int? fallbackClassId,
    VoidCallback? onLoaded,
  }) async {
    final effectiveClassId =
        (classId != null && classId > 0) ? classId : fallbackClassId;
    if (getAvatarUrl(
          studentId: studentId,
          studentName: studentName,
          classId: effectiveClassId,
        ) !=
        null) {
      return;
    }
    if (effectiveClassId == null || effectiveClassId <= 0) return;
    if (_loadedClassSectionIds.contains(effectiveClassId) ||
        _loadingClassSectionIds.contains(effectiveClassId)) {
      return;
    }
    _loadingClassSectionIds.add(effectiveClassId);
    try {
      final students = await StudentRepository().getAllStudents(
        classSectionId: effectiveClassId,
      );
      cacheStudents(students, classSectionId: effectiveClassId);
      _loadedClassSectionIds.add(effectiveClassId);
      onLoaded?.call();
    } catch (e) {
      debugPrint(
          '[StudentAvatarHelper] Failed to load students for class $effectiveClassId: $e');
    } finally {
      _loadingClassSectionIds.remove(effectiveClassId);
    }
  }
}
