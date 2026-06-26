import 'package:eschool_saas_staff/data/models/extracurricular/extracurricular.dart';
import 'package:eschool_saas_staff/data/models/auth/user.dart';
import 'package:eschool_saas_staff/utils/system/api.dart';
import 'package:flutter/foundation.dart';

class ExtracurricularRepository {
  // Get list of active extracurriculars
  Future<List<Extracurricular>> getExtracurriculars() async {
    try {
      debugPrint(
          '🔍 [EXTRACURRICULAR REPO] API Call: ${Api.getExtracurriculars}');

      final response = await Api.get(
        url: Api.getExtracurriculars,
        useAuthToken: true,
        queryParameters: {
          'role': 'staff',
          'view_type': 'staff',
          'all': 'true',
        },
      );

      debugPrint(
          '✅ [EXTRACURRICULAR REPO] Response keys: ${response.keys.toList()}');
      debugPrint(
          '✅ [EXTRACURRICULAR REPO] Response message: ${response['message'] ?? 'N/A'}');

      if (response['error'] == true) {
        debugPrint(
            '❌ [EXTRACURRICULAR REPO] API Error: ${response['message']}');
        throw ApiException(
            response['message'] ?? 'Failed to load extracurriculars');
      }

      // Try multiple response keys: 'data', 'rows', or root level list
      List<dynamic> items = [];
      if (response['data'] != null && response['data'] is List) {
        items = response['data'] as List;
        debugPrint('📊 [EXTRACURRICULAR REPO] Found data in "data" key');
      } else if (response['rows'] != null && response['rows'] is List) {
        items = response['rows'] as List;
        debugPrint('📊 [EXTRACURRICULAR REPO] Found data in "rows" key');
      } else if (response['data'] != null && response['data'] is Map) {
        // Paginated response: data.data
        final nested = response['data'] as Map;
        items = (nested['data'] ?? nested['rows'] ?? []) as List;
        debugPrint(
            '📊 [EXTRACURRICULAR REPO] Found data in nested "data.data" key');
      } else {
        debugPrint(
            '⚠️ [EXTRACURRICULAR REPO] No recognized data key found! Response: $response');
      }

      debugPrint(
          '📊 [EXTRACURRICULAR REPO] Loaded ${items.length} extracurriculars');

      final extracurriculars =
          items.map((json) => Extracurricular.fromJson(json)).toList();

      debugPrint(
          '📊 [EXTRACURRICULAR REPO] Successfully loaded ${extracurriculars.length} active items');

      return extracurriculars;
    } catch (e) {
      debugPrint('❌ [EXTRACURRICULAR REPO] Exception: $e');
      throw ApiException(e.toString());
    }
  }

  // Get list of archived extracurriculars
  Future<List<Extracurricular>> getArchivedExtracurriculars() async {
    try {
      debugPrint(
          '🔍 [EXTRACURRICULAR REPO] API Call: ${Api.getTrashedExtracurriculars}');

      final response = await Api.get(
        url: Api.getTrashedExtracurriculars,
        useAuthToken: true,
        queryParameters: {
          'role': 'teacher',
          'view_type': 'teacher',
        },
      );

      debugPrint(
          '✅ [EXTRACURRICULAR REPO] Archived Response: ${response['message'] ?? 'Success'}');

      // Check for success field instead of error field
      if (response['success'] != true) {
        debugPrint(
            '❌ [EXTRACURRICULAR REPO] API Error: ${response['message']}');
        throw ApiException(
            response['message'] ?? 'Failed to load archived extracurriculars');
      }

      // Response uses 'data' field for trashed endpoint
      final List<dynamic> data = response['data'] ?? [];

      debugPrint(
          '📊 [EXTRACURRICULAR REPO] Loaded ${data.length} archived extracurriculars');

      final archivedExtracurriculars =
          data.map((json) => Extracurricular.fromJson(json)).toList();

      // Debug: Print all items and their deletedAt status
      for (var item in archivedExtracurriculars) {
        debugPrint(
            '🔍 [DEBUG ARCHIVED] Item ID: ${item.id}, Name: ${item.name}, deletedAt: ${item.deletedAt}');
      }

      debugPrint(
          '📊 [EXTRACURRICULAR REPO] Successfully loaded ${archivedExtracurriculars.length} archived items');

      return archivedExtracurriculars;
    } catch (e) {
      debugPrint('❌ [EXTRACURRICULAR REPO] Exception: $e');
      throw ApiException(e.toString());
    }
  }

  // Create new extracurricular
  Future<void> createExtracurricular({
    required String name,
    required String description,
    required int coachId,
  }) async {
    try {
      debugPrint('➕ [EXTRACURRICULAR REPO] Creating: $name');
      debugPrint(
          '📊 [EXTRACURRICULAR REPO] Payload: name=$name, description=$description, coach_id=$coachId');

      final response = await Api.post(
        url: Api.createExtracurricular,
        useAuthToken: true,
        queryParameters: {
          'role': 'staff',
          'view_type': 'staff',
        },
        body: {
          'name': name,
          'description': description,
          'coach_id': coachId.toString(),
          '_method': 'POST',
        },
      );

      debugPrint('✅ [EXTRACURRICULAR REPO] Create Response: $response');

      if (response['error'] == true) {
        debugPrint(
            '❌ [EXTRACURRICULAR REPO] Create failed: ${response['message']}');
        throw ApiException(
            response['message'] ?? 'Failed to create extracurricular');
      }

      debugPrint(
          '✅ [EXTRACURRICULAR REPO] Created successfully. New Item: ${response['data']}');
    } catch (e) {
      debugPrint('❌ [EXTRACURRICULAR REPO] Create exception: $e');
      throw ApiException(e.toString());
    }
  }

  // Update extracurricular
  Future<void> updateExtracurricular({
    required int id,
    required String name,
    required String description,
    required int coachId,
  }) async {
    try {
      debugPrint('✏️ [EXTRACURRICULAR REPO] Updating ID $id: $name');

      final response = await Api.postJson(
        url: '${Api.updateExtracurricular}/$id',
        useAuthToken: true,
        body: {
          '_method':
              'PUT', // Laravel way to handle PUT in some configurations or just use it as POST
          'name': name,
          'description': description,
          'coach_id': coachId,
        },
      );

      if (response['error'] == true) {
        debugPrint(
            '❌ [EXTRACURRICULAR REPO] Update failed: ${response['message']}');
        throw ApiException(
            response['message'] ?? 'Failed to update extracurricular');
      }

      debugPrint('✅ [EXTRACURRICULAR REPO] Updated successfully');
    } catch (e) {
      debugPrint('❌ [EXTRACURRICULAR REPO] Update exception: $e');
      throw ApiException(e.toString());
    }
  }

  // Soft delete (Archive) extracurricular
  Future<void> deleteExtracurricular(int id) async {
    try {
      debugPrint('🗂️ [EXTRACURRICULAR REPO] Archiving ID: $id');

      final response = await Api.delete(
        url: '${Api.deleteExtracurricular}/$id',
        useAuthToken: true,
        body: {},
        queryParameters: {'mode': 'archive'},
      );

      if (response['error'] == true) {
        debugPrint(
            '❌ [EXTRACURRICULAR REPO] Archive failed: ${response['message']}');
        throw ApiException(
            response['message'] ?? 'Failed to archive extracurricular');
      }

      debugPrint('✅ [EXTRACURRICULAR REPO] Archived successfully');
    } catch (e) {
      debugPrint('❌ [EXTRACURRICULAR REPO] Archive exception: $e');
      throw ApiException(e.toString());
    }
  }

  // Restore archived extracurricular
  Future<void> restoreExtracurricular(int id) async {
    try {
      debugPrint('🔄 [EXTRACURRICULAR REPO] Restoring ID: $id');

      // Use dedicated restore endpoint
      final response = await Api.post(
        url: '${Api.restoreExtracurricular}/$id',
        useAuthToken: true,
        body: {},
      );

      debugPrint('🔍 [EXTRACURRICULAR REPO] Restore response: $response');

      // Check for success field (similar to trashed endpoint)
      if (response['success'] != true && response['error'] == true) {
        debugPrint(
            '❌ [EXTRACURRICULAR REPO] Restore failed: ${response['message']}');
        throw ApiException(
            response['message'] ?? 'Failed to restore extracurricular');
      }

      debugPrint('✅ [EXTRACURRICULAR REPO] Restored successfully');
    } catch (e) {
      debugPrint('❌ [EXTRACURRICULAR REPO] Restore exception: $e');
      throw ApiException(e.toString());
    }
  }

  // Force delete (Permanent delete) extracurricular
  Future<void> forceDeleteExtracurricular(int id) async {
    try {
      debugPrint('🗑️ [EXTRACURRICULAR REPO] Permanent delete ID: $id');

      final response = await Api.delete(
        url: '${Api.forceDeleteExtracurricular}/$id',
        useAuthToken: true,
        body: {},
        queryParameters: {'mode': 'permanent'}, // Optional parameter
      );

      debugPrint(
          '🔍 [EXTRACURRICULAR REPO] Permanent delete response: $response');

      if (response['error'] == true) {
        debugPrint(
            '❌ [EXTRACURRICULAR REPO] Permanent delete failed: ${response['message']}');
        throw ApiException(response['message'] ??
            'Failed to permanently delete extracurricular');
      }

      debugPrint('✅ [EXTRACURRICULAR REPO] Permanently deleted successfully');
    } catch (e) {
      debugPrint('❌ [EXTRACURRICULAR REPO] Permanent delete exception: $e');
      throw ApiException(e.toString());
    }
  }

  // Get list of teachers and staff
  Future<List<User>> getTeachersStaffList() async {
    try {
      debugPrint(
          '🔍 [EXTRACURRICULAR REPO] Fetching teachers from: ${Api.getTeachers}');

      final response = await Api.get(
        url: Api.getTeachers,
        useAuthToken: true,
      );

      debugPrint(
          '✅ [EXTRACURRICULAR REPO] Teachers Response keys: ${response.keys.toList()}');

      if (response['error'] == true) {
        debugPrint(
            '❌ [EXTRACURRICULAR REPO] API Error: ${response['message']}');
        throw ApiException(
            response['message'] ?? 'Failed to load teachers/staff');
      }

      // Parse response - handle 'data', 'rows', or 'data.data' (paginated)
      List<dynamic> items = [];
      if (response['data'] != null && response['data'] is List) {
        items = response['data'] as List;
        debugPrint('📊 [EXTRACURRICULAR REPO] Found teachers in "data" key');
      } else if (response['rows'] != null && response['rows'] is List) {
        items = response['rows'] as List;
        debugPrint('📊 [EXTRACURRICULAR REPO] Found teachers in "rows" key');
      } else if (response['data'] != null && response['data'] is Map) {
        final nested = response['data'] as Map;
        items = (nested['data'] ?? nested['rows'] ?? []) as List;
        debugPrint(
            '📊 [EXTRACURRICULAR REPO] Found teachers in nested "data.data" key');
      }

      debugPrint(
          '📊 [EXTRACURRICULAR REPO] Loaded ${items.length} teachers/staff candidates');

      final List<User> teachers = [];
      for (var json in items) {
        try {
          final map = Map<String, dynamic>.from(json ?? {});

          // staff/teachers often returns user details with nested 'user' key
          final userData = map['user'] as Map<String, dynamic>?;
          if (userData != null) {
            teachers.add(User(
              id: userData['id'] as int?,
              firstName: userData['first_name'] as String?,
              lastName: userData['last_name'] as String?,
              fullName: userData['full_name'] as String? ??
                  '${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}'
                      .trim(),
              image: userData['image'] as String?,
              role: userData['role'] as String?,
            ));
          } else {
            // Fallback: try parsing directly as User
            teachers.add(User.fromJson(map));
          }
        } catch (e) {
          debugPrint(
              '⚠️ [EXTRACURRICULAR REPO] Failed to parse a teacher item: $e');
        }
      }

      debugPrint(
          '📊 [EXTRACURRICULAR REPO] Successfully mapped ${teachers.length} teachers/staff');
      return teachers;
    } catch (e) {
      debugPrint('❌ [EXTRACURRICULAR REPO] Exception: $e');
      throw ApiException(e.toString());
    }
  }
}
