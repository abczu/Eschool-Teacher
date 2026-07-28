import 'package:eschool_saas_staff/data/models/auth/userDetails.dart';
import 'package:eschool_saas_staff/utils/system/api.dart';
import 'package:flutter/foundation.dart';

class UserDetailsRepository {
  Future<({Map<String, String> enabledModules, List<String> permissions})>
      getPermissionAndAllowedModules() async {
    try {
      final result = await Api.get(url: Api.getStaffPermissionAndFeatures);

      if (kDebugMode) {
        print("🔍 [DEBUG] getPermissionAndAllowedModules raw: $result");
      }
      final permissionsList = ((result['data']['permissions'] ?? []) as List)
          .map((e) => e.toString())
          .toList();
      if (kDebugMode) {
        print("🔍 [DEBUG] getPermissionAndAllowedModules permissions: $permissionsList");
      }
      return (
        enabledModules:
            Map<String, String>.from(result['data']['features'] ?? {}),
        permissions: permissionsList,
      );
    } catch (e) {
      if (kDebugMode) {
        print("❌ [DEBUG] getPermissionAndAllowedModules failed with error: $e");
      }
      // TEMPORARY WORKAROUND: If backend returns HTML/empty response, return empty permissions
      // This allows user to continue but with restricted access until backend is fixed
      debugPrint(
          '⚠️ WARNING: Failed to fetch permissions from backend: ${e.toString()}');
      debugPrint(
          '⚠️ WORKAROUND: Returning empty permissions. User access will be restricted.');
      debugPrint(
          '⚠️ ACTION REQUIRED: Backend must fix /api/staff/features-permission endpoint');

      // Return empty permissions instead of throwing error
      // This prevents app from crashing but restricts all access
      return (
        enabledModules: <String, String>{},
        permissions: <String>[],
      );
    }
  }

  Future<({List<UserDetails> users, int currentPage, int totalPage})>
      searchUsers({int? page, required String search}) async {
    try {
      final result = await Api.get(
          url: Api.searchUsers,
          queryParameters: {"page": page ?? 1, "search": search});
      return (
        users: ((result['data']['data'] ?? []) as List)
            .map((user) => UserDetails.fromJson(Map.from(user ?? {})))
            .toList(),
        currentPage: (result['data']['current_page'] ?? 1) as int,
        totalPage: (result['data']['last_page'] ?? 1) as int,
      );
    } catch (e) {
      throw ApiException(e.toString());
    }
  }
}
