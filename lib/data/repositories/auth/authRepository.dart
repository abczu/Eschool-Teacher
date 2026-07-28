import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:eschool_saas_staff/data/models/auth/userDetails.dart';
import 'package:eschool_saas_staff/utils/system/api.dart';
import 'package:eschool_saas_staff/utils/system/hiveBoxKeys.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AuthRepository {
  Future<void> signOutUser() async {
    logout();
    setIsLogIn(false);
    setUserDetails(UserDetails());
    setAuthToken("");
    setSchoolsData([]);
    schoolCode = "";

    // Only clear credentials if remember me is not enabled
    if (!getRememberCredentials()) {
      await clearSavedCredentials();
    }
  }

  static String getAuthToken() {
    return Hive.box(authBoxKey).get(authTokenKey) ?? "";
  }

  Future<void> setAuthToken(String value) async {
    return Hive.box(authBoxKey).put(authTokenKey, value);
  }

  String get schoolCode => Hive.box(authBoxKey).get('schoolCode') ?? "";

  set schoolCode(String value) => Hive.box(authBoxKey).put('schoolCode', value);

  static bool getIsLogIn() {
    return Hive.box(authBoxKey).get(isLogInKey) ?? false;
  }

  Future<void> setIsLogIn(bool value) async {
    return Hive.box(authBoxKey).put(isLogInKey, value);
  }

  static UserDetails getUserDetails() {
    return UserDetails.fromJson(
        Map.from(Hive.box(authBoxKey).get(userDetailsKey) ?? {}));
  }

  Future<void> setUserDetails(UserDetails value) async {
    return Hive.box(authBoxKey).put(userDetailsKey, value.toJson());
  }

  Future<List<Map<String, dynamic>>> getSchoolsData() async {
    debugPrint('DEBUG: getSchoolsData called');
    final schoolsData = Hive.box(authBoxKey).get(schoolsDataKey);
    debugPrint('DEBUG: Raw schoolsData from Hive: $schoolsData');
    debugPrint('DEBUG: schoolsData type: ${schoolsData.runtimeType}');

    if (schoolsData == null) {
      debugPrint('DEBUG: schoolsData is null, returning empty list');
      return [];
    }

    // Properly cast each map to Map<String, dynamic>
    final result = (schoolsData as List<dynamic>).map((item) {
      return Map<String, dynamic>.from(item as Map<dynamic, dynamic>);
    }).toList();

    debugPrint('DEBUG: Converted schoolsData: $result');
    debugPrint('DEBUG: Result length: ${result.length}');
    return result;
  }

  Future<void> setSchoolsData(List<Map<String, dynamic>> schools) async {
    debugPrint('DEBUG: setSchoolsData called with: $schools');
    debugPrint('DEBUG: schools length: ${schools.length}');
    final result = await Hive.box(authBoxKey).put(schoolsDataKey, schools);
    debugPrint('DEBUG: Schools data stored in Hive');

    // Verify storage immediately
    final stored = await getSchoolsData();
    debugPrint('DEBUG: Verification - stored schools: $stored');
    debugPrint('DEBUG: Verification - stored schools length: ${stored.length}');

    return result;
  }

  Future<String> getFcmToken() async {
    try {
      return (await FirebaseMessaging.instance.getToken()) ?? "";
    } catch (e) {
      return "";
    }
  }

  /// Register FCM device token to backend for push notifications.
  /// Called after login and on app startup when user is already authenticated.
  Future<void> registerDeviceToken() async {
    try {
      final String fcmToken = await getFcmToken();
      if (fcmToken.isEmpty) {
        debugPrint('⚠️ [DEVICE-REG] FCM token is empty, skipping registration');
        return;
      }

      final String platform = Platform.isIOS ? 'ios' : 'android';

      debugPrint('📱 [DEVICE-REG] Registering device token...');
      debugPrint('   - Platform: $platform');
      debugPrint('   - FCM Token: ${fcmToken.substring(0, 20)}...');

      final result = await Api.postJson(
        body: {
          "fcm_id": fcmToken,
          "platform": platform,
        },
        url: Api.registerDeviceToken,
        useAuthToken: true,
      );

      debugPrint('✅ [DEVICE-REG] Device token registered successfully');
      debugPrint('   - Response: $result');
    } on ApiException catch (e) {
      debugPrint('❌ [DEVICE-REG] API Error: ${e.errorMessage}');
    } catch (e) {
      debugPrint('❌ [DEVICE-REG] Unexpected error: $e');
    }
  }

  Future<
      ({
        UserDetails userDetails,
        String token,
        Map<String, dynamic> responseJson
      })> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final result = await Api.post(body: {
        "email": email,
        "password": password,
        "fcm_id": await getFcmToken(),
      }, url: Api.login, useAuthToken: false);

      const JsonEncoder.withIndent('  ').convert(result).split('\n').forEach(debugPrint);

      return (
        token: (result['token'] ?? "").toString(),
        userDetails: UserDetails.fromJson(Map.from(result['data'] ?? {})),
        responseJson: Map<String, dynamic>.from(result),
      );
    } on ApiException catch (e) {
      throw ApiException(e.toString());
    } catch (e) {
      debugPrint(e.toString());
      throw ApiException(defaultErrorMessageKey);
    }
  }

  Future<void> logout() async {
    try {
      await Api.post(
        body: {},
        url: Api.logout,
        useAuthToken: true,
      );
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await Api.post(
          url: Api.passwordResetEmail,
          useAuthToken: false,
          body: {"email": email});
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<String> changePassword(
      {required String oldPassword,
      required String newPassword,
      required String confirmPassword}) async {
    try {
      final result =
          await Api.post(url: Api.changepassword, useAuthToken: true, body: {
        "current_password": oldPassword,
        "new_password": newPassword,
        "new_confirm_password": confirmPassword
      });
      return (result['message'] ?? "").toString();
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<({UserDetails userDetails, String successmessage})> editProfile(
      {required String firstName,
      required String lastName,
      required String mobileNumber,
      required String email,
      required String dateOfBirth,
      required String currentAddress,
      required String permanentAddress,
      required String gender,
      String? image}) async {
    try {
      if (kDebugMode) {
        debugPrint(image.toString());
      }
      final result = await Api.post(body: {
        "first_name": firstName,
        "last_name": lastName,
        "mobile": mobileNumber,
        "email": email,
        "dob": dateOfBirth,
        "current_address": currentAddress.isEmpty ? "-" : currentAddress,
        "permanent_address": permanentAddress.isEmpty ? "-" : permanentAddress,
        "gender": gender,
        "image":
            (image ?? "").isEmpty ? null : await MultipartFile.fromFile(image!),
      }, useAuthToken: true, url: Api.editProfile);

      if (kDebugMode) {
        debugPrint(result['data'].toString());
      }
      return (
        successmessage: (result['message'] ?? "").toString(),
        userDetails: UserDetails.fromJson(Map.from(result['data'] ?? {})),
      );
    } on ApiException catch (e) {
      throw ApiException(e.toString());
    } catch (e) {
      throw ApiException(defaultErrorMessageKey);
    }
  }

  // Remember credentials functionality
  static bool getRememberCredentials() {
    return Hive.box(authBoxKey).get(rememberCredentialsKey) ?? false;
  }

  Future<void> setRememberCredentials(bool value) async {
    return Hive.box(authBoxKey).put(rememberCredentialsKey, value);
  }

  static String getRememberedEmail() {
    return Hive.box(authBoxKey).get(rememberedEmailKey) ?? "";
  }

  Future<void> setRememberedEmail(String email) async {
    return Hive.box(authBoxKey).put(rememberedEmailKey, email);
  }

  static String getRememberedPassword() {
    return Hive.box(authBoxKey).get(rememberedPasswordKey) ?? "";
  }

  Future<void> setRememberedPassword(String password) async {
    return Hive.box(authBoxKey).put(rememberedPasswordKey, password);
  }

  Future<void> saveCredentials({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    if (rememberMe) {
      await setRememberedEmail(email);
      await setRememberedPassword(password);
      await setRememberCredentials(true);
    } else {
      await clearSavedCredentials();
    }
  }

  Future<void> clearSavedCredentials() async {
    await setRememberedEmail("");
    await setRememberedPassword("");
    await setRememberCredentials(false);
  }

  ({String email, String password, bool rememberMe}) getSavedCredentials() {
    return (
      email: getRememberedEmail(),
      password: getRememberedPassword(),
      rememberMe: getRememberCredentials(),
    );
  }

  /*


 

  Future<void> setNewPassword(
      {required String email, required String password}) async {
    try {
      await Api.post(
          body: {"email": email, "new_password": password},
          url: Api.setNewPassword,
          useAuthToken: false);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<void> changePassword(
      {required String currentPassword,
      required String newPassword,
      required String newConfirmPassword}) async {
    try {
      await Api.post(body: {
        "current_password": currentPassword,
        "new_password": newPassword,
        "new_confirm_password": newConfirmPassword,
      }, url: Api.setNewPassword, useAuthToken: true);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

 

 

  */
}
